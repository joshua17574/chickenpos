# Chicken Cuts POS

A Flutter point-of-sale app for tablet and mobile use. It supports selling from
a product grid, stock-aware cart checkout, inventory management, transaction
history, reports, offline persistence with `shared_preferences`, and an
optional MongoDB-backed production API.

## Production Readiness

This version includes:

- Guarded checkout with final stock validation before inventory is decremented.
- Recovery from corrupt local persisted JSON.
- Product input normalization and non-negative price/stock handling.
- Async persistence on checkout, inventory changes, and history clearing.
- A `PosRepository` data boundary so local storage can be swapped for a real
  database adapter without rewriting UI screens.
- A REST API server in `server/` that keeps `MONGODB_URI` out of the Flutter
  tablet/mobile app and runs checkout updates transactionally.
- MongoDB-backed app mode refreshes products, stock, and sales from the API
  every 10 seconds, with a manual sync control in the header.
- Vercel-ready API entrypoint so Android devices can use a hosted HTTPS API
  instead of a PC LAN address.
- Focused store tests for checkout, stale cart handling, persistence recovery,
  unsellable products, and product validation.
- Flutter lint configuration with stricter casts, inference, raw types, and
  unawaited future checks.
- `.gitignore` for Flutter build output, IDE files, and local secrets.

## Features

- Sell: searchable product grid, category filters, tap-to-add cart, quantity
  steppers, cash/change calculation, receipt dialog, and stock-aware disabled
  products.
- Inventory: add, edit, and delete products with low-stock and out-of-stock
  alerts.
- History: itemized sales, cash/change, profit, and clear-history action.
- Reports: total revenue, gross profit, transaction count, units sold, and
  top-selling products.
- Responsive layout: side navigation and cart panel on tablet widths; bottom
  navigation and cart sheet on phone widths.
- Offline persistence: catalog and sales history are stored locally.

## Seeded Products

| Name | Category | Selling PHP | Buying PHP | Stock |
|------|----------|-------------|------------|-------|
| MAGIC SARAP | GROCERY | 5 | 3 | 7 |
| C10 | WC | 377 | 0 | 650 |
| OS1 | WC | 158 | 153 | 1 |
| OS2 | WC | 158 | 0 | 0 |
| OS4 | WC | 158 | 153 | 150 |
| PS1 | WC | 0 | 0 | 75 |
| C59 / C99 / WHOLE CHICKEN / LECHON | WC | 0 | 0 | 0 |

Items with selling price `0` cannot be sold until a price is set in Inventory.

## Getting Started

Install Flutter, then resolve dependencies:

```bash
flutter pub get
```

Platform folders are included. If you intentionally need to regenerate them,
run `flutter create .` from this directory.

Run the app:

```bash
flutter run
```

Run the app against the backend API:

```bash
flutter run --dart-define=POS_API_BASE_URL=http://localhost:3000 --dart-define=POS_API_KEY=replace-with-a-random-value-for-tablets
```

For Android installs backed by Vercel:

```bash
flutter build apk --release --dart-define=POS_API_BASE_URL=https://your-vercel-project.vercel.app --dart-define=POS_API_KEY=<same API_KEY>
```

Without `POS_API_BASE_URL`, the app uses local preview data. To reflect MongoDB
data on the tablet/mobile app, always launch production builds with
`POS_API_BASE_URL` pointing at the running API server.

Run verification:

```bash
flutter analyze
flutter test
```

Build release artifacts:

```bash
flutter build apk
flutter build ipa
```

## Project Structure

```text
lib/
  main.dart                 # App entry and responsive navigation shell
  models/
    product.dart
    sale.dart
  services/
    pos_repository.dart       # Database-ready storage contract
    local_pos_repository.dart # Current shared_preferences adapter
    http_pos_repository.dart  # REST API adapter for MongoDB-backed mode
    store.dart              # State, seed data, persistence, reports
    format.dart             # Peso and date formatting
  screens/
    sell_screen.dart
    inventory_screen.dart
    history_screen.dart
    reports_screen.dart
  widgets/
    product_card.dart
    cart_panel.dart
    ui.dart
test/
  store_test.dart
server/
  src/                      # Express API and MongoDB repository
  test/                     # Node API tests
```

See `docs/database-integration.md` and `server/README.md` for the MongoDB setup.
