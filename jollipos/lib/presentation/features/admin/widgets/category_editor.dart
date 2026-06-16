import 'package:flutter/material.dart';

import '../../../../domain/entities/category.dart';
import '../../../providers/catalog_providers.dart';

/// Add / edit a [Category]. Returns the resulting category, or null on cancel.
class CategoryEditor extends StatefulWidget {
  const CategoryEditor({
    required this.existing,
    required this.nextSortOrder,
    super.key,
  });

  final Category? existing;
  final int nextSortOrder;

  @override
  State<CategoryEditor> createState() => _CategoryEditorState();
}

class _CategoryEditorState extends State<CategoryEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name =
      TextEditingController(text: widget.existing?.name ?? '');
  late final TextEditingController _sort = TextEditingController(
      text: '${widget.existing?.sortOrder ?? widget.nextSortOrder}');
  late String _icon = widget.existing?.iconName ?? _icons.first;

  // Curated icon-name choices (string names kept in the DB, mapped to glyphs
  // in the UI). Users pick from a friendly list — no code needed.
  static const _icons = <String>[
    'category', 'drumstick', 'burger', 'pasta', 'rice', 'fries',
    'icecream', 'cup', 'combo', 'coffee', 'pizza', 'breakfast',
  ];

  @override
  void dispose() {
    _name.dispose();
    _sort.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return AlertDialog(
      title: Text(isEdit ? 'Edit Category' : 'New Category'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _name,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _sort,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Sort order',
                helperText: 'Lower numbers appear first',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _icon,
              decoration: const InputDecoration(labelText: 'Icon'),
              items: [
                for (final i in _icons)
                  DropdownMenuItem(value: i, child: Text(i)),
              ],
              onChanged: (v) => setState(() => _icon = v ?? _icon),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final category = Category(
      id: widget.existing?.id ?? newId('cat'),
      name: _name.text.trim(),
      sortOrder: int.tryParse(_sort.text.trim()) ?? widget.nextSortOrder,
      iconName: _icon,
    );
    Navigator.pop(context, category);
  }
}
