import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../data/services/invoice_service.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/catalog_viewmodel.dart';
import '../../widgets/app_button.dart';

class InvoiceScreen extends StatefulWidget {
  const InvoiceScreen({super.key});

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  final _date = DateTime.now();

  Future<void> _print(bool share) async {
    final user = context.read<AuthViewModel>().user!;
    final lines = context.read<CatalogViewModel>().invoiceLines;
    final bytes = await context.read<InvoiceService>().build(
      user,
      lines,
      _date,
    );
    final name = '${InvoiceService.number(_date)}.pdf';
    if (share) {
      await Printing.sharePdf(bytes: bytes, filename: name);
    } else {
      await Printing.layoutPdf(onLayout: (_) async => bytes, name: name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().user;
    // Null while logging out, before the login route replaces this screen.
    if (user == null) return const SizedBox.shrink();
    final vm = context.watch<CatalogViewModel>();
    final lines = vm.invoiceLines;
    return Scaffold(
      appBar: AppBar(title: const Text('Invoice')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    InvoiceService.number(_date),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  Text(Formatters.date(_date)),
                  const SizedBox(height: 12),
                  const Text('Bill to', style: TextStyle(fontSize: 12)),
                  Text(
                    user.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  if (user.organization.isNotEmpty) Text(user.organization),
                  const Divider(height: 28),
                  for (final l in lines)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l.product.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${l.qty} × ${Formatters.money(l.product.price)} · ${l.product.supplierName}',
                                  style: const TextStyle(fontSize: 12.5),
                                ),
                              ],
                            ),
                          ),
                          Text(Formatters.money(l.subtotal)),
                        ],
                      ),
                    ),
                  const Divider(height: 28),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Total',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Text(
                        Formatters.money(vm.selectedTotal),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          AppButton(
            label: 'Share PDF',
            icon: Icons.ios_share,
            onPressed: () => _print(true),
          ),
          const SizedBox(height: 10),
          AppButton(
            label: 'Print / preview',
            icon: Icons.print_outlined,
            outlined: true,
            onPressed: () => _print(false),
          ),
        ],
      ),
    );
  }
}
