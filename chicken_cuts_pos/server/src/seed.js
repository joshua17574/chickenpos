import { loadConfig } from './config.js';
import { connectMongo } from './db.js';
import { MongoPosRepository } from './repositories/mongoPosRepository.js';

const seedProducts = [
  { id: 'p1', name: 'MAGIC SARAP', category: 'GROCERY', sell: 5, buy: 3, stock: 7 },
  { id: 'p2', name: 'C10', category: 'WC', sell: 377, buy: 0, stock: 650 },
  { id: 'p3', name: 'OS1', category: 'WC', sell: 158, buy: 153, stock: 1 },
  { id: 'p4', name: 'OS2', category: 'WC', sell: 158, buy: 0, stock: 0 },
  { id: 'p5', name: 'OS4', category: 'WC', sell: 158, buy: 153, stock: 150 },
  { id: 'p6', name: 'PS1', category: 'WC', sell: 0, buy: 0, stock: 75 },
  { id: 'p7', name: 'C59', category: 'WC', sell: 0, buy: 0, stock: 0 },
  { id: 'p8', name: 'C99', category: 'WC', sell: 0, buy: 0, stock: 0 },
  { id: 'p9', name: 'WHOLE CHICKEN', category: 'WC', sell: 0, buy: 0, stock: 0 },
  { id: 'p10', name: 'LECHON', category: 'WC', sell: 0, buy: 0, stock: 0 },
];

const config = loadConfig();
const { client, db } = await connectMongo(config);
const repository = new MongoPosRepository({ client, db });
await repository.ensureIndexes();

const now = new Date();
for (const product of seedProducts) {
  await db.collection('products').updateOne(
    { id: product.id },
    {
      $set: { ...product, updatedAt: now },
      $setOnInsert: { createdAt: now },
    },
    { upsert: true },
  );
}

console.log(`Seeded ${seedProducts.length} products.`);
await client.close();
