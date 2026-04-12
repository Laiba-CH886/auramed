import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auramed/providers/auth_provider.dart';
import 'package:auramed/screens/doctor_dashboard.dart';

class DoctorSignupScreen extends StatefulWidget {
  static const String routeName = '/doctor-signup';
  const DoctorSignupScreen({super.key});

  @override
  State<DoctorSignupScreen> createState() => _DoctorSignupScreenState();
}

class _DoctorSignupScreenState extends State<DoctorSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _specializationController = TextEditingController();
  final _pmdcController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _specializationController.dispose();
    _pmdcController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Full name is required';
    if (v.trim().length < 2) return 'Name must be at least 2 characters';
    return null;
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return emailRegex.hasMatch(v.trim()) ? null : 'Enter a valid email';
  }

  String? _validateNotEmpty(String? v, String field) {
    if (v == null || v.trim().isEmpty) return '$field is required';
    return null;
  }

  String? _validatePhone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Phone number is required';
    if (v.trim().length < 7) return 'Enter a valid phone number';
    return null;
  }

  String? _validatePmdc(String? v) {
    if (v == null || v.trim().isEmpty) return 'PMDC number is required';
    if (v.trim().length < 4) return 'Enter a valid PMDC number';
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  String? _validateConfirmPassword(String? v) {
    if (v == null || v.isEmpty) return 'Please confirm your password';
    if (v != _passwordController.text) return 'Passwords do not match';
    return null;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);

    try {
      // 1. Firebase Auth
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      final user = credential.user;
      if (user == null) throw Exception('Account creation failed.');

      // 2. Display name
      await user.updateDisplayName(_nameController.text.trim());

      // 3. Firestore doc with role: 'doctor'
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'specialization': _specializationController.text.trim(),
        'pmdcNumber': _pmdcController.text.trim(),
        'role': 'doctor',
        'isVerified': false,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
        'authProvider': 'email',
        'photoUrl': '',
      });

      // 4. ✅ Sync AuthProvider so dashboard shows correct user immediately
      if (!mounted) return;
      await Provider.of<AuthProvider>(context, listen: false)
          .login(_emailController.text.trim(), _passwordController.text);

      // 5. Welcome email (non-fatal)
      _sendWelcomeEmail(
        toEmail: _emailController.text.trim(),
        name: _nameController.text.trim(),
        specialization: _specializationController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Doctor account created successfully! Welcome 🩺'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ));
      Navigator.pushReplacementNamed(context, DoctorDashboard.routeName);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showError(_friendlyError(e));
    } catch (e) {
      if (!mounted) return;
      _showError('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _sendWelcomeEmail({required String toEmail, required String name, required String specialization}) {
    FirebaseFirestore.instance.collection('mail').add({
      'to': [toEmail],
      'message': {
        'subject': '🩺 Welcome to AuraMed, Dr. $name!',
        'html':
        '<h2>Welcome, Dr. $name!</h2><p>Your AuraMed doctor account ($specialization) has been registered. Pending PMDC verification by our team.</p>',
      },
      'createdAt': FieldValue.serverTimestamp(),
    }).catchError((_) {});
  }

  String _friendlyError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'An account already exists with this email. Please login instead.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return e.message ?? 'Signup failed. Please try again.';
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
      duration: const Duration(seconds: 4),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text('Doctor Registration'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
              horizontal: isWide ? width * 0.2 : 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Text('Doctor Registration',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('Register as a verified doctor to access the platform',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600])),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 12, offset: const Offset(0, 4))
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionLabel('Personal Information'),
                      const SizedBox(height: 10),
                      _buildField(controller: _nameController, hint: 'Full Name', icon: Icons.person_outline, validator: _validateName),
                      _buildField(controller: _emailController, hint: 'Email', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress, validator: _validateEmail),
                      _buildField(controller: _phoneController, hint: 'Phone Number', icon: Icons.phone_outlined, keyboardType: TextInputType.phone, validator: _validatePhone),
                      const SizedBox(height: 6),
                      _sectionLabel('Professional Information'),
                      const SizedBox(height: 10),
                      _buildField(controller: _specializationController, hint: 'Specialization (e.g. Cardiologist)', icon: Icons.local_hospital_outlined, validator: (v) => _validateNotEmpty(v, 'Specialization')),
                      _buildField(controller: _pmdcController, hint: 'PMDC Registration Number', icon: Icons.badge_outlined, validator: _validatePmdc),
                      const SizedBox(height: 6),
                      _sectionLabel('Security'),
                      const SizedBox(height: 10),
                      _buildPasswordField(controller: _passwordController, hint: 'Password', obscure: _obscurePassword, onToggle: () => setState(() => _obscurePassword = !_obscurePassword), validator: _validatePassword),
                      _buildPasswordField(controller: _confirmPasswordController, hint: 'Confirm Password', obscure: _obscureConfirm, onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm), validator: _validateConfirmPassword),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: const Text('Register as Doctor',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: Row(children: [
                          Icon(Icons.info_outline, color: Colors.amber.shade800, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Your PMDC number will be verified by our team before full access is granted.',
                              style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
                            ),
                          ),
                        ]),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Already have an account? Login',
                      style: TextStyle(color: Colors.deepPurple)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) => Text(label,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.deepPurple, letterSpacing: 0.5));

  Widget _buildField({required TextEditingController controller, required String hint, required IconData icon, TextInputType keyboardType = TextInputType.text, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.deepPurple),
          hintText: hint,
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.deepPurple, width: 1.5)),
        ),
      ),
    );
  }

  Widget _buildPasswordField({required TextEditingController controller, required String hint, required bool obscure, required VoidCallback onToggle, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        validator: validator,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.lock_outline, color: Colors.deepPurple),
          suffixIcon: IconButton(
            icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.grey),
            onPressed: onToggle,
          ),
          hintText: hint,
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.deepPurple, width: 1.5)),
        ),
      ),
    );
  }
}
