import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auramed/providers/auth_provider.dart';
import 'package:auramed/screens/doctor_dashboard.dart';
import 'package:auramed/screens/doctor_signup_screen.dart';
import 'package:auramed/widgets/rounded_button.dart';

class DoctorLoginScreen extends StatefulWidget {
  static const routeName = "/doctor_login_screen";
  const DoctorLoginScreen({super.key});

  @override
  State<DoctorLoginScreen> createState() => _DoctorLoginScreenState();
}

class _DoctorLoginScreenState extends State<DoctorLoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

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
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(
            CurvedAnimation(
                parent: _animController, curve: Curves.easeOut));
    Future.delayed(
        const Duration(milliseconds: 120),
            () { if (mounted) _animController.forward(); });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  // ── Email Login ───────────────────────────────────────────────────────────
  Future<void> _loginWithEmail() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      // ✅ AuthProvider.login — syncs Firebase + Firestore user into provider
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final result = await auth.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        final role = result['role'] as String? ?? '';
        if (role == 'doctor') {
          Navigator.pushReplacementNamed(context, DoctorDashboard.routeName);
        } else {
          // Patient trying to log in as doctor
          await auth.logout();
          _showError(
              'This account is registered as a patient. Please use Patient login.');
        }
      } else {
        _showError(result['message'] as String? ?? 'Login failed. Please try again.');
      }
    } catch (e) {
      if (!mounted) return;
      _showError('An unexpected error occurred: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Google Sign-In ────────────────────────────────────────────────────────
  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      // ✅ AuthProvider.signInWithGoogle — syncs user into provider
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final result = await auth.signInWithGoogle(role: 'doctor');

      if (!mounted) return;

      if (result['success'] == true) {
        final role = result['role'] as String? ?? '';
        if (role == 'doctor') {
          _showSuccess(result['isNewUser'] == true
              ? 'Welcome! Your doctor account has been created.'
              : 'Welcome back, Doctor!');
          Navigator.pushReplacementNamed(context, DoctorDashboard.routeName);
        } else {
          await auth.logout();
          _showError(
              'This Google account is registered as a patient. Please use Patient login.');
        }
      } else {
        final msg = result['message'] as String? ?? '';
        if (msg != 'Sign in canceled') _showError(msg);
      }
    } catch (e) {
      if (!mounted) return;
      _showError('Google sign-in failed: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Forgot Password ───────────────────────────────────────────────────────
  Future<void> _forgotPassword() async {
    final emailController =
    TextEditingController(text: _emailController.text.trim());

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                "Enter your registered email and we'll send you a reset link."),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isEmpty || !email.contains('@')) {
                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                  content: Text('Please enter a valid email'),
                  backgroundColor: Colors.red,
                ));
                return;
              }
              Navigator.pop(ctx);
              await _sendPasswordReset(email);
            },
            child: const Text('Send Link',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    emailController.dispose();
  }

  Future<void> _sendPasswordReset(String email) async {
    setState(() => _isLoading = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.sendPasswordReset(email: email);
      if (!mounted) return;
      _showSuccess('Password reset email sent to $email. Check your inbox.');
    } catch (e) {
      if (!mounted) return;
      _showError('Failed to send reset email. Please check the address.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
      duration: const Duration(seconds: 4),
    ));
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.green,
      duration: const Duration(seconds: 3),
    ));
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          const _AnimatedGradientBackground(),
          Positioned(
            top: -mq.size.width * 0.3,
            right: -mq.size.width * 0.22,
            child: _DecorBlur(
                size: mq.size.width * 0.55,
                color: Colors.deepPurpleAccent),
          ),
          Positioned(
            bottom: -mq.size.width * 0.28,
            left: -mq.size.width * 0.28,
            child: _DecorBlur(
              size: mq.size.width * 0.72,
              color: Colors.blueAccent.withValues(alpha: 0.08),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding:
              const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back,
                          color: Colors.black87),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
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
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.local_hospital,
                              size: 92,
                              color: Colors.deepPurple),
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
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: Colors.grey[600]),
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

                  // Animated glass card
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: _GlassFormCard(
                        child: Column(
                          children: [
                            // Google Button
                            SizedBox(
                              height: 56,
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed:
                                _isLoading ? null : _loginWithGoogle,
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(12)),
                                  side: BorderSide(
                                      color: Colors.grey[300]!,
                                      width: 1.5),
                                  backgroundColor:
                                  Colors.white.withValues(alpha: 0.8),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                )
                                    : Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CustomPaint(
                                          painter:
                                          _GoogleLogoPainter()),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Continue with Google',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),
                            Row(children: [
                              Expanded(
                                  child: Divider(
                                      color: Colors.grey[400],
                                      thickness: 0.5)),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16),
                                child: Text('OR',
                                    style: TextStyle(
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12)),
                              ),
                              Expanded(
                                  child: Divider(
                                      color: Colors.grey[400],
                                      thickness: 0.5)),
                            ]),
                            const SizedBox(height: 24),

                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  // Email
                                  TextFormField(
                                    controller: _emailController,
                                    decoration: InputDecoration(
                                      labelText: "Email",
                                      prefixIcon: const Icon(
                                          Icons.email_outlined),
                                      border: OutlineInputBorder(
                                          borderRadius:
                                          BorderRadius.circular(12)),
                                      filled: true,
                                      fillColor: Colors.white
                                          .withValues(alpha: 0.6),
                                    ),
                                    validator: (v) =>
                                    v != null && v.contains('@')
                                        ? null
                                        : "Enter valid email",
                                    keyboardType:
                                    TextInputType.emailAddress,
                                  ),
                                  const SizedBox(height: 14),

                                  // Password
                                  TextFormField(
                                    controller: _passwordController,
                                    decoration: InputDecoration(
                                      labelText: "Password",
                                      prefixIcon: const Icon(
                                          Icons.lock_outline),
                                      suffixIcon: IconButton(
                                        icon: Icon(_obscurePassword
                                            ? Icons.visibility_outlined
                                            : Icons
                                            .visibility_off_outlined),
                                        onPressed: () => setState(() =>
                                        _obscurePassword =
                                        !_obscurePassword),
                                      ),
                                      border: OutlineInputBorder(
                                          borderRadius:
                                          BorderRadius.circular(12)),
                                      filled: true,
                                      fillColor: Colors.white
                                          .withValues(alpha: 0.6),
                                    ),
                                    obscureText: _obscurePassword,
                                    validator: (v) =>
                                    v != null && v.length >= 6
                                        ? null
                                        : "Minimum 6 characters",
                                  ),
                                  const SizedBox(height: 8),

                                  // Forgot Password
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: _forgotPassword,
                                      child: const Text('Forgot Password?'),
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Login Button
                                  SizedBox(
                                    width: double.infinity,
                                    child: _isLoading
                                        ? const Center(
                                        child:
                                        CircularProgressIndicator())
                                        : RoundedButton(
                                      text: "LOGIN",
                                      onTap: _loginWithEmail,
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.center,
                                    children: [
                                      const Text("Don't have an account?"),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pushNamed(
                                                context,
                                                DoctorSignupScreen
                                                    .routeName),
                                        child: const Text("Sign up",
                                            style: TextStyle(
                                                fontWeight:
                                                FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
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
                        'Need help? Contact support@auramed.example',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[600]),
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

// ── Google Logo Painter ───────────────────────────────────────────────────────
class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.85);
    const sw = 6.5;

    void arc(double start, double sweep, Color color) {
      canvas.drawArc(
          rect,
          start,
          sweep,
          false,
          Paint()
            ..color = color
            ..strokeWidth = sw
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.butt);
    }

    arc(-0.26, 1.65, const Color(0xFF4285F4));
    arc(1.39, 0.78, const Color(0xFF34A853));
    arc(2.17, 0.65, const Color(0xFFFBBC05));
    arc(2.82, 1.10, const Color(0xFFEA4335));

    canvas.drawLine(
      Offset(cx - 0.02, cy + r * 0.01),
      Offset(cx + r * 0.82, cy + r * 0.01),
      Paint()
        ..color = const Color(0xFF4285F4)
        ..strokeWidth = sw
        ..strokeCap = StrokeCap.square,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── Animated Gradient Background ─────────────────────────────────────────────
class _AnimatedGradientBackground extends StatefulWidget {
  const _AnimatedGradientBackground();

  @override
  State<_AnimatedGradientBackground> createState() =>
      _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState
    extends State<_AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Alignment> _alignAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(seconds: 8))
      ..repeat(reverse: true);
    _alignAnim =
        AlignmentTween(begin: Alignment.topLeft, end: Alignment.bottomRight)
            .animate(CurvedAnimation(
            parent: _controller, curve: Curves.easeInOut));
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
      builder: (_, __) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: _alignAnim.value,
            end: Alignment.center,
            colors: [
              const Color(0xFFFFFFFF),
              Colors.deepPurple.shade50.withValues(alpha: 0.9),
              const Color(0xFFF7FBFF),
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
      ),
    );
  }
}

// ── Decorative Blur Circle ────────────────────────────────────────────────────
class _DecorBlur extends StatelessWidget {
  final double size;
  final Color color;
  const _DecorBlur(
      {required this.size, this.color = const Color(0xFF9B5DFF)});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: const SizedBox(),
      ),
    );
  }
}

// ── Glass Form Card ───────────────────────────────────────────────────────────
class _GlassFormCard extends StatelessWidget {
  final Widget child;
  const _GlassFormCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
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
    );
  }
}