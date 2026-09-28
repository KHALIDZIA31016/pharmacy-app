import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/ui.dart';
import '../../core/utils/validators.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/catalog_viewmodel.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/section_header.dart';
import '../../widgets/status_chip.dart';

/// Ask the admin to add a supply that is missing from the list.
class SupplyRequestScreen extends StatefulWidget {
  const SupplyRequestScreen({super.key});

  @override
  State<SupplyRequestScreen> createState() => _SupplyRequestScreenState();
}

class _SupplyRequestScreenState extends State<SupplyRequestScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _details = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _details.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final user = context.read<AuthViewModel>().user!;
    await context.read<CatalogViewModel>().requestSupply(
      user,
      _name.text,
      _details.text,
    );
    if (!mounted) return;
    _name.clear();
    _details.clear();
    showSnack(context, 'Request sent to admin');
  }

  @override
  Widget build(BuildContext context) {
    final requests = context.watch<CatalogViewModel>().requests;
    return Scaffold(
      appBar: AppBar(title: const Text('Request an item')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Form(
            key: _form,
            child: Column(
              children: [
                AppTextField(
                  controller: _name,
                  label: 'Item name',
                  icon: Icons.medication_outlined,
                  validator: (v) => Validators.required(v, 'Item name'),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _details,
                  label: 'Details (strength, pack size, brand)',
                  icon: Icons.notes,
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                AppButton(label: 'Send request', onPressed: _submit),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const SectionHeader('My requests'),
          const SizedBox(height: 8),
          if (requests.isEmpty)
            const Text(
              'No requests yet.',
              style: TextStyle(color: AppColors.textSecondary),
            )
          else
            for (final r in requests)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  child: ListTile(
                    title: Text(
                      r.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(Formatters.date(r.createdAt)),
                    trailing: StatusChip(r.status),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
