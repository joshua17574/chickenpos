import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';
import '../../providers/catalog_providers.dart';

/// Admin hub. Menu Management is fully built; other modules are flagged as
/// upcoming so the roadmap is honest and discoverable.
class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productCount = ref.watch(productsProvider).valueOrNull?.length ?? 0;
    final categoryCount =
        ref.watch(categoriesProvider).valueOrNull?.length ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('${AppConstants.appName} · Admin')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.restaurant_menu)),
              title: const Text('Menu Management',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                '$productCount products · $categoryCount categories\n'
                'Encode your own products, prices, categories & modifiers.',
              ),
              isThreeLine: true,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(Routes.menuManagement),
            ),
          ),
          const SizedBox(height: 8),
          const _ComingSoonTile(
            icon: Icons.point_of_sale,
            title: 'Shift & Cash Management',
            note: 'Open/close shift, float, X & Z readings.',
          ),
          const _ComingSoonTile(
            icon: Icons.insights,
            title: 'Reports & Dashboard',
            note: 'Sales, top-sellers, payment mix (fl_chart).',
          ),
          const _ComingSoonTile(
            icon: Icons.people,
            title: 'Users & Roles',
            note: 'Manage staff PINs and permissions.',
          ),
        ],
      ),
    );
  }
}

class _ComingSoonTile extends StatelessWidget {
  const _ComingSoonTile({
    required this.icon,
    required this.title,
    required this.note,
  });

  final IconData icon;
  final String title;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).disabledColor),
        title: Text(title),
        subtitle: Text(note),
        trailing: const Chip(label: Text('Soon')),
        enabled: false,
      ),
    );
  }
}
