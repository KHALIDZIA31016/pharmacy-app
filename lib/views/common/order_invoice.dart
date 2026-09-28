import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../core/utils/ui.dart';
import '../../data/models/app_user.dart';
import '../../data/models/order.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/services/invoice_service.dart';

/// Downloads (shares) or prints the branded PDF invoice for [order].
/// Refused until the supplier has approved the order.
Future<void> showOrderInvoice(
  BuildContext context,
  Order order,
  AppUser billTo, {
  bool share = true,
}) async {
  if (!order.isApproved) {
    showSnack(
      context,
      'The invoice unlocks once ${order.supplierName} approves this order.',
      error: true,
    );
    return;
  }
  try {
    final supplier = await context.read<UserRepository>().getById(
      order.supplierId,
    );
    if (!context.mounted) return;
    final bytes = await context.read<InvoiceService>().buildOrderInvoice(
      billTo: billTo,
      supplier: supplier,
      order: order,
    );
    final name = 'INV-${order.id.toString().padLeft(5, '0')}.pdf';
    if (share) {
      await Printing.sharePdf(bytes: bytes, filename: name);
    } else {
      await Printing.layoutPdf(onLayout: (_) async => bytes, name: name);
    }
  } catch (_) {
    if (context.mounted) {
      showSnack(context, 'Could not create the invoice.', error: true);
    }
  }
}
