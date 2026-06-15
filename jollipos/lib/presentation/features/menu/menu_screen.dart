import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/responsive.dart';
import '../../providers/cart_providers.dart';
import '../../providers/catalog_providers.dart';
import '../cart/widgets/cart_panel.dart';
import 'widgets/category_selector.dart';
import 'widgets/menu_grid.dart';

/// Menu + cart. Tablet shows a master-detail (grid + persistent cart panel);
/// phone shows the grid with a floating cart button that opens a bottom sheet.
class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  void _checkout(BuildContext context) {
    context.push(Routes.checkout);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuArea = Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search menu…',
            ),
            onChanged: (v) =>
                ref.read(menuSearchProvider.notifier).state = v,
          ),
        ),
        const CategorySelector(),
        const Expanded(child: MenuGrid()),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('${AppConstants.appName} · Menu'),
      ),
      body: context.isTabletOrWider
          ? Row(
              children: [
                Expanded(child: menuArea),
                const VerticalDivider(width: 1),
                SizedBox(
                  width: 380,
                  child: Material(
                    elevation: 2,
                    child: CartPanel(onCheckout: () => _checkout(context)),
                  ),
                ),
              ],
            )
          : menuArea,
      floatingActionButton:
          context.isPhone ? _CartFab(onCheckout: () => _checkout(context)) : null,
    );
  }
}

/// Phone-only cart access: shows count + total, opens the cart bottom sheet.
class _CartFab extends ConsumerWidget {
  const _CartFab({required this.onCheckout});
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartControllerProvider);
    final total = ref.watch(draftOrderProvider).totalCentavos;
    if (cart.isEmpty) return const SizedBox.shrink();

    return FloatingActionButton.extended(
      onPressed: () => _openCart(context),
      icon: Badge(
        label: Text('${cart.unitCount}'),
        child: const Icon(Icons.shopping_cart),
      ),
      label: Text('View Cart · ${Money.format(total)}'),
    );
  }

  Future<void> _openCart(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, scrollController) => CartPanel(
          onCheckout: () {
            Navigator.pop(context);
            onCheckout();
          },
        ),
      ),
    );
  }
}
