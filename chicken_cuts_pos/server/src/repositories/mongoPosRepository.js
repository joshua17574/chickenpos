import crypto from 'node:crypto';

import { ObjectId } from 'mongodb';

import { ApiError } from '../errors.js';

const POS_CATALOG_NAMES = new Set(['C10', 'C59', 'C99', 'PEPSI']);

export class MongoPosRepository {
  constructor({ client, db }) {
    this.client = client;
    this.products = db.collection('products');
    this.bodegaProducts = db.collection('bodegaproducts');
    this.categories = db.collection('categories');
    this.sales = db.collection('sales');
    this.saleLines = db.collection('salelines');
  }

  async ensureIndexes() {
    await Promise.all([
      ensurePartialUniqueIdIndex(this.products),
      ensurePartialUniqueIdIndex(this.sales),
      this.products.createIndex({ category: 1, name: 1 }),
      this.sales.createIndex({ ts: -1 }),
      this.sales.createIndex({ saleDate: -1 }),
    ]);
  }

  async listProducts() {
    const categories = await this.categoryMap();
    const [productDocs, bodegaDocs] = await Promise.all([
      this.products
        .find({ isActive: { $ne: false } })
        .sort({ category: 1, name: 1 })
        .toArray(),
      this.bodegaProducts
        .find({ isActive: { $ne: false } })
        .sort({ name: 1 })
        .toArray(),
    ]);

    return filterPosCatalogProducts([
      ...productDocs.map((doc) => toProduct(doc, 'product', categories)),
      ...bodegaDocs.map((doc) => toProduct(doc, 'bodega', categories)),
    ]).sort((a, b) => a.category.localeCompare(b.category) || a.name.localeCompare(b.name));
  }

  async createProduct(input) {
    const now = new Date();
    const product = {
      id: `p_${crypto.randomUUID()}`,
      name: input.name,
      category: input.category,
      sell: input.sell,
      buy: input.buy,
      stock: input.stock,
      unitPrice: input.sell,
      buyingPrice: input.buy,
      stockPcs: input.stock,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    };

    await this.products.insertOne(product);
    return toProduct(product, 'product', new Map());
  }

  async updateProduct(id, input) {
    const ref = decodeProductRef(id);
    const updated = await this.collectionForRef(ref).findOneAndUpdate(
      queryForRef(ref),
      { $set: productUpdateForRef(ref, input) },
      {
        returnDocument: 'after',
        includeResultMetadata: false,
      },
    );

    if (!updated) {
      throw new ApiError(404, 'PRODUCT_NOT_FOUND', 'Product was not found.');
    }

    return toProduct(updated, ref.source, await this.categoryMap());
  }

  async deleteProduct(id) {
    const ref = decodeProductRef(id);
    const result = await this.collectionForRef(ref).updateOne(
      queryForRef(ref),
      { $set: { isActive: false, updatedAt: new Date() } },
    );
    if (result.matchedCount === 0) {
      throw new ApiError(404, 'PRODUCT_NOT_FOUND', 'Product was not found.');
    }
  }

  async listSales({ page, pageSize }) {
    const skip = (page - 1) * pageSize;
    const [docs, totalItems] = await Promise.all([
      this.sales
        .find({ isVoided: { $ne: true } })
        .sort({ ts: -1, saleDate: -1, createdAt: -1 })
        .skip(skip)
        .limit(pageSize)
        .toArray(),
      this.sales.countDocuments({ isVoided: { $ne: true } }),
    ]);
    const linesBySaleId = await this.saleLinesBySaleId(docs);

    return {
      data: docs.map((doc) => toSale(doc, linesBySaleId.get(String(doc._id)) ?? [])),
      pagination: {
        page,
        pageSize,
        totalItems,
        totalPages: Math.ceil(totalItems / pageSize),
      },
    };
  }

  async clearSales() {
    const mobileSales = await this.sales
      .find({ source: 'MOBILE_POS' }, { projection: { _id: 1 } })
      .toArray();
    const saleIds = mobileSales.flatMap((sale) => [sale._id, String(sale._id)]);
    await this.sales.deleteMany({ source: 'MOBILE_POS' });
    if (saleIds.length > 0) {
      await this.saleLines.deleteMany({ saleId: { $in: saleIds } });
    }
  }

