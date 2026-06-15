import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/money.dart';
import '../../../../domain/entities/enums.dart';
import '../../../../domain/entities/payment.dart';
import '../../../providers/checkout_providers.dart';

/// Collects a single payment of [method] toward [balanceCentavos].
/// Supports partial (split) amounts and, for cash, a change calculator.
class PaymentSheet extends ConsumerStatefulWidget {
  const PaymentSheet({
    required this.method,
    required this.balanceCentavos,
    super.key,
  });

  final PaymentMethod method;
  final int balanceCentavos;

  @override
  ConsumerState<PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends ConsumerState<PaymentSheet> {
  late final TextEditingController _amountCtrl;
  final _refCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(
      text: Money.toPesos(widget.balanceCentavos).toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _refCtrl.dispose();
    super.dispose();
  }

  int get _enteredCentavos =>
      Money.toCentavos(double.tryParse(_amountCtrl.text) ?? 0);

  bool get _isCash => widget.method == PaymentMethod.cash;

  int get _changeCentavos =>
      _isCash ? (_enteredCentavos - widget.balanceCentavos).clamp(0, 1 << 62) : 0;

  void _confirm() {
    final controller = ref.read(checkoutControllerProvider.notifier);
    final entered = _enteredCentavos;
    if (entered <= 0) return;

    final Payment payment;
    if (_isCash) {
      // Tendered ≥ balance ⇒ fully covers balance with change; else partial.
      final applied =
          entered >= widget.balanceCentavos ? widget.balanceCentavos : entered;
      payment = controller.cash(
        amountCentavos: applied,
        tenderedCentavos: entered,
      );
    } else if (widget.method == PaymentMethod.card) {
      payment = controller.card(
        amountCentavos: entered.clamp(0, widget.balanceCentavos),
        reference: _refCtrl.text.trim(),
      );
    } else {
      payment = controller.eWallet(
        amountCentavos: entered.clamp(0, widget.balanceCentavos),
        reference: _refCtrl.text.trim(),
      );
    }
    controller.addPayment(payment);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('${widget.method.label} payment',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text('Balance due: ${Money.format(widget.balanceCentavos)}'),
          const SizedBox(height: 12),
          TextField(
            controller: _amountCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: InputDecoration(
              labelText: _isCash ? 'Cash tendered (₱)' : 'Amount (₱)',
              prefixText: '₱ ',
            ),
            onChanged: (_) => setState(() {}),
          ),
          if (_isCash) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                _quick(widget.balanceCentavos, 'Exact'),
                for (final amt in const [10000, 20000, 50000, 100000])
                  _quick(amt, Money.format(amt)),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Change'),
                  Text(Money.format(_changeCentavos),
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.success)),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 10),
            TextField(
              controller: _refCtrl,
              decoration: InputDecoration(
                labelText: widget.method == PaymentMethod.card
                    ? 'Card ref / approval code'
                    : 'E-wallet reference (auto if blank)',
              ),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _enteredCentavos > 0 ? _confirm : null,
            child: const Text('Add payment'),
          ),
        ],
      ),
    );
  }

  Widget _quick(int centavos, String label) => ActionChip(
        label: Text(label),
        onPressed: () => setState(() {
          _amountCtrl.text = Money.toPesos(centavos).toStringAsFixed(2);
        }),
      );
}
