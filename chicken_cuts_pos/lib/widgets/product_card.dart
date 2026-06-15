import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/format.dart';
import '../services/store.dart';
import '../theme.dart';
import 'ui.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  const ProductCard({super.key, required this.product, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final p = product;
    final low = p.stock > 0 && p.stock <= Store.lowStockThreshold;
    final disabled = !p.sellable;
    final categoryColor = AppColors.category(p.category);
    final margin = p.sell - p.buy;

    Widget stockPill;
    if (p.stock <= 0) {
      stockPill = const StatusPill(
        text: 'Out of stock',
        color: AppColors.danger,
        icon: Icons.block,
      );
    } else if (low) {
      stockPill = StatusPill(
        text: '${p.stock} left',
        color: AppColors.warning,
        icon: Icons.warning_amber_rounded,
      );
    } else {
      stockPill = StatusPill(
        text: '${p.stock} in stock',
        color: AppColors.success,
        icon: Icons.check_circle_outline,
      );
    }

    return Opacity(
      opacity: disabled ? 0.55 : 1,
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.28)),
          boxShadow: [
            BoxShadow(
              color: categoryColor.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: disabled ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: categoryColor.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: categoryColor.withValues(alpha: 0.12),
                        ),
                      ),
                      child: ProductVisual(
                        name: p.name,
                        category: p.category,
                        height: 70,
                      ),
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.88),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text(
                          p.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: categoryColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  p.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  p.sell > 0 ? peso(p.sell) : 'No price set',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 19,
                    color: p.sell > 0 ? AppColors.primary : cs.outline,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  p.sell > 0
                      ? 'Margin ${peso(margin)}'
                      : 'Set price in Inventory',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: p.sell > 0 ? cs.onSurfaceVariant : AppColors.warning,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(child: stockPill),
                    const SizedBox(width: 8),
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: disabled
                            ? cs.surfaceContainerHighest
                            : AppColors.header,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(
                        disabled ? Icons.lock_outline : Icons.add,
                        color: disabled ? cs.onSurfaceVariant : Colors.white,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
