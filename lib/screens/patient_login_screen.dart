import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auramed/providers/auth_provider.dart';
import 'package:auramed/screens/patient_dashboard.dart';

class PatientLoginScreen extends StatefulWidget {
  static const String routeName = '/patient-login';
  const PatientLoginScreen({super.key});

  @override
  State<PatientLoginScreen> createState() => _PatientLoginScreenState();
}

class _PatientLoginScreenState extends State<PatientLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Email Login ───────────────────────────────────────────────────────────
  Future<void> _loginWithEmail() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);

    try {
      // ✅ Use AuthProvider.login — syncs Firebase + Firestore user into provider
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final result = await auth.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        final role = result['role'] as String? ?? '';
        if (role == 'patient') {
          Navigator.pushReplacementNamed(context, PatientDashboard.routeName);
        } else {
          // Doctor trying to login as patient
          await auth.logout();
          _showError(
              'This account is registered as a doctor. Please use the Doctor login.');
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

  // ── Google Login ──────────────────────────────────────────────────────────
  Future<void> _loginWithGoogle() async {
    setState(() => _isGoogleLoading = true);

    try {
      // ✅ Use AuthProvider.signInWithGoogle — syncs user into provider
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final result = await auth.signInWithGoogle(role: 'patient');

      if (!mounted) return;

      if (result['success'] == true) {
        final role = result['role'] as String? ?? '';
        if (role == 'patient') {
          Navigator.pushReplacementNamed(context, PatientDashboard.routeName);
        } else {
          await auth.logout();
          _showError('This Google account is registered as a doctor. Please use Doctor login.');
        }
      } else {
        final message = result['message'] as String? ?? 'Google sign-in failed.';
        if (message != 'Sign in canceled') _showError(message);
      }
    } catch (e) {
      if (!mounted) return;
      _showError('Google sign-in failed: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  // ── Forgot Password ───────────────────────────────────────────────────────
  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showError('Please enter your email address first.');
      return;
    }

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      // AuthProvider exposes firebaseUser — use AuthService directly via provider
      await auth.sendPasswordReset(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Password reset email sent! Check your inbox.'),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      if (!mounted) return;
      _showError('Failed to send reset email. Please check the email address.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
      duration: const Duration(seconds: 4),
    ));
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              Image.asset(
                'assets/images/logo.png',
                height: 60,
                errorBuilder: (_, __, ___) =>
                const Icon(Icons.local_hospital, size: 60, color: Colors.teal),
              ),
              const SizedBox(height: 12),
              const Text(
                'AuraMed - Patient',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal),
              ),
              const Text(
                'Login to continue',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 32),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Welcome Back 👤',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),

              // ── Form Card ───────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.07),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    // Google Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: _isGoogleLoading ? null : _loginWithGoogle,
                        icon: _isGoogleLoading
                            ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                            : SizedBox(
                          width: 22,
                          height: 22,
                          child: CustomPaint(painter: _GoogleLogoPainter()),
                        ),
                        label: const Text(
                          'Continue with Google',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w500),
                        ),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('OR',
                            style: TextStyle(
                                color: Colors.grey, fontSize: 12)),
                      ),
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                    ]),
                    const SizedBox(height: 16),

                    // Email/Password Form
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Email
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty)
                                return 'Email is required';
                              if (!v.contains('@'))
                                return 'Enter a valid email';
                              return null;
                            },
                            decoration:
                            _inputDecoration('Email', Icons.email_outlined),
                          ),
                          const SizedBox(height: 14),

                          // Password
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            validator: (v) {
                              if (v == null || v.isEmpty)
                                return 'Password is required';
                              if (v.length < 6)
                                return 'Password must be at least 6 characters';
                              return null;
                            },
                            decoration: _inputDecoration(
                                'Password', Icons.lock_outline)
                                .copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: Colors.grey,
                                ),
                                onPressed: () => setState(() =>
                                _obscurePassword = !_obscurePassword),
                              ),
                            ),
                          ),

                          // Forgot Password
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _forgotPassword,
                              child: const Text('Forgot Password?',
                                  style:
                                  TextStyle(color: Colors.deepPurple)),
                            ),
                          ),

                          // Login Button
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _loginWithEmail,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white),
                              )
                                  : const Text(
                                'LOGIN',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account? "),
                  GestureDetector(
                    onTap: () =>
                        Navigator.pushNamed(context, '/patient-signup'),
                    child: const Text(
                      'Sign up',
                      style: TextStyle(
                          color: Colors.deepPurple,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: Colors.deepPurple),
      hintText: hint,
      labelText: hint,
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding:
      const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.deepPurple, width: 1.5),
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