  async checkout(input) {
    const mergedItems = mergeCheckoutItems(input.items);
    const session = this.client.startSession();
    let saleDoc;

    try {
      await session.withTransaction(
        async () => {
          const products = await Promise.all(
            mergedItems.map((item) => this.findProductForCheckout(item.productId, session)),
          );
          const byId = new Map(products.map((product) => [product.publicId, product]));
          const saleItems = [];
          for (const item of mergedItems) {
            const product = byId.get(item.productId);
            if (product.sell <= 0 || product.stock <= 0) {
              throw new ApiError(
                409,
                'PRODUCT_UNAVAILABLE',
                `${product.name} is not available for sale.`,
              );
            }
            if (item.qty > product.stock) {
              throw new ApiError(
                409,
                'INSUFFICIENT_STOCK',
                `Only ${product.stock} ${product.name} left in stock.`,
              );
            }

            saleItems.push({
              productId: product.publicId,
              name: product.name,
              category: product.category,
              categoryId: product.categoryId,
              price: product.sell,
              cost: product.buy,
              qty: item.qty,
              ref: product.ref,
            });
          }

          const total = roundMoney(
            saleItems.reduce((sum, item) => sum + item.price * item.qty, 0),
          );
          const paid = input.cash > 0 ? input.cash : total;
          if (paid < total) {
            throw new ApiError(422, 'INSUFFICIENT_CASH', 'Cash is less than total.');
          }

          const now = new Date();
          const saleObjectId = new ObjectId();
          const receiptNumber = `MOB-${now.getTime()}-${crypto.randomUUID().slice(0, 6)}`;
          saleDoc = {
            _id: saleObjectId,
            id: `S${now.getTime()}_${crypto.randomUUID().slice(0, 8)}`,
            receiptNumber,
            saleDate: now,
            source: 'MOBILE_POS',
            totalAmount: total,
            paidAmount: roundMoney(paid),
            balance: 0,
            totalPacks: saleItems.reduce((sum, item) => sum + item.qty, 0),
            totalQty: saleItems.reduce((sum, item) => sum + item.qty, 0),
            remarks: 'Mobile POS checkout',
            status: 'PAID',
            isVoided: false,
            ts: now,
            items: saleItems.map(({ ref: _ref, categoryId: _categoryId, ...item }) => item),
            total,
            cash: roundMoney(paid),
            change: roundMoney(paid - total),
            createdAt: now,
            updatedAt: now,
          };

          for (const item of saleItems) {
            const result = await this.collectionForRef(item.ref).updateOne(
              {
                ...queryForRef(item.ref),
                [item.ref.stockField]: { $gte: item.qty },
              },
              stockUpdateForRef(item.ref, item.qty, now),
              { session },
            );

            if (result.matchedCount !== 1) {
              throw new ApiError(
                409,
                'INSUFFICIENT_STOCK',
                'Stock changed before checkout completed.',
              );
            }
          }

          await this.sales.insertOne(saleDoc, { session });
          if (saleItems.length > 0) {
            await this.saleLines.insertMany(
              saleItems.map((item) => toSaleLine(item, saleObjectId, now)),
              { session },
            );
          }
        },
        {
          readConcern: { level: 'snapshot' },
          writeConcern: { w: 'majority' },
        },
      );
    } finally {
      await session.endSession();
    }

    return toSale(saleDoc);
  }

  async categoryMap(session) {
    const docs = await this.categories
      .find({ isActive: { $ne: false } }, { session })
      .toArray();
    return new Map(docs.map((doc) => [String(doc._id), doc.name]));
  }

  collectionForRef(ref) {
    return ref.source === 'bodega' ? this.bodegaProducts : this.products;
  }

