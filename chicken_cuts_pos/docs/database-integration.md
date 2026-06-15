# Database Integration Contract

The app reads and writes POS data through `PosRepository`.

- `LocalPosRepository`: offline/local preview mode using `shared_preferences`.
- `HttpPosRepository`: production mode using the REST API in `server/`.

Do not connect Flutter directly to MongoDB Atlas. The app runs on tablets and
phones, so anything compiled into it can be extracted. Keep `MONGODB_URI` only
in `server/.env`.

## MongoDB Collections

### products

| Field | Type | Notes |
|-------|------|-------|
| id | string | Public product ID, unique |
| name | string | Required display name |
| category | string | Uppercase label such as `WC` |
| sell | number | Selling price |
| buy | number | Buying cost |
| stock | integer | Current available quantity |
| createdAt | date | Server timestamp |
| updatedAt | date | Server timestamp |

### sales

| Field | Type | Notes |
|-------|------|-------|
| id | string | Public sale ID, unique |
| ts | date | Transaction timestamp |
| items | array | Embedded sale item snapshots |
| total | number | Sale total |
| cash | number | Cash received |
| change | number | Change returned |
| createdAt | date | Server timestamp |

Each sale item stores `productId`, `name`, `price`, `cost`, and `qty`. This is
intentional: the receipt should preserve product name and price even if the
product changes later.

## Adapter Responsibilities

Implement `PosRepository` in `lib/services/pos_repository.dart`:

- `load`: fetch products and sales history for the app.
- `createProduct`: create one product and return the saved product.
- `updateProduct`: update one product and return the saved product.
- `deleteProduct`: remove one product.
- `clearSales`: clear sales history.
- `commitCheckout`: atomically insert the sale and decrement product stock.

`commitCheckout` must be a transaction in the real database. If stock update
fails, the sale must not be inserted. If sale insertion fails, stock must not be
decremented.

## API Shape

```text
GET    /health
GET    /api/products
POST   /api/products
PATCH  /api/products/:id
DELETE /api/products/:id

GET    /api/sales?page=1&pageSize=50
DELETE /api/sales
POST   /api/checkout
```

`POST /api/checkout` should accept cart lines and cash received, then run the
database transaction server-side. Do not trust client-submitted totals for final
stock or revenue calculations. The server implementation recomputes product
prices and costs from MongoDB before saving the sale.

## Sync Behavior

When `POS_API_BASE_URL` is provided, the Flutter app uses `HttpPosRepository` and
loads products and sales from the API. It also refreshes every 10 seconds so
products, stock, and sales posted to MongoDB through the API are reflected on the
tablet/mobile app. The header shows `DB` in this mode and includes a manual sync
button.

When `POS_API_BASE_URL` is not provided, the app intentionally uses local preview
data. That mode is only for development previews and will not reflect MongoDB.

## Running With MongoDB

Backend:

```bash
cd server
copy .env.example .env
npm install
npm run seed
npm run dev
```

Flutter:

```bash
flutter run --dart-define=POS_API_BASE_URL=http://localhost:3000 --dart-define=POS_API_KEY=replace-with-a-random-value-for-tablets
```

For phones outside your development machine, deploy the `server/` folder to
Vercel and use the Vercel URL:

```bash
flutter build apk --release --dart-define=POS_API_BASE_URL=https://your-vercel-project.vercel.app --dart-define=POS_API_KEY=<same API_KEY>
```

For production hosting, configure `CLIENT_ORIGINS` to the real web origin. For
native Android/iOS builds, CORS is not a security boundary; use authentication
before exposing the API publicly.
