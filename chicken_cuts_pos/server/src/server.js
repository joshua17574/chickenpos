import { createApp } from './app.js';
import { loadConfig } from './config.js';
import { connectMongo } from './db.js';
import { MongoPosRepository } from './repositories/mongoPosRepository.js';

let serverPromise;

export async function initializeServer() {
  serverPromise ??= createServer();
  return serverPromise;
}

async function createServer() {
  const config = loadConfig();
  const { client, db } = await connectMongo(config);
  const repository = new MongoPosRepository({ client, db });
  await repository.ensureIndexes();

  return {
    app: createApp({ repository, config }),
    client,
    config,
  };
}
