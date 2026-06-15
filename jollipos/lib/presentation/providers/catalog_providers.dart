import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/modifier.dart';
import '../../domain/entities/product.dart';

/// Live catalog streams (auto-refresh from Drift).
final categoriesProvider = StreamProvider<List<Category>>(
  (ref) => ref.watch(catalogRepositoryProvider).watchCategories(),
);

final productsProvider = StreamProvider<List<Product>>(
  (ref) => ref.watch(catalogRepositoryProvider).watchProducts(),
);

final modifierGroupsProvider = FutureProvider<List<ModifierGroup>>(
  (ref) => ref.watch(catalogRepositoryProvider).getModifierGroups(),
);

/// Currently selected category id on the Menu screen (null = All).
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

/// Free-text product search query.
final menuSearchProvider = StateProvider<String>((ref) => '');

/// Products filtered by selected category + search query.
final filteredProductsProvider = Provider<List<Product>>((ref) {
  final products = ref.watch(productsProvider).valueOrNull ?? const [];
  final catId = ref.watch(selectedCategoryProvider);
  final query = ref.watch(menuSearchProvider).trim().toLowerCase();
  return products.where((p) {
    final matchesCat = catId == null || p.categoryId == catId;
    final matchesQuery = query.isEmpty || p.name.toLowerCase().contains(query);
    return matchesCat && matchesQuery;
  }).toList();
});
