# JolliPOS

A touch-first, offline-first **Point-of-Sale** for fast-food / QSR, built with
Flutter. Bright, big-button UI, tablet 3-pane + phone stacked layouts, and a
**fully dynamic, user-encoded menu** — there are **no hardcoded products,
prices, categories, or modifiers** anywhere in the source.

> The catalog lives entirely in the on-device database. You encode your own
> items in **Menu Management**. The ordering screen reads everything live.

---

## Tech stack
- **Flutter + Dart** (null-safe)
- **Riverpod** — state management & DI
- **Drift (SQLite)** — offline-first local database (all data, incl. the catalog)
- **go_router** — navigation
- **freezed / json_serializable** — immutable models + codegen
- **esc_pos_utils_plus** — thermal receipt bytes (stubbed until hardware added)
- **image_picker** — product photos from camera/gallery
- Money is stored as **integer centavos** everywhere; formatted to ₱ only at display.

---

## First run

This repo ships the Dart app only. Generate the platform folders, fetch
packages, run codegen, then launch:

```bash
cd jollipos

# 1) Generate android/ios/web/etc. platform projects
flutter create .

# 2) Dependencies
flutter pub get

# 3) Code generation (freezed + drift + json_serializable)
dart run build_runner build --delete-conflicting-outputs

# 4) Run on a connected device / simulator
flutter run
```

### Build
```bash
flutter build apk        # Android
flutter build ipa        # iOS (requires signing)
```

### Tablet notes
The layout is responsive via `LayoutBuilder`/`MediaQuery`:
- **Tablet / landscape:** menu grid + persistent live cart panel side-by-side.
- **Phone / portrait:** product grid with a floating cart button that opens a
  bottom sheet.

### image_picker permissions
After `flutter create .`, add the usage strings:
- **iOS** — in `ios/Runner/Info.plist`:
  ```xml
  <key>NSCameraUsageDescription</key>
  <string>Take photos of menu items.</string>
  <key>NSPhotoLibraryUsageDescription</key>
  <string>Attach photos to menu items.</string>
  ```
- **Android** — camera is requested at runtime; no manifest change needed for
  `image_picker` on modern Android.

---

## Sample login PINs (seeded on first launch)
| Role    | Name          | PIN  |
|---------|---------------|------|
| Admin   | Store Manager | 1234 |
| Cashier | Cashier 1     | 0000 |

These are the **only** things seeded automatically. The product catalog starts
**empty**.

---

## How to encode your menu (no coding)

Open **Admin → Menu Management**. Four tabs:

1. **Categories** — Add categories (e.g. Chicken, Burgers, Drinks). Set a sort
   order and pick an icon. Deleting a category removes its products too.
2. **Modifiers** — Create modifier groups like *Size* (choose one) or *Add-ons*
   (choose many, min/max), each with options and a **+price** in pesos.
3. **Products** — Add items: name, category, **price**, description, a **photo**
   (camera/gallery), an **Available / Sold-Out** toggle, a **Combo** flag, and
   tick which **modifier groups** apply. Use the ⋮ menu to **Edit / Duplicate /
   Delete**.
4. **Tools** —
   - **Load Sample Menu**: optional demo data you can fully edit/delete.
   - **Clear Entire Menu**: wipes the catalog (keeps staff + past orders).
   - **Export Menu (JSON)**: preview a snapshot of your catalog.

Anything you change here appears on the **ordering screen instantly** — no app
rebuild, no code change. If the catalog is empty, the ordering screen shows a
friendly *"No products yet"* prompt with a shortcut to Menu Management.

---

## Architecture
```
lib/
  core/         theme, router, DI, constants, utils (money, pin_hasher, responsive)
  domain/       entities + repository interfaces (pure Dart)
  data/         Drift DB, DAOs, repository implementations, printing
  presentation/ features (menu, cart, checkout, receipt, KDS, admin) + Riverpod providers
```
Repositories are interfaces with local Drift implementations, so a cloud backend
can be added later without touching the UI.

---

## Implemented vs. assumptions

**Implemented**
- 100% dynamic, user-encoded catalog (no hardcoded menu) with live updates.
- Menu Management CRUD: categories, products (with photos), modifier groups.
- Optional sample-menu loader + clear + JSON export.
- Ordering screen (grid + live cart), modifier selection, PH VAT 12% +
  Senior/PWD discount math, checkout, receipt (ESC/POS bytes via stub), KDS
  status flow — all reading user data.

**Assumptions / next phases** (scoped, not yet built)
- Per-product **stock** & **VAT type** columns (needs a Drift migration).
- **Combo slot builder** & **promos engine** (schema + UI).
- **Split payments**, **GCash/e-wallet QR**.
- **Shift / cash management** with X & Z readings.
- **Reports & dashboard** (fl_chart).
- **Bluetooth/thermal printing** transport + PDF/share fallback.
- **PIN login gate + role-based permission** enforcement.
- **CSV import** and **cloud sync** queue.
