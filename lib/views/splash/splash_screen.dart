import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/app_user.dart';
import '../../viewmodels/auth_viewmodel.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  /// One-shot entrance: logo pops in, text slides up, accent bar grows.
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..forward();

  /// Endless loop driving the ripples and drifting icons.
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  @override
  void dispose() {
    _intro.dispose();
    _loop.dispose();
    super.dispose();
  }

  Future<void> _boot() async {
    final auth = context.read<AuthViewModel>();
    final results = await Future.wait([
      auth.restoreSession(),
      SharedPreferences.getInstance(),
      Future<void>.delayed(const Duration(milliseconds: 2800)),
    ]);
    if (!mounted) return;
    final user = results[0] as AppUser?;
    final prefs = results[1] as SharedPreferences;
    final seen = prefs.getBool(AppConstants.prefsOnboardingSeen) ?? false;
    final route = user != null
        ? AppRoutes.homeFor(user)
        : (seen ? AppRoutes.login : AppRoutes.onboarding);
    Navigator.pushReplacementNamed(context, route);
  }

  Animation<double> _interval(double a, double b, [Curve c = Curves.easeOut]) =>
      CurvedAnimation(
        parent: _intro,
        curve: Interval(a, b, curve: c),
      );

  @override
  Widget build(BuildContext context) {
    final logo = _interval(0.0, 0.55, Curves.elasticOut);
    final title = _interval(0.35, 0.8);
    final bar = _interval(0.6, 0.95, Curves.easeOutCubic);
    final tagline = _interval(0.7, 1.0);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Drifting faint medical icons
            AnimatedBuilder(
              animation: _loop,
              builder: (_, _) => Stack(
                fit: StackFit.expand,
                children: [
                  for (final f in _floaters)
                    Align(
                      alignment: f.alignment,
                      child: Transform.translate(
                        offset: Offset(
                          0,
                          math.sin(2 * math.pi * (_loop.value + f.phase)) * 12,
                        ),
                        child: Transform.rotate(
                          angle: f.rotation,
                          child: Icon(
                            f.icon,
                            size: f.size,
                            color: Colors.white.withValues(alpha: 0.09),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Expanding radar ripples behind the logo
            Center(
              child: AnimatedBuilder(
                animation: _loop,
                builder: (_, _) => SizedBox(
                  width: 520,
                  height: 520,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      for (var i = 0; i < 3; i++)
                        _ripple((_loop.value * 2.5 + i / 3) % 1),
                    ],
                  ),
                ),
              ),
            ),

            // Center brand block
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ScaleTransition(scale: logo, child: const _Logo()),
                  const SizedBox(height: 34),
                  FadeTransition(
                    opacity: title,
                    child: SlideTransition(
                      position: Tween(
                        begin: const Offset(0, 0.4),
                        end: Offset.zero,
                      ).animate(title),
                      child: const Text(
                        'PHARMACY UNIT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          letterSpacing: 5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  AnimatedBuilder(
                    animation: bar,
                    builder: (_, _) => Container(
                      width: 64 * bar.value,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  FadeTransition(
                    opacity: tagline,
                    child: const Text(
                      'Medical supplies, delivered',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        letterSpacing: 0.6,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Loader + caption at the bottom
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: FadeTransition(
                  opacity: tagline,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 34),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 140,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: const LinearProgressIndicator(
                              minHeight: 4,
                              color: Colors.white,
                              backgroundColor: Colors.white24,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'CLINICS  ·  PHARMACIES  ·  SUPPLIERS',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 10.5,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ripple(double t) {
    final size = 150 + t * 340;
    return Opacity(
      opacity: (1 - t) * 0.28,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 112,
          height: 112,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(34),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 30,
                offset: const Offset(0, 14),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.25),
                blurRadius: 40,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const Icon(
            Icons.medical_services_rounded,
            size: 58,
            color: AppColors.primaryDark,
          ),
        ),
        Positioned(
          right: -8,
          top: -8,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
          ),
        ),
      ],
    );
  }
}

class _Floater {
  final IconData icon;
  final Alignment alignment;
  final double size;
  final double phase;
  final double rotation;
  const _Floater(
    this.icon,
    this.alignment,
    this.size,
    this.phase,
    this.rotation,
  );
}

const _floaters = [
  _Floater(Icons.medication_rounded, Alignment(-0.85, -0.78), 54, 0.0, -0.3),
  _Floater(Icons.vaccines_rounded, Alignment(0.82, -0.62), 60, 0.25, 0.4),
  _Floater(Icons.healing_rounded, Alignment(-0.7, 0.42), 48, 0.5, 0.2),
  _Floater(Icons.water_drop_rounded, Alignment(0.78, 0.5), 44, 0.75, -0.2),
  _Floater(Icons.local_pharmacy_rounded, Alignment(-0.15, -0.92), 40, 0.4, 0.1),
  _Floater(Icons.monitor_heart_rounded, Alignment(0.1, 0.9), 46, 0.9, -0.15),
];
