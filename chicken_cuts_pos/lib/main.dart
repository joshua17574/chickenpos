import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/http_pos_repository.dart';
import 'services/local_pos_repository.dart';
import 'services/pos_repository.dart';
import 'services/store.dart';
import 'theme.dart';
import 'screens/sell_screen.dart';
import 'screens/inventory_screen.dart';
import 'screens/history_screen.dart';
import 'screens/reports_screen.dart';
import 'widgets/ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const apiBaseUrl = String.fromEnvironment('POS_API_BASE_URL');
  const apiKey = String.fromEnvironment('POS_API_KEY');
  final usesRemoteData = apiBaseUrl.trim().isNotEmpty;
  final store = Store(
    repository: _buildRepository(apiBaseUrl: apiBaseUrl, apiKey: apiKey),
    usesRemoteData: usesRemoteData,
    refreshInterval: usesRemoteData ? const Duration(seconds: 10) : null,
  );
  await store.init();
  runApp(ChangeNotifierProvider.value(value: store, child: const PosApp()));
}

PosRepository _buildRepository({
  required String apiBaseUrl,
  required String apiKey,
}) {
  if (apiBaseUrl.trim().isEmpty) {
    return LocalPosRepository();
  }
  return HttpPosRepository(
    baseUrl: apiBaseUrl,
    apiKey: apiKey.trim().isEmpty ? null : apiKey,
  );
}

class PosApp extends StatelessWidget {
  const PosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chicken Cuts POS',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      home: const HomeShell(),
    );
  }
}

class _Dest {
  final IconData icon;
  final IconData active;
  final String label;
  const _Dest(this.icon, this.active, this.label);
}

const _destinations = [
  _Dest(Icons.point_of_sale_outlined, Icons.point_of_sale, 'Sell'),
  _Dest(Icons.inventory_2_outlined, Icons.inventory_2, 'Inventory'),
  _Dest(Icons.receipt_long_outlined, Icons.receipt_long, 'History'),
  _Dest(Icons.insights_outlined, Icons.insights, 'Reports'),
];

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  final _screens = const [
    SellScreen(),
    InventoryScreen(),
    HistoryScreen(),
    ReportsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 760;
    return Scaffold(
      body: Column(
        children: [
          _BrandHeader(title: _destinations[_index].label),
          Expanded(
            child: wide
                ? Row(
                    children: [
                      _SideNav(
                        index: _index,
                        onTap: (i) => setState(() => _index = i),
                      ),
                      Expanded(child: _screens[_index]),
                    ],
                  )
                : _screens[_index],
          ),
        ],
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: [
                for (final d in _destinations)
                  NavigationDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.active),
                    label: d.label,
                  ),
              ],
            ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  final String title;
  const _BrandHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<Store>();
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.brandGradient),
      child: Stack(
        children: [
          const CutPattern(),
          Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 14,
              bottom: 16,
              left: 18,
              right: 18,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const BrandMark(size: 48),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Chicken Cuts',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '$title counter',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.76),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (store.usesRemoteData) ...[
                      IconButton(
                        tooltip: 'Sync inventory',
                        visualDensity: VisualDensity.compact,
                        onPressed: store.isSyncing
                            ? null
                            : () => unawaited(
                                  store.refreshFromRepository().catchError(
                                        (_) {},
                                      ),
                                ),
                        icon: store.isSyncing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.sync_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                      ),
                      const SizedBox(width: 2),
                    ],
                    _DataSourceBadge(store: store),
                  ],
                ),
                if (store.usesRemoteData && store.lastSyncedAt != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _HeaderChip(
                        icon: Icons.storefront_rounded,
                        label: '${store.products.length} POS items',
                      ),
                      const SizedBox(width: 8),
                      const _HeaderChip(
                        icon: Icons.schedule_rounded,
                        label: 'Live stock',
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _HeaderChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.86),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _DataSourceBadge extends StatelessWidget {
  final Store store;
  const _DataSourceBadge({required this.store});

  @override
  Widget build(BuildContext context) {
    final hasError = store.syncError != null;
    final icon = store.usesRemoteData
        ? hasError
            ? Icons.cloud_off_outlined
            : Icons.cloud_done_outlined
        : Icons.phone_iphone;
    final label = store.usesRemoteData
        ? hasError
            ? 'Sync'
            : 'DB'
        : 'Local';
    final color = store.usesRemoteData && !hasError
        ? AppColors.success
        : hasError
            ? AppColors.warning
            : Colors.white;

    return Tooltip(
      message: store.syncError ??
          (store.usesRemoteData
              ? 'Using MongoDB inventory'
              : 'Using local preview data'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SideNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const _SideNav({required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 108,
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          right: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.26)),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      child: Column(
        children: [
          for (var i = 0; i < _destinations.length; i++)
            _navItem(i, _destinations[i], i == index),
        ],
      ),
    );
  }

  Widget _navItem(int i, _Dest d, bool sel) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => onTap(i),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              color: sel ? AppColors.header : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: sel
                    ? Colors.transparent
                    : AppColors.line.withValues(alpha: 0.0),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  sel ? d.active : d.icon,
                  color: sel ? Colors.white : AppColors.muted,
                  size: 24,
                ),
                const SizedBox(height: 5),
                Text(
                  d.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: sel ? Colors.white : AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
