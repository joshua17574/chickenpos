import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/di/providers.dart';
import 'data/local/database.dart';
import 'data/local/seed_data.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Bootstrap: shared prefs + Drift DB.
  final prefs = await SharedPreferences.getInstance();
  final db = AppDatabase();

  // IMPORTANT — NO HARDCODED MENU.
  // We only ensure the default staff accounts exist so the manager can log in
  // and start encoding their own catalog. The product catalog starts EMPTY.
  // A sample menu can be loaded on demand from Menu Management > Tools.
  await SeedData.ensureDefaultUsers(db);

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
