import assert from 'node:assert/strict';
import test from 'node:test';

import {
  ensurePartialUniqueIdIndex,
  filterPosCatalogProducts,
  mergeCheckoutItems,
} from '../src/repositories/mongoPosRepository.js';

test('mergeCheckoutItems combines duplicate products before checkout', () => {
  assert.deepEqual(
    mergeCheckoutItems([
      { productId: 'p1', qty: 2 },
      { productId: 'p2', qty: 1 },
      { productId: 'p1', qty: 3 },
    ]),
    [
      { productId: 'p1', qty: 5 },
      { productId: 'p2', qty: 1 },
    ],
  );
});

test('ensurePartialUniqueIdIndex replaces legacy unique indexes', async () => {
  const collection = new FakeCollection([
    { name: '_id_', key: { _id: 1 } },
    { name: 'id_1', key: { id: 1 }, unique: true },
  ]);

  await ensurePartialUniqueIdIndex(collection);

  assert.deepEqual(collection.dropped, ['id_1']);
  assert.deepEqual(collection.created, [
    {
      key: { id: 1 },
      options: {
        unique: true,
        partialFilterExpression: { id: { $type: 'string' } },
      },
    },
  ]);
});

test('filterPosCatalogProducts keeps only products sold by the mobile POS', () => {
  assert.deepEqual(
    filterPosCatalogProducts([
      { name: 'C10', stock: 12 },
      { name: 'c59', stock: 0 },
      { name: 'C99', stock: 4 },
      { name: 'Pepsi', stock: 3 },
      { name: 'OS1', stock: 1 },
      { name: 'MAGIC SARAP', stock: 8 },
    ]).map((product) => product.name),
    ['C10', 'c59', 'C99', 'Pepsi'],
  );
});

class FakeCollection {
  constructor(indexes) {
    this._indexes = indexes;
    this.dropped = [];
    this.created = [];
  }

  async indexes() {
    return this._indexes;
  }

  async dropIndex(name) {
    this.dropped.push(name);
    this._indexes = this._indexes.filter((index) => index.name !== name);
  }

  async createIndex(key, options) {
    this.created.push({ key, options });
  }
}
