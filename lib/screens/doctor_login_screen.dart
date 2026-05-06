import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auramed/providers/auth_provider.dart';
import 'package:auramed/screens/doctor_dashboard.dart';
import 'package:auramed/screens/doctor_signup_screen.dart';

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

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );

    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) _animController.forward();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  // ───────── LOGIN ─────────
  Future<void> _loginWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final result = await auth.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      final user = auth.user;

      if (user?.isBlocked == true) {
        await auth.logout();
        _showError("Blocked by admin.");
      } else if (user?.isApproved == false) {
        await auth.logout();
        _showError("Waiting for approval.");
      } else if (user?.role.name == 'doctor') {
        Navigator.pushReplacementNamed(
          context,
          DoctorDashboard.routeName,
        );
      } else {
        await auth.logout();
        _showError("Not a doctor account.");
      }
    } else {
      _showError(result['message'] ?? 'Login failed');
    }

    setState(() => _isLoading = false);
  }

  // ───────── GOOGLE LOGIN ─────────
  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final result = await auth.signInWithGoogle(role: 'doctor');

    if (!mounted) return;

    if (result['success'] == true) {
      final user = auth.user;

      if (user?.isBlocked == true) {
        await auth.logout();
        _showError("Blocked account.");
      } else if (user?.isApproved == false) {
        await auth.logout();
        _showError("Approval pending.");
      } else if (user?.role.name == 'doctor') {
        Navigator.pushReplacementNamed(
          context,
          DoctorDashboard.routeName,
        );
      } else {
        await auth.logout();
        _showError("Invalid account.");
      }
    } else {
      _showError(result['message'] ?? 'Google login failed');
    }

    setState(() => _isLoading = false);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  // ───────── UI ─────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  Image.asset('assets/images/logo.png', height: 70),
                  const SizedBox(height: 20),
                  const Text(
                    "Doctor Login",
                    style:
                    TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 30),

                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _emailController,
                          validator: (v) =>
                          v!.isEmpty ? "Email required" : null,
                          decoration:
                          const InputDecoration(labelText: "Email"),
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          validator: (v) =>
                          v!.isEmpty ? "Password required" : null,
                          decoration: InputDecoration(
                            labelText: "Password",
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        ElevatedButton(
                          onPressed: _isLoading ? null : _loginWithEmail,
                          child: _isLoading
                              ? const CircularProgressIndicator()
                              : const Text("Login"),
                        ),

                        const SizedBox(height: 10),

                        ElevatedButton(
                          onPressed: _loginWithGoogle,
                          child: const Text("Login with Google"),
                        ),

                        const SizedBox(height: 20),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Don't have an account?"),
                            TextButton(
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  DoctorSignupScreen.routeName,
                                );
                              },
                              child: const Text(
                                "Sign Up",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
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
      ),
    );
  }
}