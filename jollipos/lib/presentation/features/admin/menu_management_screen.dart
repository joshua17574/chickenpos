import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/di/providers.dart';
import '../../../core/utils/money.dart';
import '../../../data/local/seed_data.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/modifier.dart';
import '../../../domain/entities/product.dart';
import '../../providers/catalog_providers.dart';
import 'widgets/category_editor.dart';
import 'widgets/modifier_group_editor.dart';
import 'widgets/product_editor.dart';

/// The heart of the app: a full in-app CRUD interface so the user encodes their
/// OWN menu — zero hardcoded items. All four tabs read live from the database
/// and write straight back, so the ordering screen updates instantly.
class MenuManagementScreen extends StatelessWidget {
  const MenuManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('${AppConstants.appName} · Menu Management'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.category), text: 'Categories'),
              Tab(icon: Icon(Icons.fastfood), text: 'Products'),
              Tab(icon: Icon(Icons.tune), text: 'Modifiers'),
              Tab(icon: Icon(Icons.build), text: 'Tools'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _CategoriesTab(),
            _ProductsTab(),
            _ModifiersTab(),
            _ToolsTab(),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Categories
// ---------------------------------------------------------------------------

class _CategoriesTab extends ConsumerWidget {
  const _CategoriesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    return Scaffold(
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (categories) {
          if (categories.isEmpty) {
            return const _EmptyHint(
              icon: Icons.category_outlined,
              message: 'No categories yet.\nTap + to add your first one.',
            );
          }
          return ListView.separated(
            itemCount: categories.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final c = categories[i];
              return ListTile(
                leading: CircleAvatar(child: Text('${c.sortOrder + 1}')),
                title: Text(c.name),
                subtitle: Text('Icon: ${c.iconName}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _edit(context, ref, c),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _confirmDelete(context, ref, c),
                    ),
                  ],
                ),
                onTap: () => _edit(context, ref, c),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context, ref, null),
        icon: const Icon(Icons.add),
        label: const Text('Category'),
      ),
    );
  }

  Future<void> _edit(
      BuildContext context, WidgetRef ref, Category? existing) async {
    final existingCount =
        ref.read(categoriesProvider).valueOrNull?.length ?? 0;
    final result = await showDialog<Category>(
      context: context,
      builder: (_) => CategoryEditor(
        existing: existing,
        nextSortOrder: existing?.sortOrder ?? existingCount,
      ),
    );
    if (result != null) {
      await ref.read(catalogEditorProvider).saveCategory(result);
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Category c) async {
    final ok = await _confirm(
      context,
      'Delete "${c.name}"?',
      'All products in this category will also be deleted. This cannot be undone.',
    );
    if (ok) await ref.read(catalogEditorProvider).deleteCategory(c.id);
  }
}

// ---------------------------------------------------------------------------
// Products
// ---------------------------------------------------------------------------

class _ProductsTab extends ConsumerWidget {
  const _ProductsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);
    final categories = ref.watch(categoriesProvider).valueOrNull ?? const [];
    final catNames = {for (final c in categories) c.id: c.name};

    return Scaffold(
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (products) {
          if (categories.isEmpty) {
            return const _EmptyHint(
              icon: Icons.info_outline,
              message: 'Add a category first,\nthen you can add products to it.',
            );
          }
          if (products.isEmpty) {
            return const _EmptyHint(
              icon: Icons.fastfood_outlined,
              message: 'No products yet.\nTap + to encode your first item.',
            );
          }
          return ListView.separated(
            itemCount: products.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final p = products[i];
              return ListTile(
                leading: _Thumb(path: p.imageAsset),
                title: Text(p.name),
                subtitle: Text(
                  '${catNames[p.categoryId] ?? '—'} · '
                  '${Money.format(p.basePriceCentavos)}'
                  '${p.isCombo ? ' · Combo' : ''}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Sold out / available toggle.
                    Switch(
                      value: p.available,
                      onChanged: (v) => ref
                          .read(catalogEditorProvider)
                          .setAvailability(p.id, v),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (v) => _onMenu(context, ref, p, v),
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(
                            value: 'duplicate', child: Text('Duplicate')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  ],
                ),
                onTap: () => _edit(context, ref, p),
              );
            },
          );
        },
      ),
      floatingActionButton: categories.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _edit(context, ref, null),
              icon: const Icon(Icons.add),
              label: const Text('Product'),
            ),
    );
  }

  Future<void> _onMenu(
      BuildContext context, WidgetRef ref, Product p, String action) async {
    switch (action) {
      case 'edit':
        await _edit(context, ref, p);
      case 'duplicate':
        await ref.read(catalogEditorProvider).duplicateProduct(p);
      case 'delete':
        final ok = await _confirm(
            context, 'Delete "${p.name}"?', 'This cannot be undone.');
        if (ok) await ref.read(catalogEditorProvider).deleteProduct(p.id);
    }
  }

  Future<void> _edit(
      BuildContext context, WidgetRef ref, Product? existing) async {
    final products = ref.read(productsProvider).valueOrNull ?? const [];
    final result = await Navigator.of(context).push<Product>(
      MaterialPageRoute(
        builder: (_) => ProductEditor(
          existing: existing,
          nextSortOrder: existing?.sortOrder ?? products.length,
        ),
        fullscreenDialog: true,
      ),
    );
    if (result != null) {
      await ref.read(catalogEditorProvider).saveProduct(result);
    }
  }
}

