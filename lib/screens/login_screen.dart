// dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auramed/models/user.dart';
import 'package:auramed/providers/auth_provider.dart';
import 'package:auramed/screens/signup_screen.dart';
import 'package:auramed/screens/patient_dashboard.dart';
import 'package:auramed/screens/doctor_dashboard.dart';
import 'package:auramed/widgets/rounded_button.dart';

class LoginScreen extends StatefulWidget {
  static const routeName = '/login';
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String password = '';
  bool loading = false;

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => loading = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final ok = await auth.login(email.trim(), password);

    setState(() => loading = false);
    if (!mounted) return;

    if (ok) {
      if (auth.user?.role == UserRole.doctor) {
        Navigator.pushReplacementNamed(context, DoctorDashboard.routeName);
      } else {
        Navigator.pushReplacementNamed(context, PatientDashboard.routeName);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ---------- Logo and App Name ----------
              Column(
                children: [
                  Image.asset(
                    'assets/images/logo.png', // Make sure this path is correct
                    width: 100,
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'AuraMed',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.teal.shade700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Patient Monitoring System',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // ---------- Welcome Text ----------
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Welcome Back 👋',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Login to your AuraMed account',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[700],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ---------- Login Form ----------
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (v) => email = v,
                      validator: (v) =>
                      v != null && v.contains('@') ? null : 'Enter a valid email',
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      obscureText: true,
                      onChanged: (v) => password = v,
                      validator: (v) =>
                      v != null && v.length >= 6 ? null : 'Minimum 6 characters',
                    ),
                    const SizedBox(height: 24),

                    // ---------- Login Button ----------
                    loading
                        ? const CircularProgressIndicator()
                        : RoundedButton(
                      text: 'Login',
                      onTap: _submit,
                    ),

                    const SizedBox(height: 16),

                    // ---------- Signup Link ----------
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account?"),
                        TextButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, SignupScreen.routeName),
                          child: const Text(
                            'Create one',
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
    );
  }
}
