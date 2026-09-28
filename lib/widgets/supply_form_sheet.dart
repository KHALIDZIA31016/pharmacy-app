import 'package:flutter/material.dart';

import '../core/constants/supply_suggestions.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/validators.dart';
import '../data/models/product.dart';
import 'app_button.dart';
import 'image_picker_field.dart';
import 'app_text_field.dart';

class SupplyDraft {
  final String name;
  final String category;
  final String unit;
  final double price;
  final String? imagePath;
  const SupplyDraft(
    this.name,
    this.category,
    this.unit,
    this.price, [
    this.imagePath,
  ]);
}

/// Bottom sheet to add ([existing] == null) or edit a supply.
Future<SupplyDraft?> showSupplyForm(
  BuildContext context, {
  Product? existing,
  SupplyDraft? initial,
  required List<String> categories,
}) {
  return showModalBottomSheet<SupplyDraft>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _SupplyForm(
      existing: existing,
      initial: initial,
      knownCategories: categories,
    ),
  );
}

class _SupplyForm extends StatefulWidget {
  final Product? existing;
  final SupplyDraft? initial;
  final List<String> knownCategories;
  const _SupplyForm({
    this.existing,
    this.initial,
    required this.knownCategories,
  });

  @override
  State<_SupplyForm> createState() => _SupplyFormState();
}

class _SupplyFormState extends State<_SupplyForm> {
  final _key = GlobalKey<FormState>();
  late final _name = TextEditingController(
    text: widget.existing?.name ?? widget.initial?.name,
  );
  late final _category = TextEditingController(
    text: widget.existing?.category ?? widget.initial?.category,
  );
  late final _unit = TextEditingController(
    text: widget.existing?.unit ?? widget.initial?.unit,
  );
  late final _price = TextEditingController(
    text:
        widget.existing?.price.toString() ??
        widget.initial?.price.toString() ??
        '',
  );

  late String? _image = widget.initial?.imagePath;

  bool get _editing => widget.existing != null;

  List<String> get _categoryChoices => ({
    ...supplySuggestions.map((s) => s.$2),
    ...widget.knownCategories,
  }.toList()..sort());

  List<(String, String, String, double)> get _matches {
    final q = _name.text.trim().toLowerCase();
    if (_editing || q.length < 2) return const [];
    return supplySuggestions
        .where((s) => s.$1.toLowerCase().contains(q) && s.$1.toLowerCase() != q)
        .take(5)
        .toList();
  }

  void _apply((String, String, String, double) s) {
    setState(() {
      _name.text = s.$1;
      _category.text = s.$2;
      _unit.text = s.$3;
      _price.text = s.$4.toStringAsFixed(s.$4 == s.$4.roundToDouble() ? 0 : 2);
    });
  }

  @override
  void dispose() {
    for (final c in [_name, _category, _unit, _price]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (!_key.currentState!.validate()) return;
    Navigator.pop(
      context,
      SupplyDraft(
        _name.text.trim(),
        _category.text.trim(),
        _unit.text.trim(),
        double.parse(_price.text),
        _image,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _key,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _editing ? 'Edit supply' : 'Add a supply',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Changes go live after the admin approves them.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              ImagePickerField(
                path: _image,
                onChanged: (v) => setState(() => _image = v),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                onChanged: (_) => setState(() {}),
                validator: (v) => Validators.required(v, 'Name'),
                decoration: const InputDecoration(
                  labelText: 'Supply name',
                  prefixIcon: Icon(Icons.medication_outlined),
                ),
              ),
              if (_matches.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final s in _matches)
                      ActionChip(
                        avatar: const Icon(Icons.bolt, size: 16),
                        label: Text(s.$1),
                        onPressed: () => _apply(s),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              AppTextField(
                controller: _category,
                label: 'Category',
                icon: Icons.category_outlined,
                validator: (v) => Validators.required(v, 'Category'),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final c in _categoryChoices)
                    ChoiceChip(
                      label: Text(c),
                      selected: _category.text.trim() == c,
                      onSelected: (_) => setState(() => _category.text = c),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _unit,
                      label: 'Unit (Strip, Box…)',
                      validator: (v) => Validators.required(v, 'Unit'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      controller: _price,
                      label: 'Rate',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: Validators.positiveNumber,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              AppButton(
                label: _editing
                    ? 'Submit update for approval'
                    : 'Submit for approval',
                icon: Icons.send_rounded,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
