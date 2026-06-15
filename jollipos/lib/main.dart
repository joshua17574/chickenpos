import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/di/providers.dart';
import 'data/local/database.dart';
import 'data/local/seed_data.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Bootstrap: shared prefs + Drift DB (seeded on first run).
  final prefs = await SharedPreferences.getInstance();
  final db = AppDatabase();
  await SeedData.seedIfEmpty(db);

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        databaseProvider.overrideWithValue(db),
      ],
      child: const JolliPosApp(),
    ),
  );
}
