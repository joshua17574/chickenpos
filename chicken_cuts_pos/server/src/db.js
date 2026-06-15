import { MongoClient } from 'mongodb';

export async function connectMongo(config) {
  if (!config.mongoUri) {
    throw new Error('MONGODB_URI is required. Put it in server/.env.');
  }

  const client = new MongoClient(config.mongoUri, {
    maxPoolSize: 10,
    retryWrites: true,
  });
  await client.connect();
  return {
    client,
    db: client.db(config.databaseName),
  };
}
