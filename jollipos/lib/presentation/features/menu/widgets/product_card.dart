import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/money.dart';
import '../../../../domain/entities/product.dart';

/// Tap-to-add product tile with availability + combo state.
class ProductCard extends StatelessWidget {
  const ProductCard({required this.product, required this.onTap, super.key});

  final Product product;
  final VoidCallback onTap;

  bool get _sellable => product.available && product.basePriceCentavos > 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Opacity(
      opacity: _sellable ? 1 : 0.5,
      child: Card(
        child: InkWell(
          onTap: _sellable ? onTap : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      color: AppColors.brandYellow.withValues(alpha: 0.18),
                      child: Icon(
                        product.isCombo ? Icons.fastfood : Icons.lunch_dining,
                        size: 44,
                        color: AppColors.brandRed,
                      ),
                    ),
                    if (product.isCombo)
                      const Positioned(
                        top: 6,
                        left: 6,
                        child: _Badge(label: 'VALUE', color: AppColors.brandRed),
                      ),
                    if (!_sellable)
                      const Positioned(
                        top: 6,
                        right: 6,
                        child: _Badge(label: 'UNAVAILABLE', color: Colors.black54),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          Money.format(product.basePriceCentavos),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: AppColors.brandRed,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (product.hasModifiers)
                          Icon(Icons.tune, size: 16, color: theme.hintColor),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}
