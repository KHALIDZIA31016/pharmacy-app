import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/app_user.dart';
import '../../data/models/order.dart';
import '../../data/repositories/user_repository.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../widgets/app_button.dart';
import 'order_invoice.dart';

/// On-screen invoice. Visible right after the order is placed, but the PDF
/// can only be downloaded / printed once the supplier has approved the order.
class InvoicePreviewScreen extends StatefulWidget {
  final Order order;
  final bool asSupplier;

  const InvoicePreviewScreen({
    super.key,
    required this.order,
    this.asSupplier = false,
  });

  @override
  State<InvoicePreviewScreen> createState() => _InvoicePreviewScreenState();
}

class _Parties {
  final AppUser? supplier;
  final AppUser billTo;
  const _Parties(this.supplier, this.billTo);
}

class _InvoicePreviewScreenState extends State<InvoicePreviewScreen> {
  late final Future<_Parties> _future = _load();

  Future<_Parties> _load() async {
    final users = context.read<UserRepository>();
    final me = context.read<AuthViewModel>().user;
    final supplier = await users.getById(widget.order.supplierId);
    final AppUser billTo;
    if (widget.asSupplier) {
      billTo =
          await users.getById(widget.order.userId) ??
          AppUser(
            uid: widget.order.userId,
            name: widget.order.userName,
            email: '',
            createdAt: DateTime.now(),
          );
    } else {
      billTo = me!;
    }
    return _Parties(supplier, billTo);
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final approved = order.isApproved;

    return Scaffold(
      body: Column(
        children: [
          _Header(order: order),
          Expanded(
            child: FutureBuilder<_Parties>(
              future: _future,
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final parties = snap.data!;
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                  children: [
                    _StatusBanner(order: order),
                    const SizedBox(height: 16),
                    _Paper(order: order, parties: parties),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: FutureBuilder<_Parties>(
        future: _future,
        builder: (context, snap) {
          final billTo = snap.data?.billTo;
          return Container(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              12 + MediaQuery.of(context).padding.bottom,
            ),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!approved)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.lock_outline_rounded,
                          size: 16,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Download and print unlock after ${order.supplierName} approves.',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: approved ? 'Download' : 'Locked',
                        icon: approved
                            ? Icons.download_rounded
                            : Icons.lock_outline_rounded,
                        onPressed: approved && billTo != null
                            ? () => showOrderInvoice(context, order, billTo)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AppButton(
                        label: 'Print',
                        icon: Icons.print_outlined,
                        outlined: true,
                        onPressed: approved && billTo != null
                            ? () => showOrderInvoice(
                                context,
                                order,
                                billTo,
                                share: false,
                              )
                            : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final Order order;
  const _Header({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        8,
        MediaQuery.of(context).padding.top + 4,
        20,
        20,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -8,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.13),
                  width: 14,
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'INVOICE',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11.5,
                              letterSpacing: 1.8,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'INV-${order.id.toString().padLeft(5, '0')}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              letterSpacing: -0.3,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            order.isApproved
                                ? Icons.verified_rounded
                                : Icons.hourglass_top_rounded,
                            size: 15,
                            color: order.isApproved
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            order.isApproved ? 'Approved' : 'Pending',
                            style: TextStyle(
                              color: order.isApproved
                                  ? AppColors.success
                                  : AppColors.warning,
                              fontWeight: FontWeight.w800,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final Order order;
  const _StatusBanner({required this.order});

  @override
  Widget build(BuildContext context) {
    final cancelled = order.status == 'cancelled';
    final color = cancelled
        ? AppColors.danger
        : (order.isApproved ? AppColors.success : AppColors.warning);
    final icon = cancelled
        ? Icons.cancel_outlined
        : (order.isApproved
              ? Icons.verified_rounded
              : Icons.hourglass_top_rounded);
    final text = cancelled
        ? 'This order was cancelled, so there is no invoice to download.'
        : (order.isApproved
              ? '${order.supplierName} approved this order. Your invoice is ready to download or print.'
              : 'Waiting for ${order.supplierName} to approve. You can preview the invoice now; download and print unlock after approval.');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

/// The invoice "paper".
class _Paper extends StatelessWidget {
  final Order order;
  final _Parties parties;
  const _Paper({required this.order, required this.parties});

  @override
  Widget build(BuildContext context) {
    final supplier = parties.supplier;
    final name = supplier?.name ?? order.supplierName;

    final paper = Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Supplier logo + tag
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Logo(supplier: supplier, fallbackName: name),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: const Text(
                        'SUPPLIER',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                    if ((supplier?.address ?? '').isNotEmpty)
                      Text(
                        supplier!.address,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    if ((supplier?.phone ?? '').isNotEmpty)
                      Text(
                        supplier!.phone,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(height: 3, color: AppColors.primary),
          const SizedBox(height: 14),

          // Parties
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Info('Bill to', parties.billTo.name, [
                  if (parties.billTo.organization.isNotEmpty)
                    parties.billTo.organization,
                  if (parties.billTo.phone.isNotEmpty) parties.billTo.phone,
                ]),
              ),
              Expanded(
                child: _Info(
                  'Order #${order.id}',
                  Formatters.date(order.createdAt),
                  [
                    if (order.deliveredAt != null)
                      'Delivered ${Formatters.date(order.deliveredAt!)}',
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Items
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Expanded(flex: 5, child: Text('ITEM', style: _th)),
                Expanded(
                  flex: 2,
                  child: Text('QTY', textAlign: TextAlign.center, style: _th),
                ),
                Expanded(
                  flex: 3,
                  child: Text('AMOUNT', textAlign: TextAlign.right, style: _th),
                ),
              ],
            ),
          ),
          for (var i = 0; i < order.items.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              color: i.isOdd ? const Color(0xFFF3F8F8) : null,
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.items[i].name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '${Formatters.money(order.items[i].price)} · ${order.items[i].unit}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${order.items[i].qty}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      Formatters.money(order.items[i].subtotal),
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Total  ${Formatters.money(order.total)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          if (order.notes.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'NOTES',
              style: TextStyle(
                color: AppColors.textSecondary.withValues(alpha: 0.9),
                fontSize: 10.5,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(order.notes),
          ],
          const SizedBox(height: 26),

          // Signature
          Align(
            alignment: Alignment.centerRight,
            child: _Signature(order: order, supplier: supplier, name: name),
          ),
        ],
      ),
    );

    // "Pending" watermark until approval
    if (order.isApproved) return paper;
    return Stack(
      children: [
        paper,
        Positioned.fill(
          child: IgnorePointer(
            child: Center(
              child: Transform.rotate(
                angle: -0.45,
                child: Text(
                  'PENDING APPROVAL',
                  style: TextStyle(
                    fontSize: 34,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w900,
                    color: AppColors.warning.withValues(alpha: 0.16),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

const _th = TextStyle(
  color: Colors.white,
  fontSize: 10.5,
  letterSpacing: 1,
  fontWeight: FontWeight.w800,
);

class _Info extends StatelessWidget {
  final String label;
  final String title;
  final List<String> lines;
  const _Info(this.label, this.title, this.lines);

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 10.5,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 3),
      Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      for (final l in lines)
        Text(
          l,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
    ],
  );
}

/// Supplier logo: profile photo, or a monogram tile.
class _Logo extends StatelessWidget {
  final AppUser? supplier;
  final String fallbackName;
  const _Logo({required this.supplier, required this.fallbackName});

  @override
  Widget build(BuildContext context) {
    final path = supplier?.photoPath;
    final hasImage = path != null && path.isNotEmpty && File(path).existsSync();
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: hasImage
          ? Image.file(File(path), width: 60, height: 60, fit: BoxFit.cover)
          : Container(
              width: 60,
              height: 60,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
              ),
              child: Text(
                Formatters.initials(fallbackName),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
    );
  }
}

/// Signature block at the end of the invoice.
class _Signature extends StatelessWidget {
  final Order order;
  final AppUser? supplier;
  final String name;
  const _Signature({
    required this.order,
    required this.supplier,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    final path = supplier?.signaturePath;
    final hasSig = path != null && path.isNotEmpty && File(path).existsSync();

    Widget mark;
    if (!order.isApproved) {
      mark = Container(
        width: 180,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 15, color: AppColors.textSecondary),
            SizedBox(width: 6),
            Text(
              'Signed after approval',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      );
    } else if (hasSig) {
      mark = Image.file(File(path), height: 56, fit: BoxFit.contain);
    } else {
      mark = Text(
        name,
        style: const TextStyle(
          fontSize: 24,
          fontStyle: FontStyle.italic,
          color: AppColors.primaryDark,
        ),
      );
    }

    return Column(
      children: [
        mark,
        Container(width: 180, height: 1, color: AppColors.textSecondary),
        const SizedBox(height: 4),
        const Text(
          'Authorized signature',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
        ),
        Text(
          name,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11.5,
          ),
        ),
      ],
    );
  }
}
