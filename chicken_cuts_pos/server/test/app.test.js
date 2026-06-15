import assert from 'node:assert/strict';
import test from 'node:test';

import { createApp } from '../src/app.js';

test('protects API routes when an API key is configured', async () => {
  const { server, url } = await listen(createTestApp());
  try {
    const response = await fetch(`${url}/api/products`);
    assert.equal(response.status, 401);
  } finally {
    await close(server);
  }
});

test('returns products through the API contract', async () => {
  const { server, url } = await listen(createTestApp());
  try {
    const response = await fetch(`${url}/api/products`, {
      headers: { 'x-api-key': 'test-key' },
    });
    assert.equal(response.status, 200);

    const body = await response.json();
    assert.deepEqual(body.data, [
      {
        id: 'p1',
        name: 'MAGIC SARAP',
        category: 'GROCERY',
        sell: 5,
        buy: 3,
        stock: 7,
      },
    ]);
  } finally {
    await close(server);
  }
});

test('validates product input at the boundary', async () => {
  const { server, url } = await listen(createTestApp());
  try {
    const response = await fetch(`${url}/api/products`, {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        'x-api-key': 'test-key',
      },
      body: JSON.stringify({
        name: '',
        category: 'WC',
        sell: -1,
        buy: 0,
        stock: 5,
      }),
    });

    assert.equal(response.status, 422);
    const body = await response.json();
    assert.equal(body.error.code, 'VALIDATION_ERROR');
  } finally {
    await close(server);
  }
});

function createTestApp() {
  return createApp({
    repository: new FakeRepository(),
    config: {
      clientOrigins: ['http://localhost:53822'],
      apiKey: 'test-key',
      nodeEnv: 'test',
    },
  });
}

class FakeRepository {
  async listProducts() {
    return [
      {
        id: 'p1',
        name: 'MAGIC SARAP',
        category: 'GROCERY',
        sell: 5,
        buy: 3,
        stock: 7,
      },
    ];
  }

  async createProduct(input) {
    return { id: 'created', ...input };
  }

  async updateProduct(id, input) {
    return { id, ...input };
  }

  async deleteProduct() {}

  async listSales({ page, pageSize }) {
    return {
      data: [],
      pagination: { page, pageSize, totalItems: 0, totalPages: 0 },
    };
  }

  async clearSales() {}

  async checkout() {
    return {
      id: 'S1',
      ts: new Date('2026-06-10T00:00:00.000Z').toISOString(),
      items: [],
      total: 0,
      cash: 0,
      change: 0,
    };
  }
}

function listen(app) {
  return new Promise((resolve) => {
    const server = app.listen(0, () => {
      const address = server.address();
      resolve({ server, url: `http://127.0.0.1:${address.port}` });
    });
  });
}

function close(server) {
  return new Promise((resolve, reject) => {
    server.close((error) => (error ? reject(error) : resolve()));
  });
}
