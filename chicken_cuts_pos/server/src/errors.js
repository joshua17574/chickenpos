export class ApiError extends Error {
  constructor(status, code, message, details) {
    super(message);
    this.name = 'ApiError';
    this.status = status;
    this.code = code;
    this.details = details;
  }
}

export function toErrorBody(error, exposeDetails = false) {
  if (error instanceof ApiError) {
    return {
      error: {
        code: error.code,
        message: error.message,
        ...(error.details && exposeDetails ? { details: error.details } : {}),
      },
    };
  }

  return {
    error: {
      code: 'INTERNAL_ERROR',
      message: 'Something went wrong.',
    },
  };
}
