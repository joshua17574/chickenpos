import cors from 'cors';
import express from 'express';
import rateLimit from 'express-rate-limit';
import helmet from 'helmet';

import { ApiError, toErrorBody } from './errors.js';
import { createRoutes } from './routes.js';

export function createApp({ repository, config }) {
  const app = express();

  app.disable('x-powered-by');
  app.use(helmet());
  app.use(cors({ origin: corsOrigin(config.clientOrigins) }));
  app.use(express.json({ limit: '100kb' }));

  app.get('/health', (_req, res) => {
    res.json({ ok: true });
  });

  app.use(
    '/api',
    rateLimit({
      windowMs: 60 * 1000,
      limit: 180,
      standardHeaders: 'draft-7',
      legacyHeaders: false,
    }),
    requireApiKey(config.apiKey),
    createRoutes(repository),
  );

  app.use((error, _req, res, _next) => {
    const status = error instanceof ApiError ? error.status : 500;
    if (!(error instanceof ApiError)) {
      console.error(error);
    }

    res
      .status(status)
      .json(toErrorBody(error, config.nodeEnv !== 'production'));
  });

  return app;
}

function corsOrigin(allowedOrigins) {
  return (origin, callback) => {
    if (!origin || allowedOrigins.includes(origin)) {
      callback(null, true);
      return;
    }
    callback(null, false);
  };
}

function requireApiKey(apiKey) {
  return (req, _res, next) => {
    if (!apiKey) {
      next();
      return;
    }

    if (req.get('x-api-key') === apiKey) {
      next();
      return;
    }

    next(new ApiError(401, 'UNAUTHORIZED', 'Invalid API key.'));
  };
}
