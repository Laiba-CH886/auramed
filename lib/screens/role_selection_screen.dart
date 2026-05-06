import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:auramed/screens/patient_login_screen.dart';
import 'package:auramed/screens/doctor_login_screen.dart';

class RoleSelectionScreen extends StatefulWidget {
  static const routeName = "/role_selection";
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pageController =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
    ..forward();

  late final AnimationController _bgController =
  AnimationController(vsync: this, duration: const Duration(seconds: 6))
    ..repeat(reverse: true);

  late final Animation<Alignment> _alignmentAnim = AlignmentTween(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  ).animate(
    CurvedAnimation(parent: _bgController, curve: Curves.easeInOut),
  );

  static const _lottiePath = 'assets/lottie/medical_app.json';
  late final Future<bool> _lottieExistsFuture =
  rootBundle.loadString(_lottiePath).then((_) => true).catchError((_) => false);

  @override
  void dispose() {
    _pageController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // Animated gradient background
          AnimatedBuilder(
            animation: _alignmentAnim,
            builder: (_, __) => Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: _alignmentAnim.value,
                  end: Alignment.center,
                  colors: const [
                    Color(0xFFe6f0ff),
                    Color(0xFFF7F9FF),
                    Color(0xFFF6FFF5),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // Blurred decorative circles
          Positioned(
            top: -mq.size.width * 0.2,
            right: -mq.size.width * 0.25,
            child: _BlurCircle(size: mq.size.width * 0.6),
          ),
          Positioned(
            bottom: -mq.size.width * 0.25,
            left: -mq.size.width * 0.25,
            child: _BlurCircle(
              size: mq.size.width * 0.7,
              color: Colors.greenAccent.withOpacity(0.08),
            ),
          ),

          // Main content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
              child: Column(
                children: [
                  FadeScaleTransition(
                    controller: _pageController,
                    child: Column(
                      children: [
                        // Lottie + Hero image
                        SizedBox(
                          height: 260,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Hero(
                                tag: 'app-hero-image',
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Image.asset(
                                    'assets/images/role-selection.jpg',
                                    fit: BoxFit.contain,
                                    width: mq.size.width * 0.75,
                                  ),
                                ),
                              ),
                              Positioned.fill(
                                child: FutureBuilder<bool>(
                                  future: _lottieExistsFuture,
                                  builder: (_, snap) {
                                    if (!snap.hasData || !snap.data!) {
                                      return const SizedBox();
                                    }
                                    return Opacity(
                                      opacity: 0.95,
                                      child: Lottie.asset(
                                        _lottiePath,
                                        fit: BoxFit.contain,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),
                        Text(
                          "Welcome to AuraMed",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF163a5f).withOpacity(0.95),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Choose your role to continue",
                          style: TextStyle(fontSize: 15, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Role cards
                  FadeScaleTransition(
                    controller: _pageController,
                    delay: 120,
                    child: Column(
                      children: [
                        RoleCard(
                          icon: Icons.person_rounded,
                          title: 'Continue as Patient',
                          subtitle: 'Login to access patient services',
                          gradientColors: const [
                            Color(0xFFDCEBFF),
                            Color(0xFFEAF3FF),
                          ],
                          onTap: () => _fadeTo(const PatientLoginScreen()),
                        ),
                        const SizedBox(height: 18),
                        RoleCard(
                          icon: Icons.medical_services_outlined,
                          title: 'Continue as Doctor',
                          subtitle: 'Manage your patients & appointments',
                          gradientColors: const [
                            Color(0xFFDFF8E6),
                            Color(0xFFEAFEF0)
                          ],
                          onTap: () => _fadeTo(const DoctorLoginScreen()),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Footer
                  FadeScaleTransition(
                    controller: _pageController,
                    delay: 260,
                    child: const Text(
                      'Need help? Contact support@auramed.example',
                      style: TextStyle(fontSize: 12, color: Colors.black45),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _fadeTo(Widget page) {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 700),
        pageBuilder: (_, anim, __) => FadeTransition(opacity: anim, child: page),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Reusable Widgets
// -----------------------------------------------------------------------------

class _BlurCircle extends StatelessWidget {
  final double size;
  final Color color;
  const _BlurCircle({required this.size, this.color = const Color(0xFF7AA7FF)});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(size),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: const SizedBox(),
      ),
    );
  }
}

class RoleCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const RoleCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradientColors,
    required this.onTap,
  });

  @override
  State<RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<RoleCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: widget.gradientColors),
          borderRadius: BorderRadius.circular(18),
          boxShadow: _pressed
              ? [
            const BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ]
              : [
            BoxShadow(
              color: Colors.black12.withOpacity(0.06),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.9),
              blurRadius: 0.5,
              offset: const Offset(-6, -6),
              spreadRadius: -10,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(widget.icon, size: 30, color: Colors.black87),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(widget.subtitle,
                      style: const TextStyle(color: Colors.black54)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_forward_ios, size: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class FadeScaleTransition extends StatelessWidget {
  final Widget child;
  final AnimationController controller;
  final int delay;

  const FadeScaleTransition({
    super.key,
    required this.child,
    required this.controller,
    this.delay = 0,
  });

  @override
  Widget build(BuildContext context) {
    final start = delay / 1000;
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final t = (controller.value - start).clamp(0.0, 1.0);
        final opacity = Curves.easeIn.transform(t);
        final scale = 0.92 + (0.08 * t);

        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 14),
            child: Transform.scale(scale: scale, child: child),
          ),
        );
      },
    );
  }
}