  async findProductForCheckout(id, session) {
    const ref = decodeProductRef(id);
    const doc = await this.collectionForRef(ref).findOne(queryForRef(ref), { session });
    if (!doc || doc.isActive === false) {
      throw new ApiError(
        422,
        'INVALID_PRODUCT',
        'One or more cart products no longer exist.',
      );
    }

    const categories = await this.categoryMap(session);
    const product = toProduct(doc, ref.source, categories);
    if (!isPosCatalogProduct(product)) {
      throw new ApiError(
        422,
        'PRODUCT_NOT_ALLOWED',
        `${product.name} is not sold through the mobile POS.`,
      );
    }

    return {
      ...product,
      publicId: product.id,
      categoryId: doc.categoryId ? String(doc.categoryId) : undefined,
      ref: {
        ...ref,
        stockField: stockFieldForDoc(ref.source, doc),
        mirrorStock: ref.source === 'product' && typeof doc.stock === 'number',
        rawId: String(doc._id),
      },
    };
  }

  async saleLinesBySaleId(sales) {
    const ids = sales.flatMap((sale) => [sale._id, String(sale._id)]).filter(Boolean);
    if (ids.length === 0) return new Map();

    const lines = await this.saleLines
      .find({ saleId: { $in: ids } })
      .sort({ createdAt: 1 })
      .toArray();
    const bySaleId = new Map();
    for (const line of lines) {
      const key = String(line.saleId);
      const list = bySaleId.get(key) ?? [];
      list.push(line);
      bySaleId.set(key, list);
    }
    return bySaleId;
  }
}

export function mergeCheckoutItems(items) {
  const quantities = new Map();
  for (const item of items) {
    quantities.set(item.productId, (quantities.get(item.productId) ?? 0) + item.qty);
  }
  return [...quantities.entries()].map(([productId, qty]) => ({ productId, qty }));
}

export function filterPosCatalogProducts(products) {
  return products.filter(isPosCatalogProduct);
}

export async function ensurePartialUniqueIdIndex(collection) {
  const indexes = await collection.indexes();
  const oldIndex = indexes.find(
    (index) =>
      index.name === 'id_1' &&
      index.unique === true &&
      index.key?.id === 1 &&
      !index.partialFilterExpression,
  );

  if (oldIndex) {
    await collection.dropIndex(oldIndex.name);
  }

  await collection.createIndex(
    { id: 1 },
    {
      unique: true,
      partialFilterExpression: { id: { $type: 'string' } },
    },
  );
}

function isPosCatalogProduct(product) {
  return POS_CATALOG_NAMES.has(normalizeProductName(product.name));
}

function normalizeProductName(name) {
  return String(name ?? '').trim().replace(/\s+/g, ' ').toUpperCase();
}

function toProduct(doc, source, categories = new Map()) {
  return {
    id: publicProductId(doc, source),
    name: doc.name,
    category: categoryNameForDoc(doc, categories),
    sell: numberFrom(doc.sell, doc.unitPrice, doc.sellingPrice),
    buy: numberFrom(doc.buy, doc.buyingPrice),
    stock: intFrom(doc.stock, doc.stockPcs, doc.stockQty),
  };
}

function toSale(doc, lines = []) {
  const items = Array.isArray(doc.items) && doc.items.length > 0
    ? doc.items.map(toSaleItem)
    : lines.map(toSaleItem);
  const total = numberFrom(doc.total, doc.totalAmount, sumLineTotals(items));
  const cash = numberFrom(doc.cash, doc.paidAmount, total);

  return {
    id: doc.id || doc.receiptNumber || String(doc._id),
    ts: toIsoDate(doc.ts || doc.saleDate || doc.createdAt),
    items,
    total,
    cash,
    change: numberFrom(doc.change, Math.max(cash - total, 0)),
  };
}

function toSaleItem(doc) {
  return {
    productId: productIdForSaleItem(doc),
    name: doc.name || doc.productName || 'Product',
    price: numberFrom(doc.price),
    cost: numberFrom(doc.cost, doc.buyingPrice),
    qty: intFrom(doc.qty),
  };
}

function productIdForSaleItem(doc) {
  if (doc.name && doc.productId) return doc.productId;
  return productIdFromSaleLine(doc);
}

