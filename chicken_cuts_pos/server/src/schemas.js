import { z } from 'zod';

const money = z.number().finite().min(0).max(1_000_000);
const stock = z.number().int().min(0).max(1_000_000);

export const productIdSchema = z
  .string()
  .trim()
  .min(1)
  .max(120)
  .regex(/^[A-Za-z0-9:_-]+$/, 'Use letters, numbers, colon, underscore, or hyphen.');

export const productInputSchema = z.object({
  name: z
    .string()
    .trim()
    .min(1)
    .max(100)
    .transform((value) => value.replace(/\s+/g, ' ')),
  category: z
    .string()
    .trim()
    .max(40)
    .transform((value) => {
      const normalized = value.replace(/\s+/g, ' ');
      return normalized ? normalized.toUpperCase() : 'OTHER';
    }),
  sell: money,
  buy: money,
  stock,
});

export const productPatchSchema = productInputSchema.partial().refine(
  (value) => Object.keys(value).length > 0,
  'Provide at least one product field.',
);

export const checkoutSchema = z.object({
  items: z
    .array(
      z.object({
        productId: productIdSchema,
        qty: z.number().int().min(1).max(10_000),
      }),
    )
    .min(1)
    .max(200),
  cash: money,
});

export const salesQuerySchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  pageSize: z.coerce.number().int().min(1).max(200).default(50),
});

export function parseOrThrow(schema, input) {
  const result = schema.safeParse(input);
  if (result.success) return result.data;

  const details = result.error.flatten();
  const message = details.formErrors[0] || 'Invalid request data.';
  const error = new Error(message);
  error.validation = details;
  throw error;
}
