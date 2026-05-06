import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

// Theme
import 'package:auramed/theme.dart';

// Providers
import 'package:auramed/providers/auth_provider.dart';
import 'package:auramed/providers/appointment_provider.dart';

// Services
import 'package:auramed/services/fcm_service.dart';

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

// 🟣 ADMIN SCREENS (NEW)
import 'package:auramed/screens/admin_login_screen.dart';
import 'package:auramed/screens/admin_dashboard_screen.dart';
import 'package:auramed/screens/pending_doctors_screen.dart';

// Common Screens
import 'package:auramed/screens/patient_detail_screen.dart';
import 'package:auramed/screens/profile_screen.dart';
import 'package:auramed/screens/edit_profile_screen.dart';

// Settings / Info Screens
import 'package:auramed/screens/app_setting_screen.dart';
import 'package:auramed/screens/notifications_screen.dart';
import 'package:auramed/screens/appearance_screen.dart';
import 'package:auramed/screens/help_and_faq_screen.dart';
import 'package:auramed/screens/contact_support_screen.dart';
import 'package:auramed/screens/about_auramed_screen.dart';
import 'package:auramed/screens/health_tips_screen.dart';

// Appointment Screens
import 'package:auramed/screens/appointments/appointments_list_screen.dart';
import 'package:auramed/screens/appointments/appointment_detail_screen.dart';
import 'package:auramed/screens/appointments/book_appointment_screen.dart';
import 'package:auramed/screens/appointments/doctor_appointment_action_screen.dart';

// Consultation Screens
import 'package:auramed/screens/consultation/consultation_list_screen.dart';
import 'package:auramed/screens/consultation/consultation_chat_screen.dart';
import 'package:auramed/screens/consultation/doctor_notes_screen.dart';

// Readings Screens
import 'package:auramed/screens/readings/add_manual_reading_screen.dart';
import 'package:auramed/screens/readings/reading_detail_screen.dart';
import 'package:auramed/screens/readings/readings_history_screen.dart';
import 'package:auramed/screens/connect_device_screen.dart';

final GlobalKey<NavigatorState> appNavigatorKey =
GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    debugPrint('✅ Firebase initialized successfully!');
  } catch (e) {
    debugPrint('❌ Firebase initialization error: $e');
  }

  await FcmService.instance.initialize();

  runApp(const AuraMedApp());
}

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
            navigatorKey: appNavigatorKey,
            title: 'AuraMed',
            debugShowCheckedModeBanner: false,

            // THEMES
            theme: buildAuraLightTheme(),
            darkTheme: buildAuraDarkTheme(),
            themeMode: auth.currentThemeMode,

            // START SCREEN
            initialRoute: SplashScreen.routeName,

            // ROUTES
            routes: {
              // 🔵 CORE
              SplashScreen.routeName: (_) => const SplashScreen(),
              RoleSelectionScreen.routeName: (_) =>
              const RoleSelectionScreen(),

              // 🟢 PATIENT
              PatientLoginScreen.routeName: (_) =>
              const PatientLoginScreen(),
              PatientSignupScreen.routeName: (_) =>
              const PatientSignupScreen(),
              PatientDashboard.routeName: (_) =>
              const PatientDashboard(),

              // 🟢 DOCTOR
              DoctorLoginScreen.routeName: (_) =>
              const DoctorLoginScreen(),
              DoctorSignupScreen.routeName: (_) =>
              const DoctorSignupScreen(),
              DoctorDashboard.routeName: (_) =>
              const DoctorDashboard(),

              // 🟣 ADMIN (NEW)
              AdminLoginScreen.routeName: (_) =>
              const AdminLoginScreen(),
              AdminDashboardScreen.routeName: (_) =>
              const AdminDashboardScreen(),
              PendingDoctorsScreen.routeName: (_) =>
              const PendingDoctorsScreen(),

              // 🟡 COMMON
              PatientDetailScreen.routeName: (_) =>
              const PatientDetailScreen(),
              ProfileScreen.routeName: (_) =>
              const ProfileScreen(),
              EditProfileScreen.routeName: (_) =>
              const EditProfileScreen(),

              // 📅 APPOINTMENTS
              AppointmentsListScreen.routeName: (_) =>
              const AppointmentsListScreen(),
              AppointmentDetailScreen.routeName: (_) =>
              const AppointmentDetailScreen(),
              BookAppointmentScreen.routeName: (_) =>
              const BookAppointmentScreen(),
              DoctorAppointmentActionScreen.routeName: (_) =>
              const DoctorAppointmentActionScreen(),

              // 💬 CONSULTATION
              ConsultationListScreen.routeName: (_) =>
              const ConsultationListScreen(),
              ConsultationChatScreen.routeName: (_) =>
              const ConsultationChatScreen(),
              DoctorNotesScreen.routeName: (_) =>
              const DoctorNotesScreen(),

              // 📊 READINGS
              AddManualReadingScreen.routeName: (_) =>
              const AddManualReadingScreen(),
              ReadingDetailScreen.routeName: (_) =>
              const ReadingDetailScreen(),
              ReadingsHistoryScreen.routeName: (_) =>
              const ReadingsHistoryScreen(),

              // ⚙️ SETTINGS
              AppSettingsScreen.routeName: (_) =>
              const AppSettingsScreen(),
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

              // 🔌 DEVICE
              ConnectDeviceScreen.routeName: (_) =>
              const ConnectDeviceScreen(),
            },
          );
        },
      ),
    );
  }
}