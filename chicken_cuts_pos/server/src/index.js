import { initializeServer } from './server.js';

const { app, client, config } = await initializeServer();
const server = app.listen(config.port, () => {
  console.log(`POS API listening on http://localhost:${config.port}`);
});

async function shutdown() {
  server.close(async () => {
    await client.close();
    process.exit(0);
  });
}

process.on('SIGINT', shutdown);
process.on('SIGTERM', shutdown);
