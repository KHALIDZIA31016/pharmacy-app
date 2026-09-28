import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/category_style.dart';
import '../core/utils/formatters.dart';
import '../core/utils/validators.dart';
import '../data/models/product.dart';
import '../data/models/supply_change.dart';
import 'app_button.dart';
import 'image_picker_field.dart';
import 'supply_image.dart';
import 'app_text_field.dart';
import 'supply_form_sheet.dart';

/// Outcome of the popup: an edited draft to send, or a deletion request.
class SupplyDetailResult {
  final SupplyDraft? draft;
  final bool delete;
  const SupplyDetailResult.update(SupplyDraft this.draft) : delete = false;
  const SupplyDetailResult.delete() : draft = null, delete = true;
}

/// Themed popup for one supply: name, category, price, and an Edit button.
/// Editing happens inside the popup and ends with "Send request".
Future<SupplyDetailResult?> showSupplyDetail(
  BuildContext context, {
  required Product product,
  SupplyChange? pending,
  bool isNew = false,
  required List<String> categories,
}) {
  return showModalBottomSheet<SupplyDetailResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SupplyDetail(
      product: product,
      pending: pending,
      isNew: isNew,
      categories: categories,
    ),
  );
}

class _SupplyDetail extends StatefulWidget {
  final Product product;
  final SupplyChange? pending;
  final bool isNew; // price-list item being requested as a new supply
  final List<String> categories;
  const _SupplyDetail({
    required this.product,
    this.pending,
    this.isNew = false,
    required this.categories,
  });

  @override
  State<_SupplyDetail> createState() => _SupplyDetailState();
}

class _SupplyDetailState extends State<_SupplyDetail> {
  final _key = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.product.name);
  late final _category = TextEditingController(text: widget.product.category);
  late final _unit = TextEditingController(text: widget.product.unit);
  late final _price = TextEditingController(
    text: widget.product.price.toString(),
  );
  String? _image; // newly chosen photo (null = keep current)
  bool _editing = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _category, _unit, _price]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _changed {
    final p = widget.product;
    return _name.text.trim() != p.name ||
        _category.text.trim() != p.category ||
        _unit.text.trim() != p.unit ||
        double.tryParse(_price.text) != p.price ||
        _image != null;
  }

  void _send() {
    if (!_key.currentState!.validate()) return;
    if (!widget.isNew && !_changed) {
      setState(() => _error = 'Change something before sending.');
      return;
    }
    Navigator.pop(
      context,
      SupplyDetailResult.update(
        SupplyDraft(
          _name.text.trim(),
          _category.text.trim(),
          _unit.text.trim(),
          double.parse(_price.text),
          _image,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final style = CategoryStyle.of(_editing ? _category.text : p.category);
    return Container(
      margin: const EdgeInsets.only(top: 60),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Themed header band
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    style.color.withValues(alpha: 0.95),
                    Color.lerp(style.color, AppColors.primaryDark, 0.5)!,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 18),
                  if ((_image ?? p.imagePath) != null)
                    SupplyImage(
                      path: _image ?? p.imagePath,
                      style: style,
                      size: 72,
                      radius: 20,
                    )
                  else
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(style.icon, color: Colors.white, size: 32),
                    ),
                  const SizedBox(height: 12),
                  Text(
                    _editing
                        ? (widget.isNew ? 'Request supply' : 'Edit supply')
                        : p.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: _editing ? _editForm() : _viewBody(p, style),
            ),
          ],
        ),
      ),
    );
  }

  Widget _viewBody(Product p, CategoryStyle style) {
    final pending = widget.pending;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _Fact(
                'Category',
                p.category,
                icon: style.icon,
                color: style.color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Fact(
                'Price',
                Formatters.money(p.price),
                icon: Icons.sell_outlined,
                color: AppColors.primaryDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (pending != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.hourglass_top_rounded,
                  size: 18,
                  color: AppColors.warning,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    pending.action == ChangeAction.delete
                        ? 'A deletion request is awaiting admin approval.'
                        : 'An edit request is awaiting admin approval.',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          )
        else ...[
          AppButton(
            label: 'Edit',
            icon: Icons.edit_outlined,
            onPressed: () => setState(() => _editing = true),
          ),
          const SizedBox(height: 4),
          if (!widget.isNew)
            TextButton.icon(
              onPressed: () =>
                  Navigator.pop(context, const SupplyDetailResult.delete()),
              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Request deletion'),
            ),
        ],
      ],
    );
  }

  Widget _editForm() {
    final choices = ({...widget.categories, widget.product.category}.toList()
      ..sort());
    return Form(
      key: _key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ImagePickerField(
            path: _image ?? widget.product.imagePath,
            onChanged: (v) => setState(() => _image = v),
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: _name,
            label: 'Name',
            icon: Icons.medication_outlined,
            validator: (v) => Validators.required(v, 'Name'),
          ),
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
              for (final c in choices)
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
                  label: 'Unit',
                  validator: (v) => Validators.required(v, 'Unit'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppTextField(
                  controller: _price,
                  label: 'Price',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: Validators.positiveNumber,
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: AppColors.danger)),
          ],
          const SizedBox(height: 18),
          AppButton(
            label: 'Send request to admin',
            icon: Icons.send_rounded,
            onPressed: _send,
          ),
          const SizedBox(height: 6),
          Center(
            child: TextButton(
              onPressed: () => setState(() {
                _editing = false;
                _error = null;
              }),
              child: const Text('Cancel'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _Fact(
    this.label,
    this.value, {
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}
