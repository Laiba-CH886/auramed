import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

// Theme
import 'package:auramed/theme.dart';

// Providers
import 'package:auramed/providers/auth_provider.dart';
import 'package:auramed/providers/appointment_provider.dart';

// Splash & Role
import 'package:auramed/screens/splash_screen.dart';
import 'package:auramed/screens/role_selection_screen.dart';

// Patient Authentication
import 'package:auramed/screens/patient_login_screen.dart';
import 'package:auramed/screens/patient_signup_screen.dart';
import 'package:auramed/screens/patient_dashboard.dart';

// Doctor Authentication
import 'package:auramed/screens/doctor_login_screen.dart';
import 'package:auramed/screens/doctor_signup_screen.dart';
import 'package:auramed/screens/doctor_dashboard.dart';

// Common Screens
import 'package:auramed/screens/patient_detail_screen.dart';
import 'package:auramed/screens/profile_screen.dart';
import 'package:auramed/screens/edit_profile_screen.dart';

// Settings / Info Screens
import 'package:auramed/screens/app_setting_screen.dart';
import 'package:auramed/screens/privacy_and_security_screen.dart';
import 'package:auramed/screens/notifications_screen.dart';
import 'package:auramed/screens/Appearance_screen.dart';
import 'package:auramed/screens/Help_and_FAQ_Screen.dart';
import 'package:auramed/screens/contact_support_screen.dart';
import 'package:auramed/screens/about_AuraMed_screen.dart';
import 'package:auramed/screens/health_tips_screen.dart';

// --------------------------
// Appointment Screens
// --------------------------
import 'package:auramed/screens/appointments/appointments_list_screen.dart';
import 'package:auramed/screens/appointments/appointment_detail_screen.dart';
import 'package:auramed/screens/appointments/book_appointment_screen.dart';
import 'package:auramed/screens/appointments/doctor_appointment_action_screen.dart';

// --------------------------
// Consultation Screens
// --------------------------
import 'package:auramed/screens/consultation/consultation_list_screen.dart';
import 'package:auramed/screens/consultation/consultation_chat_screen.dart';
import 'package:auramed/screens/consultation/doctor_notes_screen.dart';

// --------------------------
// Readings Screens
// --------------------------
import 'package:auramed/screens/readings/add_manual_reading_screen.dart';
import 'package:auramed/screens/readings/reading_detail_screen.dart';
import 'package:auramed/screens/readings/readings_history_screen.dart';
import 'package:auramed/screens/connect_device_screen.dart';



// ==============================
// MAIN FUNCTION
// ==============================
void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase
    await Firebase.initializeApp();
    debugPrint('✅ Firebase initialized successfully!');
  } catch (e) {
    debugPrint('❌ Firebase initialization error: $e');
  }

  runApp(const AuraMedApp());
}


// ==============================
// MAIN APP
// ==============================
class AuraMedApp extends StatelessWidget {
  const AuraMedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(),
        ),
        ChangeNotifierProvider<AppointmentProvider>(
          create: (_) => AppointmentProvider(),
        ),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return MaterialApp(
            title: 'AuraMed',
            debugShowCheckedModeBanner: false,
            theme: buildAuraTheme(),
            initialRoute: SplashScreen.routeName,

            // ==========================
            //         ALL ROUTES
            // ==========================
            routes: {

              // --------------------------
              // Splash & Role
              // --------------------------
              SplashScreen.routeName: (_) =>
              const SplashScreen(),
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
              ProfileScreen.routeName: (_) =>
              const ProfileScreen(),
              EditProfileScreen.routeName: (_) =>
              const EditProfileScreen(),

              // --------------------------
              // Appointment Screens
              // --------------------------
              AppointmentsListScreen.routeName: (_) =>
              const AppointmentsListScreen(),
              AppointmentDetailScreen.routeName: (_) =>
              const AppointmentDetailScreen(),
              BookAppointmentScreen.routeName: (_) =>
              const BookAppointmentScreen(),
              DoctorAppointmentActionScreen.routeName: (_) =>
              const DoctorAppointmentActionScreen(),

              // --------------------------
              // Consultation Screens
              // --------------------------
              ConsultationListScreen.routeName: (_) =>
              const ConsultationListScreen(),
              ConsultationChatScreen.routeName: (_) =>
              const ConsultationChatScreen(),
              DoctorNotesScreen.routeName: (_) =>
              const DoctorNotesScreen(),

              // --------------------------
              // Readings Screens
              // --------------------------
              AddManualReadingScreen.routeName: (_) =>
              const AddManualReadingScreen(),
              ReadingDetailScreen.routeName: (_) =>
              const ReadingDetailScreen(),
              ReadingsHistoryScreen.routeName: (_) =>
              const ReadingsHistoryScreen(),

              // --------------------------
              // Settings / Support / Info
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
              HealthTipsScreen.routeName: (_) =>
              const HealthTipsScreen(),
              '/connect-device': (context) => const ConnectDeviceScreen(),
            },
          );
        },
      ),
    );
  }
}
