import 'package:flutter/material.dart';

import '../../../../core/utils/money.dart';
import '../../../../domain/entities/enums.dart';
import '../../../../domain/entities/modifier.dart';
import '../../../providers/catalog_providers.dart';

/// Add / edit a [ModifierGroup] and its options. Pops with the resulting group.
class ModifierGroupEditor extends StatefulWidget {
  const ModifierGroupEditor({required this.existing, super.key});

  final ModifierGroup? existing;

  @override
  State<ModifierGroupEditor> createState() => _ModifierGroupEditorState();
}

class _ModifierGroupEditorState extends State<ModifierGroupEditor> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name =
      TextEditingController(text: widget.existing?.name ?? '');
  late ModifierSelection _selection =
      widget.existing?.selection ?? ModifierSelection.single;
  late bool _required = widget.existing?.required ?? false;
  late int _min = widget.existing?.min ?? 1;
  late int _max = widget.existing?.max ?? 1;

  // Editable option rows. Each keeps its own controllers.
  late final List<_OptionRow> _options = (widget.existing?.options ??
          const <Modifier>[])
      .map((m) => _OptionRow(
            id: m.id,
            name: TextEditingController(text: m.name),
            price: TextEditingController(
                text: m.priceDeltaCentavos == 0
                    ? ''
                    : Money.toPesos(m.priceDeltaCentavos).toStringAsFixed(2)),
          ))
      .toList();

  @override
  void initState() {
    super.initState();
    if (_options.isEmpty) _options.add(_OptionRow.empty());
  }

  @override
  void dispose() {
    _name.dispose();
    for (final o in _options) {
      o.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSingle = _selection == ModifierSelection.single;
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.existing == null ? 'New Modifier Group' : 'Edit Modifier'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('SAVE', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Group name (e.g. Size, Spice Level)',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            SegmentedButton<ModifierSelection>(
              segments: const [
                ButtonSegment(
                  value: ModifierSelection.single,
                  label: Text('Choose one'),
                  icon: Icon(Icons.radio_button_checked),
                ),
                ButtonSegment(
                  value: ModifierSelection.multiple,
                  label: Text('Choose many'),
                  icon: Icon(Icons.check_box),
                ),
              ],
              selected: {_selection},
              onSelectionChanged: (s) => setState(() {
                _selection = s.first;
                if (_selection == ModifierSelection.single) {
                  _min = _required ? 1 : 0;
                  _max = 1;
                }
              }),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Required'),
              subtitle: const Text('Customer must make a selection'),
              value: _required,
              onChanged: (v) => setState(() {
                _required = v;
                if (isSingle) _min = v ? 1 : 0;
              }),
            ),
            if (!isSingle) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _NumberStepper(
                      label: 'Min',
                      value: _min,
                      min: 0,
                      onChanged: (v) => setState(() => _min = v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _NumberStepper(
                      label: 'Max',
                      value: _max,
                      min: 1,
                      onChanged: (v) => setState(() => _max = v),
                    ),
                  ),
                ],
              ),
            ],
            const Divider(height: 24),
            Text('Options', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (var i = 0; i < _options.length; i++) _optionRow(i),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () =>
                  setState(() => _options.add(_OptionRow.empty())),
              icon: const Icon(Icons.add),
              label: const Text('Add option'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _optionRow(int i) {
    final row = _options[i];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: row.name,
              decoration: const InputDecoration(
                labelText: 'Option name',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name?' : null,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: row.price,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: '+ price',
                prefixText: '₱',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null; // 0 = free
                return Money.parsePesos(v) == null ? 'Bad' : null;
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: _options.length == 1
                ? null
                : () => setState(() => _options.removeAt(i)),
          ),
        ],
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final groupId = widget.existing?.id ?? newId('grp');
    final options = <Modifier>[];
    for (final row in _options) {
      final name = row.name.text.trim();
      if (name.isEmpty) continue;
      options.add(Modifier(
        id: row.id ?? newId('mod'),
        name: name,
        priceDeltaCentavos: Money.parsePesos(row.price.text) ?? 0,
      ));
    }
    if (options.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one option')),
      );
      return;
    }
    // Clamp min/max sensibly.
    final max = _selection == ModifierSelection.single
        ? 1
        : _max.clamp(1, options.length);
    final min = _selection == ModifierSelection.single
        ? (_required ? 1 : 0)
        : _min.clamp(0, max);

    final group = ModifierGroup(
      id: groupId,
      name: _name.text.trim(),
      selection: _selection,
      required: _required,
      min: min,
      max: max,
      options: options,
    );
    Navigator.pop(context, group);
  }
}

class _OptionRow {
  _OptionRow({this.id, required this.name, required this.price});
  factory _OptionRow.empty() =>
      _OptionRow(name: TextEditingController(), price: TextEditingController());

  final String? id;
  final TextEditingController name;
  final TextEditingController price;

  void dispose() {
    name.dispose();
    price.dispose();
  }
}

class _NumberStepper extends StatelessWidget {
  const _NumberStepper({
    required this.label,
    required this.value,
    required this.min,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int min;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: value > min ? () => onChanged(value - 1) : null,
          ),
          Text('$value', style: Theme.of(context).textTheme.titleMedium),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => onChanged(value + 1),
          ),
        ],
      ),
    );
  }
}
