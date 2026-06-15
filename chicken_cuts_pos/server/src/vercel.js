import { initializeServer } from './server.js';

export default async function handler(req, res) {
  const { app } = await initializeServer();
  return app(req, res);
}
