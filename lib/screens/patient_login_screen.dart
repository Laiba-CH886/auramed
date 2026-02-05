// patient_login_screen.dart
//
// Updated PatientLoginScreen with:
// - animated gradient background
// - Hero animation on the logo (tag: 'app-hero-logo')
// - glassmorphism form card
// - subtle entrance (fade + slide) animation for form
// - keeps your Provider auth logic and navigation
//
// Note: Make sure the RoleSelectionScreen (or whatever screen you navigate from)
// uses the same Hero tag ('app-hero-logo') on the same logo widget so the
// hero animation will run between screens.

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auramed/providers/auth_provider.dart';
import 'package:auramed/models/user.dart';
import 'package:auramed/widgets/rounded_button.dart';
import 'package:auramed/screens/patient_signup_screen.dart';
import 'package:auramed/screens/patient_dashboard.dart';

class PatientLoginScreen extends StatefulWidget {
  static const routeName = "/patient_login_screen";
  const PatientLoginScreen({super.key});

  @override
  State<PatientLoginScreen> createState() => _PatientLoginScreenState();
}

class _PatientLoginScreenState extends State<PatientLoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String password = '';
  bool loading = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    // small delay so the background is visible then form comes in
    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) _animController.forward();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => loading = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final ok = await auth.login(email.trim(), password);

    setState(() => loading = false);
    if (!mounted) return;

    if (ok && auth.user!.role == UserRole.patient) {
      Navigator.pushReplacementNamed(context, PatientDashboard.routeName);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Invalid patient login")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      // keep AppBar hidden for a clean login look
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // animated subtle gradient background
          const AnimatedGradientBackground(),

          // decorative blurred circles for glassmorphism vibe
          Positioned(
            top: -mq.size.width * 0.3,
            right: -mq.size.width * 0.22,
            child: _DecorBlur(size: mq.size.width * 0.55),
          ),
          Positioned(
            bottom: -mq.size.width * 0.28,
            left: -mq.size.width * 0.28,
            child: _DecorBlur(
              size: mq.size.width * 0.72,
              color: Colors.tealAccent.withValues(alpha: 0.08),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // small top spacing
                  const SizedBox(height: 6),

                  // HERO Logo (this must match the role selection's hero tag)
                  Hero(
                    tag: 'app-hero-logo',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        color: Colors.white,
                        padding: const EdgeInsets.all(6),
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 92,
                          height: 92,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    'AuraMed - Patient',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.teal.shade700,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'Login to continue',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Welcome text
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Welcome Patient 👤",
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Animated card (glassmorphism) containing the form
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: _GlassFormCard(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              // Email
                              TextFormField(
                                decoration: InputDecoration(
                                  labelText: "Email",
                                  prefixIcon: const Icon(Icons.email_outlined),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withValues(alpha: 0.6),
                                ),
                                validator: (v) => v != null && v.contains('@')
                                    ? null
                                    : "Enter valid email",
                                onChanged: (v) => email = v,
                                keyboardType: TextInputType.emailAddress,
                              ),

                              const SizedBox(height: 14),

                              // Password
                              TextFormField(
                                decoration: InputDecoration(
                                  labelText: "Password",
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withValues(alpha: 0.6),
                                ),
                                obscureText: true,
                                validator: (v) => v != null && v.length >= 6
                                    ? null
                                    : "Minimum 6 characters",
                                onChanged: (v) => password = v,
                              ),

                              const SizedBox(height: 18),

                              // login button or loader
                              SizedBox(
                                width: double.infinity,
                                child: loading
                                    ? const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                                    : RoundedButton(
                                  text: "Login",
                                  onTap: _submit,
                                ),
                              ),

                              const SizedBox(height: 12),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text("Don't have an account?"),
                                  TextButton(
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const PatientSignupScreen(),
                                      ),
                                    ),
                                    child: const Text(
                                      "Sign up",
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // small secondary actions / help
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Having trouble signing in? Contact support@auramed.example',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
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
}

/// Animated subtle gradient background widget
class AnimatedGradientBackground extends StatefulWidget {
  const AnimatedGradientBackground({super.key});

  @override
  State<AnimatedGradientBackground> createState() =>
      _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState
    extends State<AnimatedGradientBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Alignment> _alignAnim;

  @override
  void initState() {
    super.initState();
    _controller =
    AnimationController(vsync: this, duration: const Duration(seconds: 8))
      ..repeat(reverse: true);
    _alignAnim = AlignmentTween(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _alignAnim,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: _alignAnim.value,
              end: Alignment.center,
              colors: [
                const Color(0xFFFFFFFF),
                Colors.teal.shade50.withValues(alpha: 0.9),
                const Color(0xFFF7FBFF),
              ],
              stops: const [0.0, 0.6, 1.0],
            ),
          ),
        );
      },
    );
  }
}

/// subtle decorative blurred circle
class _DecorBlur extends StatelessWidget {
  final double size;
  final Color color;
  const _DecorBlur({required this.size, this.color = const Color(0xFF66C2FF)});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration:
      BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: const SizedBox(),
      ),
    );
  }
}

/// Glassmorphism card used to hold the form
class _GlassFormCard extends StatelessWidget {
  final Widget child;
  const _GlassFormCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12.withValues(alpha: 0.04),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
