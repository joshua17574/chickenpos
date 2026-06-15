import { Router } from 'express';

import { ApiError } from './errors.js';
import {
  checkoutSchema,
  parseOrThrow,
  productIdSchema,
  productInputSchema,
  productPatchSchema,
  salesQuerySchema,
} from './schemas.js';

export function createRoutes(repository) {
  const router = Router();

  router.get('/products', asyncHandler(async (_req, res) => {
    res.json({ data: await repository.listProducts() });
  }));

  router.post('/products', asyncHandler(async (req, res) => {
    const input = parseRequest(productInputSchema, req.body);
    const product = await repository.createProduct(input);
    res.status(201).json({ data: product });
  }));

  router.patch('/products/:id', asyncHandler(async (req, res) => {
    const id = parseRequest(productIdSchema, req.params.id);
    const input = parseRequest(productPatchSchema, req.body);
    const product = await repository.updateProduct(id, input);
    res.json({ data: product });
  }));

  router.delete('/products/:id', asyncHandler(async (req, res) => {
    const id = parseRequest(productIdSchema, req.params.id);
    await repository.deleteProduct(id);
    res.status(204).send();
  }));

  router.get('/sales', asyncHandler(async (req, res) => {
    const query = parseRequest(salesQuerySchema, req.query);
    const result = await repository.listSales(query);
    res.json(result);
  }));

  router.delete('/sales', asyncHandler(async (_req, res) => {
    await repository.clearSales();
    res.status(204).send();
  }));

  router.post('/checkout', asyncHandler(async (req, res) => {
    const input = parseRequest(checkoutSchema, req.body);
    const sale = await repository.checkout(input);
    const [products, sales] = await Promise.all([
      repository.listProducts(),
      repository.listSales({ page: 1, pageSize: 50 }),
    ]);
    res.status(201).json({
      data: {
        sale,
        products,
        sales: sales.data,
      },
    });
  }));

  return router;
}

function parseRequest(schema, input) {
  try {
    return parseOrThrow(schema, input);
  } catch (error) {
    if (error.validation) {
      throw new ApiError(
        422,
        'VALIDATION_ERROR',
        error.message,
        error.validation,
      );
    }
    throw error;
  }
}

function asyncHandler(fn) {
  return (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
}
