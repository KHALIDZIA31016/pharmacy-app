import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/ui.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../widgets/app_button.dart';

/// Supplier draws a signature once; it is printed at the end of every invoice.
class SignatureScreen extends StatefulWidget {
  const SignatureScreen({super.key});

  @override
  State<SignatureScreen> createState() => _SignatureScreenState();
}

class _SignatureScreenState extends State<SignatureScreen> {
  static const _padSize = Size(600, 240);

  final List<List<Offset>> _strokes = [];
  final _padKey = GlobalKey();
  bool _saving = false;

  bool get _empty => _strokes.every((s) => s.isEmpty);

  Offset _local(Offset global) {
    final box = _padKey.currentContext!.findRenderObject() as RenderBox;
    return box.globalToLocal(global);
  }

  Future<void> _save() async {
    if (_empty) return;
    setState(() => _saving = true);
    final auth = context.read<AuthViewModel>();

    // Draw the strokes (scaled to the pad) onto a transparent PNG.
    final box = _padKey.currentContext!.findRenderObject() as RenderBox;
    final scale = _padSize.width / box.size.width;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    _SignaturePainter(
      _strokes,
      Colors.black,
      scale: scale,
    ).paint(canvas, _padSize);
    final image = await recorder.endRecording().toImage(
      _padSize.width.round(),
      _padSize.height.round(),
    );
    final data = await image.toByteData(format: ui.ImageByteFormat.png);

    final dir = Directory(
      p.join((await getApplicationDocumentsDirectory()).path, 'signatures'),
    );
    await dir.create(recursive: true);
    final file = File(
      p.join(dir.path, '${DateTime.now().microsecondsSinceEpoch}.png'),
    );
    await file.writeAsBytes(data!.buffer.asUint8List());

    await auth.updateSignature(file.path);
    if (!mounted) return;
    showSnack(context, 'Signature saved');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final saved = auth.user?.signaturePath;
    final hasSaved =
        saved != null && saved.isNotEmpty && File(saved).existsSync();

    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              8,
              MediaQuery.of(context).padding.top + 4,
              20,
              22,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'INVOICE SIGNATURE',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          letterSpacing: 1.8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Sign here once',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'It is printed at the end of every approved invoice.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  key: _padKey,
                  height: 220,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColors.border, width: 1.5),
                  ),
                  child: GestureDetector(
                    onPanStart: (d) => setState(
                      () => _strokes.add([_local(d.globalPosition)]),
                    ),
                    onPanUpdate: (d) => setState(
                      () => _strokes.last.add(_local(d.globalPosition)),
                    ),
                    child: Stack(
                      children: [
                        const Positioned(
                          left: 18,
                          right: 18,
                          bottom: 44,
                          child: Divider(color: AppColors.border),
                        ),
                        if (_empty)
                          const Center(
                            child: Text(
                              'Draw your signature here',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _SignaturePainter(
                              _strokes,
                              AppColors.primaryDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Clear',
                        icon: Icons.refresh_rounded,
                        outlined: true,
                        onPressed: _empty
                            ? null
                            : () => setState(_strokes.clear),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AppButton(
                        label: 'Save signature',
                        icon: Icons.check_rounded,
                        loading: _saving,
                        onPressed: _empty ? null : _save,
                      ),
                    ),
                  ],
                ),
                if (hasSaved) ...[
                  const SizedBox(height: 26),
                  const Text(
                    'CURRENT SIGNATURE',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11.5,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 110,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Image.file(File(saved), fit: BoxFit.contain),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      await auth.updateSignature(null);
                      if (context.mounted) {
                        showSnack(context, 'Signature removed');
                      }
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.danger,
                    ),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Remove signature'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final Color color;
  final double scale;
  _SignaturePainter(this.strokes, this.color, {this.scale = 1});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.2 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    for (final s in strokes) {
      if (s.isEmpty) continue;
      if (s.length == 1) {
        canvas.drawCircle(
          s.first * scale,
          1.6 * scale,
          paint..style = PaintingStyle.fill,
        );
        paint.style = PaintingStyle.stroke;
        continue;
      }
      final path = Path()..moveTo(s.first.dx * scale, s.first.dy * scale);
      for (final o in s.skip(1)) {
        path.lineTo(o.dx * scale, o.dy * scale);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter old) => true;
}
