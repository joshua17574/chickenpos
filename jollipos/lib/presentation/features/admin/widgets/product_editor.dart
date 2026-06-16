import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/utils/money.dart';
import '../../../../domain/entities/product.dart';
import '../../../providers/catalog_providers.dart';

/// Add / edit a [Product]. Pops with the resulting product, or null on cancel.
/// Photos are taken from camera/gallery and the local file path is stored on
/// the product ([Product.imageAsset]); a placeholder shows when none is set.
class ProductEditor extends ConsumerStatefulWidget {
  const ProductEditor({
    required this.existing,
    required this.nextSortOrder,
    super.key,
  });

  final Product? existing;
  final int nextSortOrder;

  @override
  ConsumerState<ProductEditor> createState() => _ProductEditorState();
}

class _ProductEditorState extends ConsumerState<ProductEditor> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  late final TextEditingController _name =
      TextEditingController(text: widget.existing?.name ?? '');
  late final TextEditingController _price = TextEditingController(
    text: widget.existing == null
        ? ''
        : Money.toPesos(widget.existing!.basePriceCentavos)
            .toStringAsFixed(2),
  );
  late final TextEditingController _desc =
      TextEditingController(text: widget.existing?.description ?? '');

  late String? _categoryId = widget.existing?.categoryId;
  late bool _available = widget.existing?.available ?? true;
  late bool _isCombo = widget.existing?.isCombo ?? false;
  late String _imagePath = widget.existing?.imageAsset ?? '';
  late Set<String> _groupIds =
      {...(widget.existing?.modifierGroupIds ?? const <String>[])};

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _desc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider).valueOrNull ?? const [];
    final groups = ref.watch(modifierGroupsProvider).valueOrNull ?? const [];
    // Default the category to the first one when adding a new product.
    _categoryId ??= categories.isNotEmpty ? categories.first.id : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'New Product' : 'Edit Product'),
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
            _photoPicker(),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Product name',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _categoryId,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final c in categories)
                  DropdownMenuItem(value: c.id, child: Text(c.name)),
              ],
              validator: (v) => v == null ? 'Pick a category' : null,
              onChanged: (v) => setState(() => _categoryId = v),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _price,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Base price',
                prefixText: '₱ ',
                border: OutlineInputBorder(),
                helperText: 'Stored as centavos — no rounding errors',
              ),
              validator: (v) {
                final c = Money.parsePesos(v ?? '');
                if (c == null) return 'Enter a valid price';
                if (c == 0) return 'Price must be greater than 0';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _desc,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Available'),
              subtitle: const Text('Turn off to mark Sold Out / 86\u2019d'),
              value: _available,
              onChanged: (v) => setState(() => _available = v),
            ),
            SwitchListTile(
              title: const Text('Combo / Value Meal'),
              value: _isCombo,
              onChanged: (v) => setState(() => _isCombo = v),
            ),
            const Divider(height: 24),
            Text('Modifier groups',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            if (groups.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No modifier groups yet. Create some in the Modifiers tab, '
                  'then attach them here.',
                ),
              )
            else
              for (final g in groups)
                CheckboxListTile(
                  title: Text(g.name),
                  subtitle: Text('${g.options.length} option(s)'),
                  value: _groupIds.contains(g.id),
                  onChanged: (sel) => setState(() {
                    if (sel == true) {
                      _groupIds.add(g.id);
                    } else {
                      _groupIds.remove(g.id);
                    }
                  }),
                ),
          ],
        ),
      ),
    );
  }

  Widget _photoPicker() {
    final hasImage = _imagePath.isNotEmpty && File(_imagePath).existsSync();
    return Column(
      children: [
        Container(
          height: 160,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0x0D000000),
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: hasImage
              ? Image.file(File(_imagePath), fit: BoxFit.cover)
              : const Center(
                  child: Icon(Icons.add_a_photo, size: 40),
                ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(
              onPressed: () => _pick(ImageSource.camera),
              icon: const Icon(Icons.photo_camera),
              label: const Text('Camera'),
            ),
            TextButton.icon(
              onPressed: () => _pick(ImageSource.gallery),
              icon: const Icon(Icons.photo_library),
              label: const Text('Gallery'),
            ),
            if (hasImage)
              TextButton.icon(
                onPressed: () => setState(() => _imagePath = ''),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Remove'),
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        imageQuality: 80,
      );
      if (file != null) setState(() => _imagePath = file.path);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not access the camera/gallery')),
        );
      }
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final product = Product(
      id: widget.existing?.id ?? newId('p'),
      categoryId: _categoryId!,
      name: _name.text.trim(),
      basePriceCentavos: Money.parsePesos(_price.text)!,
      description: _desc.text.trim(),
      imageAsset: _imagePath,
      available: _available,
      isCombo: _isCombo,
      sortOrder: widget.existing?.sortOrder ?? widget.nextSortOrder,
      modifierGroupIds: _groupIds.toList(),
    );
    Navigator.pop(context, product);
  }
}
