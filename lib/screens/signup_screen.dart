import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auramed/providers/auth_provider.dart';
import 'package:auramed/models/user.dart';
import 'package:auramed/screens/patient_dashboard.dart';
import 'package:auramed/screens/doctor_dashboard.dart';
import 'package:auramed/widgets/rounded_button.dart';

class SignupScreen extends StatefulWidget {
  static const routeName = '/signup';
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  String name = '';
  String email = '';
  String password = '';
  UserRole role = UserRole.patient;
  bool loading = false;

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => loading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final ok = await auth.signup(name.trim(), email.trim(), password, role);
    
    if (!mounted) return;
    setState(() => loading = false);

    if (ok) {
      if (role == UserRole.doctor) {
        Navigator.pushReplacementNamed(context, DoctorDashboard.routeName);
      } else {
        Navigator.pushReplacementNamed(context, PatientDashboard.routeName);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Signup failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 22),
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              IconButton(
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back),
              ),
              const SizedBox(height: 8),
              Text('Create Account', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('Join AuraMed — choose patient or doctor account', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 20),
              Form(
                key: _formKey,
                child: Column(children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Full name'),
                    onChanged: (v) => name = v,
                    validator: (v) => v != null && v.isNotEmpty ? null : 'Enter full name',
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Email'),
                    onChanged: (v) => email = v,
                    validator: (v) => v != null && v.contains('@') ? null : 'Enter valid email',
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    onChanged: (v) => password = v,
                    validator: (v) => v != null && v.length >= 6 ? null : 'At least 6 chars',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<UserRole>(
                          title: const Text('Patient'),
                          value: UserRole.patient,
                          groupValue: role,
                          onChanged: (v) => setState(() => role = v!),
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<UserRole>(
                          title: const Text('Doctor'),
                          value: UserRole.doctor,
                          groupValue: role,
                          onChanged: (v) => setState(() => role = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  loading ? const CircularProgressIndicator() : RoundedButton(text: 'Sign up', onTap: _submit),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
