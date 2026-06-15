import dotenv from 'dotenv';

dotenv.config();

const defaultOrigins = [
  'http://localhost:53822',
  'http://127.0.0.1:53822',
  'http://localhost:8080',
  'http://127.0.0.1:8080',
];

export function loadConfig(env = process.env) {
  const port = Number.parseInt(env.PORT ?? '3000', 10);
  if (!Number.isInteger(port) || port <= 0) {
    throw new Error('PORT must be a positive integer.');
  }

  const clientOrigins = parseOrigins(env.CLIENT_ORIGINS);
  return {
    port,
    mongoUri: env.MONGODB_URI,
    databaseName:
      env.MONGODB_DB_NAME || extractDatabaseName(env.MONGODB_URI) || 'letsonDB',
    clientOrigins,
    apiKey: env.API_KEY || '',
    nodeEnv: env.NODE_ENV || 'development',
  };
}

function parseOrigins(value) {
  if (!value) return defaultOrigins;
  return value
    .split(',')
    .map((origin) => origin.trim())
    .filter(Boolean);
}

function extractDatabaseName(uri) {
  if (!uri) return '';
  try {
    const parsed = new URL(uri);
    return parsed.pathname.replace(/^\//, '') || '';
  } catch (_) {
    return '';
  }
}
