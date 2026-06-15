# Chicken Cuts POS API

This backend is the secure bridge between the Flutter app and MongoDB Atlas.
The Flutter tablet/mobile app must never contain the MongoDB connection string.

## Setup

1. Rotate the MongoDB Atlas password because the current URI was pasted into
   chat.
2. Copy `server/.env.example` to `server/.env`.
3. Put the rotated URI in `server/.env` as `MONGODB_URI`.
4. Install and run:

```bash
cd server
npm install
npm run seed
npm run dev
```

## Deploy To Vercel

Deploy the `server/` folder as the Vercel project. Set these Vercel environment
variables in Project Settings:

```text
MONGODB_URI=<rotated MongoDB Atlas URI>
MONGODB_DB_NAME=letsonDB
API_KEY=<random value used by the tablets>
CLIENT_ORIGINS=
NODE_ENV=production
```

For Android/iOS, `CLIENT_ORIGINS` can be empty because native apps do not use
browser CORS. If you also host a web version, set it to that web origin.

After deployment, test:

```text
https://your-vercel-project.vercel.app/health
```

Then rebuild the APK with the deployed API URL:

```bash
flutter build apk --release --dart-define=POS_API_BASE_URL=https://your-vercel-project.vercel.app --dart-define=POS_API_KEY=<same API_KEY>
```

## App Connection

Run the Flutter app with only the API URL and optional API key:

```bash
flutter run --dart-define=POS_API_BASE_URL=http://localhost:3000 --dart-define=POS_API_KEY=replace-with-a-random-value-for-tablets
```

The `POS_API_KEY` is only a basic gate for trusted tablets. For a public
deployment, add real user/device authentication before exposing the API on the
internet.

If the app is launched without `POS_API_BASE_URL`, it uses local preview data and
will not reflect MongoDB. In API mode, the app refreshes product and sales data
from this server every 10 seconds.

## API

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

`POST /api/checkout` accepts cart lines and cash received. The server recomputes
prices from MongoDB and runs stock decrement plus sale insertion in one MongoDB
transaction.