function productIdFromSaleLine(doc) {
  if (doc.productId) return `product:${doc.productId}`;
  if (doc.bodegaProductId) return `bodega:${doc.bodegaProductId}`;
  return 'unknown';
}

function toSaleLine(item, saleObjectId, now) {
  const line = {
    saleId: saleObjectId,
    source: item.ref.source === 'bodega' ? 'CHICKEN' : 'PRODUCT',
    categoryId: item.categoryId,
    categoryName: item.category,
    productName: item.name,
    qty: item.qty,
    price: item.price,
    lineTotal: roundMoney(item.price * item.qty),
    stockUnit: 'PCS',
    packSize: 1,
    stockPcsOut: item.qty,
    remarks: 'Mobile POS checkout',
    createdAt: now,
    updatedAt: now,
  };

  if (item.ref.source === 'bodega') {
    line.bodegaProductId = item.ref.rawId;
  } else {
    line.productId = item.ref.rawId ?? item.productId;
  }

  return line;
}

function publicProductId(doc, source) {
  if (typeof doc.id === 'string' && doc.id.trim()) {
    return doc.id;
  }
  return `${source}:${String(doc._id)}`;
}

function decodeProductRef(id) {
  if (id.startsWith('bodega:')) {
    return { source: 'bodega', kind: 'objectId', value: id.slice('bodega:'.length) };
  }
  if (id.startsWith('product:')) {
    return { source: 'product', kind: 'objectId', value: id.slice('product:'.length) };
  }
  return { source: 'product', kind: 'appId', value: id };
}

function queryForRef(ref) {
  if (ref.kind === 'appId') return { id: ref.value };
  return { _id: toObjectId(ref.value) };
}

function toObjectId(value) {
  if (!ObjectId.isValid(value)) {
    throw new ApiError(422, 'INVALID_PRODUCT', 'Product id is invalid.');
  }
  return new ObjectId(value);
}

function productUpdateForRef(ref, input) {
  const now = new Date();
  if (ref.source === 'bodega') {
    return {
      name: input.name,
      sellingPrice: input.sell,
      buyingPrice: input.buy,
      stockQty: input.stock,
      updatedAt: now,
    };
  }

  return {
    name: input.name,
    category: input.category,
    sell: input.sell,
    buy: input.buy,
    stock: input.stock,
    unitPrice: input.sell,
    buyingPrice: input.buy,
    stockPcs: input.stock,
    updatedAt: now,
  };
}

function stockFieldForDoc(source, doc) {
  if (source === 'bodega') return 'stockQty';
  if (typeof doc.stockPcs === 'number') return 'stockPcs';
  if (typeof doc.stock === 'number') return 'stock';
  return 'stockPcs';
}

function stockUpdateForRef(ref, qty, now) {
  const inc = { [ref.stockField]: -qty };
  if (ref.source === 'product' && ref.stockField === 'stockPcs' && ref.mirrorStock) {
    inc.stock = -qty;
  }
  return {
    $inc: inc,
    $set: { updatedAt: now },
  };
}

function categoryNameForDoc(doc, categories) {
  if (typeof doc.category === 'string' && doc.category.trim()) {
    return doc.category.trim().toUpperCase();
  }
  const fromCategory = doc.categoryId ? categories.get(String(doc.categoryId)) : null;
  return typeof fromCategory === 'string' && fromCategory.trim()
    ? fromCategory.trim().toUpperCase()
    : 'OTHER';
}

function numberFrom(...values) {
  for (const value of values) {
    if (typeof value === 'number' && Number.isFinite(value)) return value;
  }
  return 0;
}

function intFrom(...values) {
  return Math.trunc(numberFrom(...values));
}

function sumLineTotals(items) {
  return roundMoney(items.reduce((sum, item) => sum + item.price * item.qty, 0));
}

function toIsoDate(value) {
  if (value instanceof Date) return value.toISOString();
  if (typeof value === 'string' && value) return new Date(value).toISOString();
  return new Date().toISOString();
}

function roundMoney(value) {
  return Math.round((value + Number.EPSILON) * 100) / 100;
}
