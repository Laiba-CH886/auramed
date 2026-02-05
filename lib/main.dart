import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Theme & Provider
import 'package:auramed/theme.dart';
import 'package:auramed/providers/auth_provider.dart';

// Screens
import 'package:auramed/screens/splash_screen.dart';
import 'package:auramed/screens/role_selection_screen.dart';

// Patient Screens
import 'package:auramed/screens/patient_login_screen.dart';
import 'package:auramed/screens/patient_signup_screen.dart';
import 'package:auramed/screens/patient_dashboard.dart';

// Doctor Screens
import 'package:auramed/screens/doctor_login_screen.dart';
import 'package:auramed/screens/doctor_signup_screen.dart';
import 'package:auramed/screens/doctor_dashboard.dart';

// Common Screens
import 'package:auramed/screens/patient_detail_screen.dart';
import 'package:auramed/screens/profile_screen.dart';

// Settings & Info Screens
import 'package:auramed/screens/app_setting_screen.dart';
import 'package:auramed/screens/privacy_and_security_screen.dart';
import 'package:auramed/screens/notifications_screen.dart';
import 'package:auramed/screens/appearance_screen.dart';
import 'package:auramed/screens/Help_and_FAQ_Screen.dart';
import 'package:auramed/screens/contact_support_screen.dart';
import 'package:auramed/screens/about_auramed_screen.dart';

// ------------------------------
// MAIN APP WIDGET
// ------------------------------
void main() {
  runApp(const AuraMedApp());
}

class AuraMedApp extends StatelessWidget {
  const AuraMedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return MaterialApp(
            title: 'AuraMed',
            debugShowCheckedModeBanner: false,
            theme: buildAuraTheme(),
            initialRoute: SplashScreen.routeName,

            // ============================
            //         ALL ROUTES
            // ============================
            routes: {
              // --------------------------
              // Splash + Role
              // --------------------------
              SplashScreen.routeName: (_) => const SplashScreen(),
              RoleSelectionScreen.routeName: (_) =>
              const RoleSelectionScreen(),

              // --------------------------
              // Patient Authentication
              // --------------------------
              PatientLoginScreen.routeName: (_) =>
              const PatientLoginScreen(),
              PatientSignupScreen.routeName: (_) =>
              const PatientSignupScreen(),
              PatientDashboard.routeName: (_) =>
              const PatientDashboard(),

              // --------------------------
              // Doctor Authentication
              // --------------------------
              DoctorLoginScreen.routeName: (_) =>
              const DoctorLoginScreen(),
              DoctorSignupScreen.routeName: (_) =>
              const DoctorSignupScreen(),
              DoctorDashboard.routeName: (_) =>
              const DoctorDashboard(),

              // --------------------------
              // Common Screens
              // --------------------------
              PatientDetailScreen.routeName: (_) =>
              const PatientDetailScreen(),
              ProfileScreen.routeName: (_) => const ProfileScreen(),

              // --------------------------
              // Settings / Support / About
              // --------------------------
              AppSettingsScreen.routeName: (_) =>
              const AppSettingsScreen(),
              PrivacySecurityScreen.routeName: (_) =>
              const PrivacySecurityScreen(),
              NotificationsScreen.routeName: (_) =>
              const NotificationsScreen(),
              AppearanceScreen.routeName: (_) =>
              const AppearanceScreen(),
              HelpFaqScreen.routeName: (_) =>
              const HelpFaqScreen(),
              ContactSupportScreen.routeName: (_) =>
              const ContactSupportScreen(),
              AboutAuraMedScreen.routeName: (_) =>
              const AboutAuraMedScreen(),
            },
          );
        },
      ),
    );
  }
}
