// dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auramed/providers/auth_provider.dart';
import 'package:auramed/models/user.dart';
import 'package:auramed/widgets/rounded_button.dart';
import 'package:auramed/screens/doctor_signup_screen.dart';
import 'package:auramed/screens/doctor_dashboard.dart';

class DoctorLoginScreen extends StatefulWidget {
  static const routeName = "/doctor_login_screen";
  const DoctorLoginScreen({super.key});

  @override
  State<DoctorLoginScreen> createState() => _DoctorLoginScreenState();
}

class _DoctorLoginScreenState extends State<DoctorLoginScreen>
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

    _animController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 700));

    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

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

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);

      final ok = await auth.loginEnhanced(email.trim(), password);

      if (!mounted) return;

      setState(() => loading = false);

      if (ok && auth.user != null && auth.user!.role == UserRole.doctor) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, DoctorDashboard.routeName);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid doctor login credentials. Use an email containing 'doc' or 'doctor'.")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login error: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          const AnimatedGradientBackground(),

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
              color: Colors.deepPurpleAccent.withAlpha(20),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 6),

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
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    'AuraMed - Doctor',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'Login to continue',
                    style:
                    theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),

                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withAlpha(26),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber),
                    ),
                    child: const Text(
                      '💡 Tip: Use "doctor@test.com" or any email containing "doc"',
                      style: TextStyle(fontSize: 12, color: Colors.amber),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 28),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Welcome Doctor 🩺",
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),

                  const SizedBox(height: 18),

                  FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: _GlassFormCard(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              TextFormField(
                                decoration: InputDecoration(
                                  labelText: "Email",
                                  prefixIcon: const Icon(Icons.email_outlined),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withAlpha(153),
                                  hintText: "doctor@test.com",
                                ),
                                validator: (v) =>
                                v != null && v.contains('@') ? null : "Enter valid email",
                                onChanged: (v) => email = v,
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 14),

                              TextFormField(
                                decoration: InputDecoration(
                                  labelText: "Password",
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withAlpha(153),
                                  hintText: "Enter any password (min 6 chars)",
                                ),
                                obscureText: true,
                                validator: (v) => v != null && v.length >= 6
                                    ? null
                                    : "Minimum 6 characters",
                                onChanged: (v) => password = v,
                              ),
                              const SizedBox(height: 18),

                              SizedBox(
                                width: double.infinity,
                                child: loading
                                    ? const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Center(child: CircularProgressIndicator()),
                                )
                                    : Column(
                                  children: [
                                    RoundedButton(
                                      text: "Login as Doctor",
                                      onTap: _submit,
                                    ),
                                    const SizedBox(height: 8),
                                    TextButton(
                                      onPressed: () {
                                        email = "doctor@test.com";
                                        password = "password123";
                                        _formKey.currentState?.validate();
                                        _submit();
                                      },
                                      child: const Text(
                                        "Auto-fill Test Credentials",
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
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
                                        builder: (context) => const DoctorSignupScreen(),
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

                  FadeTransition(
                    opacity: _fadeAnim,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Need help logging in? Contact support@auramed.example',
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

class AnimatedGradientBackground extends StatefulWidget {
  const AnimatedGradientBackground({super.key});

  @override
  State<AnimatedGradientBackground> createState() =>
      _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
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
                Colors.deepPurple.shade50.withAlpha(230),
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

class _DecorBlur extends StatelessWidget {
  final double size;
  final Color color;
  const _DecorBlur({required this.size, this.color = const Color(0xFF9B5DFF)});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration:
      BoxDecoration(color: color.withAlpha(30), shape: BoxShape.circle),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: const SizedBox(),
      ),
    );
  }
}

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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(166),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withAlpha(128)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12.withAlpha(10),
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