// ---------------------------------------------------------------------------
// Modifiers
// ---------------------------------------------------------------------------

class _ModifiersTab extends ConsumerWidget {
  const _ModifiersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(modifierGroupsProvider);
    return Scaffold(
      body: groupsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (groups) {
          if (groups.isEmpty) {
            return const _EmptyHint(
              icon: Icons.tune,
              message: 'No modifier groups yet.\n'
                  'Add groups like "Size" or "Add-ons",\n'
                  'then attach them to products.',
            );
          }
          return ListView.separated(
            itemCount: groups.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final g = groups[i];
              return ListTile(
                leading: const Icon(Icons.tune),
                title: Text(g.name),
                subtitle: Text(
                  '${g.selection == ModifierSelection.single ? 'Choose one' : 'Choose ${g.min}-${g.max}'}'
                  '${g.required ? ' · required' : ''} · '
                  '${g.options.length} option(s)',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _edit(context, ref, g),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _confirmDelete(context, ref, g),
                    ),
                  ],
                ),
                onTap: () => _edit(context, ref, g),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context, ref, null),
        icon: const Icon(Icons.add),
        label: const Text('Modifier Group'),
      ),
    );
  }

  Future<void> _edit(
      BuildContext context, WidgetRef ref, ModifierGroup? existing) async {
    final result = await Navigator.of(context).push<ModifierGroup>(
      MaterialPageRoute(
        builder: (_) => ModifierGroupEditor(existing: existing),
        fullscreenDialog: true,
      ),
    );
    if (result != null) {
      await ref.read(catalogEditorProvider).saveModifierGroup(result);
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, ModifierGroup g) async {
    final ok = await _confirm(context, 'Delete "${g.name}"?',
        'Products referencing this group will simply stop showing it.');
    if (ok) await ref.read(catalogEditorProvider).deleteModifierGroup(g.id);
  }
}

// ---------------------------------------------------------------------------
// Tools — sample menu, clear, export
// ---------------------------------------------------------------------------

class _ToolsTab extends ConsumerWidget {
  const _ToolsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.auto_awesome),
            title: const Text('Load Sample Menu'),
            subtitle: const Text(
                'Optional demo data (categories, modifiers, ~26 items). '
                'You can edit or delete everything afterwards.'),
            trailing: const Icon(Icons.download),
            onTap: () => _loadSample(context, ref),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Clear Entire Menu'),
            subtitle: const Text(
                'Removes all products, modifiers and categories. '
                'Staff accounts and past orders are kept.'),
            onTap: () => _clear(context, ref),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.ios_share),
            title: const Text('Export Menu (JSON)'),
            subtitle:
                const Text('Preview a JSON snapshot of your current catalog.'),
            onTap: () => _export(context, ref),
          ),
        ),
      ],
    );
  }

  Future<void> _loadSample(BuildContext context, WidgetRef ref) async {
    final db = ref.read(databaseProvider);
    await SeedData.loadSampleMenu(db);
    if (context.mounted) _toast(context, 'Sample menu loaded');
  }

  Future<void> _clear(BuildContext context, WidgetRef ref) async {
    final ok = await _confirm(context, 'Clear entire menu?',
        'This deletes every category, product and modifier. Cannot be undone.');
    if (!ok) return;
    await ref.read(catalogEditorProvider).clearCatalog();
    if (context.mounted) _toast(context, 'Menu cleared');
  }

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final cats = ref.read(categoriesProvider).valueOrNull ?? const [];
    final prods = ref.read(productsProvider).valueOrNull ?? const [];
    final groups = ref.read(modifierGroupsProvider).valueOrNull ?? const [];
    final json = const JsonEncoder.withIndent('  ').convert({
      'categories': cats.map((c) => c.toJson()).toList(),
      'products': prods.map((p) => p.toJson()).toList(),
      'modifierGroups': groups.map((g) => g.toJson()).toList(),
    });
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Menu JSON'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(json,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared bits
// ---------------------------------------------------------------------------

class _Thumb extends StatelessWidget {
  const _Thumb({required this.path});
  final String path;

  @override
  Widget build(BuildContext context) {
    final hasImage = path.isNotEmpty && File(path).existsSync();
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 48,
        height: 48,
        child: hasImage
            ? Image.file(File(path), fit: BoxFit.cover)
            : Container(
                color: const Color(0x0D000000),
                child: const Icon(Icons.fastfood, size: 22),
              ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: Theme.of(context).disabledColor),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

void _toast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));
}

Future<bool> _confirm(BuildContext context, String title, String body) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Confirm'),
        ),
      ],
    ),
  );
  return result ?? false;
}
