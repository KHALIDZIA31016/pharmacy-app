import 'dart:io';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/utils/formatters.dart';
import '../models/app_user.dart';
import '../models/order.dart';
import '../models/product.dart';

class InvoiceLine {
  final Product product;
  final int qty;
  const InvoiceLine(this.product, this.qty);
  double get subtotal => product.price * qty;
}

class InvoiceService {
  static double total(List<InvoiceLine> lines) =>
      lines.fold(0.0, (s, l) => s + l.subtotal);

  static String number(DateTime d) =>
      'INV-${d.millisecondsSinceEpoch.toString().substring(5)}';

  /// Branded invoice for one order: supplier logo + tag, ordered items and the
  /// supplier's signature at the end. Only meant for approved orders.
  Future<Uint8List> buildOrderInvoice({
    required AppUser billTo,
    required AppUser? supplier,
    required Order order,
  }) async {
    const teal = PdfColor.fromInt(0xFF0E8A8C);
    const dark = PdfColor.fromInt(0xFF0A6466);
    const grey = PdfColors.grey700;
    final number = 'INV-${order.id.toString().padLeft(5, '0')}';
    final supplierName = supplier?.name ?? order.supplierName;

    pw.MemoryImage? readImage(String? path) {
      if (path == null || path.isEmpty) return null;
      final f = File(path);
      return f.existsSync() ? pw.MemoryImage(f.readAsBytesSync()) : null;
    }

    final logo = readImage(supplier?.photoPath);
    final signature = readImage(supplier?.signaturePath);

    pw.Widget logoBox() => logo != null
        ? pw.ClipRRect(
            horizontalRadius: 12,
            verticalRadius: 12,
            child: pw.Image(logo, width: 58, height: 58, fit: pw.BoxFit.cover),
          )
        : pw.Container(
            width: 58,
            height: 58,
            alignment: pw.Alignment.center,
            decoration: pw.BoxDecoration(
              color: teal,
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Text(
              Formatters.initials(supplierName),
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          );

    pw.Widget label(String text) => pw.Text(
      text.toUpperCase(),
      style: pw.TextStyle(
        color: grey,
        fontSize: 8.5,
        letterSpacing: 1.2,
        fontWeight: pw.FontWeight.bold,
      ),
    );

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (_) => [
          // Header: supplier logo + tag on the left, invoice on the right
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              logoBox(),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: pw.BoxDecoration(
                        color: teal,
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                      child: pw.Text(
                        'SUPPLIER',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 8,
                          letterSpacing: 1.2,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      supplierName,
                      style: pw.TextStyle(
                        fontSize: 17,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    if ((supplier?.address ?? '').isNotEmpty)
                      pw.Text(
                        supplier!.address,
                        style: const pw.TextStyle(color: grey, fontSize: 9.5),
                      ),
                    if ((supplier?.phone ?? '').isNotEmpty)
                      pw.Text(
                        supplier!.phone,
                        style: const pw.TextStyle(color: grey, fontSize: 9.5),
                      ),
                  ],
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'INVOICE',
                    style: pw.TextStyle(
                      color: dark,
                      fontSize: 26,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(number, style: const pw.TextStyle(fontSize: 10)),
                  pw.Text(
                    Formatters.date(order.createdAt),
                    style: const pw.TextStyle(color: grey, fontSize: 10),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: pw.BoxDecoration(
                      color: const PdfColor.fromInt(0xFFE3F5EA),
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Text(
                      order.isDelivered ? 'DELIVERED' : 'APPROVED',
                      style: pw.TextStyle(
                        color: const PdfColor.fromInt(0xFF2E9E5B),
                        fontSize: 8.5,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 14),
          pw.Container(height: 2, color: teal),
          pw.SizedBox(height: 16),

          // Parties
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    label('Bill to'),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      billTo.name,
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    if (billTo.organization.isNotEmpty)
                      pw.Text(billTo.organization),
                    if (billTo.phone.isNotEmpty) pw.Text(billTo.phone),
                    if (billTo.address.isNotEmpty) pw.Text(billTo.address),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    label('Order'),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      '#${order.id}',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text('Placed ${Formatters.dateTime(order.createdAt)}'),
                    if (order.deliveredAt != null)
                      pw.Text(
                        'Delivered ${Formatters.dateTime(order.deliveredAt!)}',
                      ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 18),

          // Items
          pw.TableHelper.fromTextArray(
            headers: ['#', 'Item', 'Unit', 'Rate', 'Qty', 'Amount'],
            data: [
              for (var i = 0; i < order.items.length; i++)
                [
                  '${i + 1}',
                  order.items[i].name,
                  order.items[i].unit,
                  Formatters.money(order.items[i].price),
                  '${order.items[i].qty}',
                  Formatters.money(order.items[i].subtotal),
                ],
            ],
            headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
              fontSize: 10,
            ),
            headerDecoration: const pw.BoxDecoration(color: teal),
            cellStyle: const pw.TextStyle(fontSize: 10),
            oddRowDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFF3F8F8),
            ),
            cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 6,
            ),
            cellAlignments: {
              0: pw.Alignment.center,
              3: pw.Alignment.centerRight,
              4: pw.Alignment.center,
              5: pw.Alignment.centerRight,
            },
            columnWidths: {
              0: const pw.FixedColumnWidth(26),
              1: const pw.FlexColumnWidth(3.2),
              2: const pw.FlexColumnWidth(1.4),
              3: const pw.FlexColumnWidth(1.4),
              4: const pw.FixedColumnWidth(36),
              5: const pw.FlexColumnWidth(1.5),
            },
          ),
          pw.SizedBox(height: 12),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
              decoration: pw.BoxDecoration(
                color: teal,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Text(
                'Total  ${Formatters.money(order.total)}',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ),
          if (order.notes.isNotEmpty) ...[
            pw.SizedBox(height: 14),
            label('Notes'),
            pw.SizedBox(height: 3),
            pw.Text(order.notes),
          ],

          // Signature block
          pw.SizedBox(height: 40),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Thank you for your order.',
                style: const pw.TextStyle(color: grey, fontSize: 10),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  if (signature != null)
                    pw.Image(signature, height: 52, fit: pw.BoxFit.contain)
                  else
                    pw.Text(
                      supplierName,
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontStyle: pw.FontStyle.italic,
                        color: dark,
                      ),
                    ),
                  pw.Container(width: 170, height: 1, color: PdfColors.grey600),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    'Authorized signature',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    supplierName,
                    style: const pw.TextStyle(color: grey, fontSize: 9),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
    return doc.save();
  }

  Future<Uint8List> build(
    AppUser billTo,
    List<InvoiceLine> lines,
    DateTime date, {
    String? invoiceNumber,
  }) {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (_) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'INVOICE',
                style: pw.TextStyle(
                  fontSize: 26,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(invoiceNumber ?? number(date)),
                  pw.Text(Formatters.date(date)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 18),
          pw.Text(
            'Bill to',
            style: const pw.TextStyle(color: PdfColors.grey700),
          ),
          pw.Text(
            billTo.name,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          if (billTo.organization.isNotEmpty) pw.Text(billTo.organization),
          if (billTo.phone.isNotEmpty) pw.Text(billTo.phone),
          pw.SizedBox(height: 18),
          pw.TableHelper.fromTextArray(
            headers: ['Item', 'Supplier', 'Unit', 'Rate', 'Qty', 'Amount'],
            data: [
              for (final l in lines)
                [
                  l.product.name,
                  l.product.supplierName,
                  l.product.unit,
                  Formatters.money(l.product.price),
                  '${l.qty}',
                  Formatters.money(l.subtotal),
                ],
            ],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
            cellAlignments: {
              3: pw.Alignment.centerRight,
              4: pw.Alignment.centerRight,
              5: pw.Alignment.centerRight,
            },
          ),
          pw.SizedBox(height: 12),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Total: ${Formatters.money(total(lines))}',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    return doc.save();
  }
}
