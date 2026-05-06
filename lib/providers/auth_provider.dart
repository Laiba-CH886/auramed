import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:auramed/models/user.dart';
import 'package:auramed/models/reading.dart';
import 'package:auramed/services/auth_service.dart';
import 'package:auramed/services/health_service.dart';
import 'package:auramed/services/fcm_service.dart';
import 'package:auramed/screens/consultation/consultation_service.dart';

class NotificationSettingsModel {
  final bool appointmentAlerts;
  final bool chatMessages;
  final bool healthReminders;

  const NotificationSettingsModel({
    required this.appointmentAlerts,
    required this.chatMessages,
    required this.healthReminders,
  });

  factory NotificationSettingsModel.defaults() {
    return const NotificationSettingsModel(
      appointmentAlerts: true,
      chatMessages: true,
      healthReminders: false,
    );
  }

  factory NotificationSettingsModel.fromMap(Map<String, dynamic>? map) {
    return NotificationSettingsModel(
      appointmentAlerts: map?['appointmentAlerts'] as bool? ?? true,
      chatMessages: map?['chatMessages'] as bool? ?? true,
      healthReminders: map?['healthReminders'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
    'appointmentAlerts': appointmentAlerts,
    'chatMessages': chatMessages,
    'healthReminders': healthReminders,
  };

  NotificationSettingsModel copyWith({
    bool? appointmentAlerts,
    bool? chatMessages,
    bool? healthReminders,
  }) {
    return NotificationSettingsModel(
      appointmentAlerts: appointmentAlerts ?? this.appointmentAlerts,
      chatMessages: chatMessages ?? this.chatMessages,
      healthReminders: healthReminders ?? this.healthReminders,
    );
  }
}

class AppearanceSettingsModel {
  final String themeMode;

  const AppearanceSettingsModel({required this.themeMode});

  factory AppearanceSettingsModel.defaults() =>
      const AppearanceSettingsModel(themeMode: 'light');

  factory AppearanceSettingsModel.fromMap(Map<String, dynamic>? map) {
    return AppearanceSettingsModel(
      themeMode: map?['themeMode'] as String? ?? 'light',
    );
  }

  Map<String, dynamic> toMap() => {'themeMode': themeMode};

  AppearanceSettingsModel copyWith({String? themeMode}) =>
      AppearanceSettingsModel(themeMode: themeMode ?? this.themeMode);
}

// ─────────────────────────────────────────────────────────────────────────────

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  UserModel? _user;
  List<UserModel> _registeredUsers = [];
  bool _isLoading = false;
  String? _errorMessage;
  final Map<String, List<PatientReading>> _patientReadings = {};

  NotificationSettingsModel _notificationSettings =
  NotificationSettingsModel.defaults();
  bool _isNotificationSettingsLoading = false;

  AppearanceSettingsModel _appearanceSettings =
  AppearanceSettingsModel.defaults();
  bool _isAppearanceSettingsLoading = false;

  // FIX: track whether we are already loading user data so the
  // authStateChanges listener and the login() method don't race.
  bool _isLoadingUser = false;

  UserModel? get user => _user;
  List<UserModel> get registeredUsers => _registeredUsers;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;
  String? get errorMessage => _errorMessage;
  User? get firebaseUser => _auth.currentUser;

  NotificationSettingsModel get notificationSettings => _notificationSettings;
  bool get isNotificationSettingsLoading => _isNotificationSettingsLoading;

  AppearanceSettingsModel get appearanceSettings => _appearanceSettings;
  bool get isAppearanceSettingsLoading => _isAppearanceSettingsLoading;

  bool get isChatNotificationEnabled => _notificationSettings.chatMessages;
  bool get isAppointmentNotificationEnabled =>
      _notificationSettings.appointmentAlerts;
  bool get isHealthReminderEnabled => _notificationSettings.healthReminders;

  ThemeMode get currentThemeMode {
    switch (_appearanceSettings.themeMode) {
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      case 'light':
      default:
        return ThemeMode.light;
    }
  }

  AuthProvider() {
    // FIX: authStateChanges is the single source of truth for user state.
    // login() / signup() / signInWithGoogle() no longer call
    // _loadUserFromFirestore directly — they let this listener handle it.
    _auth.authStateChanges().listen(_onAuthStateChanged);

    // FIX: do NOT load all users on boot. Fetch on demand (doctor only).
    // See getAssignedPatients() below.
  }

  // ── Auth state ────────────────────────────────────────────────────────────

  Future<void> _onAuthStateChanged(User? fbUser) async {
    if (fbUser == null) {
      _user = null;
      _patientReadings.clear();
      _notificationSettings = NotificationSettingsModel.defaults();
      _appearanceSettings = AppearanceSettingsModel.defaults();
      notifyListeners();
      return;
    }

    // FIX: guard against double-load (authStateChanges + login() race)
    if (_isLoadingUser) return;
    await _loadUserFromFirestore(fbUser.uid);
  }

  Future<void> _loadUserFromFirestore(String uid) async {
    _isLoadingUser = true;

    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      final fb = _auth.currentUser;

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final roleStr = data['role'] as String? ?? 'patient';
        final role = roleStr == 'doctor' ? UserRole.doctor : UserRole.patient;

        _user = UserModel(
          uid: uid,
          name: data['name'] as String? ?? fb?.displayName ?? '',
          email: data['email'] as String? ?? fb?.email ?? '',
          role: role,
          phone: data['phone'] as String?,
          age: data['age'] as int?,
          bloodGroup: data['bloodGroup'] as String?,
          photoUrl: data['photoUrl'] as String? ?? fb?.photoURL,
          isApproved: data['isApproved'] as bool? ?? true,
          isBlocked: data['isBlocked'] as bool? ?? false,
        );

        _notificationSettings = NotificationSettingsModel.fromMap(
          data['notificationSettings'] as Map<String, dynamic>?,
        );
        _appearanceSettings = AppearanceSettingsModel.fromMap(
          data['appearanceSettings'] as Map<String, dynamic>?,
        );

        if (role == UserRole.patient && _patientReadings[uid] == null) {
          _patientReadings[uid] = [];
          await _loadReadingsFromFirestore(uid);
        }
      } else if (fb != null) {
        // New Google sign-in user — create Firestore record
        _user = UserModel(
          uid: uid,
          name: fb.displayName ?? _getNameFromEmail(fb.email ?? ''),
          email: fb.email ?? '',
          role: UserRole.patient,
          photoUrl: fb.photoURL,
          isApproved: true,
          isBlocked: false,
        );
        _notificationSettings = NotificationSettingsModel.defaults();
        _appearanceSettings = AppearanceSettingsModel.defaults();

        await _firestore.collection('users').doc(uid).set({
          'uid': uid,
          'name': _user!.name,
          'email': _user!.email,
          'role': 'patient',
          'isApproved': true,
          'isBlocked': false,
          'notificationSettings': _notificationSettings.toMap(),
          'appearanceSettings': _appearanceSettings.toMap(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // FCM token sync — fire-and-forget, don't block notifyListeners
      _syncFcmTokenIfNeeded().catchError((_) {});
    } catch (e) {
      debugPrint('AuthProvider: Error loading user: $e');
    }

    _isLoadingUser = false;
    notifyListeners(); // single notify after everything is ready
  }

  // ── Auth actions ──────────────────────────────────────────────────────────

  /// FIX: login() no longer calls _loadUserFromFirestore itself.
  /// authStateChanges fires automatically after signIn — that's enough.
  Future<Map<String, dynamic>> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.signInWithEmail(
      email: email,
      password: password,
    );

    if (result['success'] != true) {
      _errorMessage = result['message'] as String?;
      _isLoading = false;
      notifyListeners();
    }
    // On success: authStateChanges fires → _onAuthStateChanged →
    // _loadUserFromFirestore → notifyListeners (with _isLoading still true).
    // We clear _isLoading there.
    // FIX: clear loading flag after user data is ready.
    else {
      // Wait for _isLoadingUser to finish so callers can act on result.
      // authStateChanges triggers immediately on signIn so we just yield.
      await Future.doWhile(() async {
        if (!_isLoadingUser && _user != null) return false;
        await Future.delayed(const Duration(milliseconds: 50));
        return true;
      }).timeout(
        const Duration(seconds: 10),
        onTimeout: () {},
      );
      _isLoading = false;
      notifyListeners();
    }

    return result;
  }

  Future<bool> loginEnhanced(String email, String password) async {
    final result = await login(email, password);
    return result['success'] == true;
  }

  /// FIX: signup() creates the Firestore doc and sets _user directly
  /// without calling _loadUserFromFirestore (authStateChanges handles it).
  Future<bool> signup(
      String name,
      String email,
      String password,
      UserRole role,
      ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final fbUser = credential.user;
      if (fbUser == null) throw Exception('User creation failed');

      await fbUser.updateDisplayName(name);

      final roleStr = role == UserRole.doctor ? 'doctor' : 'patient';

      await _firestore.collection('users').doc(fbUser.uid).set({
        'uid': fbUser.uid,
        'name': name,
        'email': email,
        'role': roleStr,
        'isApproved': role != UserRole.doctor, // doctors pending by default
        'isBlocked': false,
        'notificationSettings': NotificationSettingsModel.defaults().toMap(),
        'appearanceSettings': AppearanceSettingsModel.defaults().toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // authStateChanges will fire and load the full user — no need to
      // call _loadUserFromFirestore here.
      _isLoading = false;
      // Don't notify — authStateChanges will notify once user is loaded.
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>> signInWithGoogle({required String role}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.signInWithGoogle(role: role).timeout(
        const Duration(seconds: 30),
        onTimeout: () => {
          'success': false,
          'message': 'Google Sign-In timed out. Check your internet.',
        },
      );

      if (result['success'] != true) {
        _errorMessage = result['message'] as String?;
        _isLoading = false;
        notifyListeners();
      } else {
        // authStateChanges handles the rest
        await Future.doWhile(() async {
          if (!_isLoadingUser && _user != null) return false;
          await Future.delayed(const Duration(milliseconds: 50));
          return true;
        }).timeout(const Duration(seconds: 10), onTimeout: () {});
        _isLoading = false;
        notifyListeners();
      }

      return result;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Google Sign-In failed. Please try again.';
      notifyListeners();
      return {'success': false, 'message': _errorMessage};
    }
  }

  Future<void> logout() async {
    if (_user != null && _user!.role == UserRole.doctor) {
      await FcmService.instance.deleteDoctorToken(doctorId: _user!.uid);
    }
    await _authService.signOut();
    // authStateChanges fires with null → clears state and notifies
  }

  // ── Profile ───────────────────────────────────────────────────────────────

  Future<void> updateProfile({
    required String name,
    required String phone,
    required int age,
    required String bloodGroup,
  }) async {
    if (_user == null) return;

    _user = _user!.copyWith(
      name: name,
      phone: phone,
      age: age,
      bloodGroup: bloodGroup,
    );
    notifyListeners();

    try {
      await _firestore.collection('users').doc(_user!.uid).update({
        'name': name,
        'phone': phone,
        'age': age,
        'bloodGroup': bloodGroup,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // FIX: only sync FCM for doctors — patients don't need it
      if (_user!.role == UserRole.doctor) {
        await _syncFcmTokenIfNeeded();
      }
    } catch (e) {
      debugPrint('AuthProvider: Error updating profile: $e');
    }
  }

  // ── Notification settings ─────────────────────────────────────────────────

  Future<void> loadNotificationSettings() async {
    if (_user == null) return;
    _isNotificationSettingsLoading = true;
    notifyListeners();

    try {
      final doc = await _firestore.collection('users').doc(_user!.uid).get();
      _notificationSettings = NotificationSettingsModel.fromMap(
        (doc.data() ?? {})['notificationSettings'] as Map<String, dynamic>?,
      );
    } catch (e) {
      debugPrint('AuthProvider: Error loading notification settings: $e');
    }

    _isNotificationSettingsLoading = false;
    notifyListeners();
  }

  Future<bool> updateNotificationSetting({
    bool? appointmentAlerts,
    bool? chatMessages,
    bool? healthReminders,
  }) async {
    if (_user == null) return false;

    final previous = _notificationSettings;
    _notificationSettings = _notificationSettings.copyWith(
      appointmentAlerts: appointmentAlerts,
      chatMessages: chatMessages,
      healthReminders: healthReminders,
    );
    notifyListeners();

    try {
      await _firestore.collection('users').doc(_user!.uid).update({
        'notificationSettings': _notificationSettings.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      _notificationSettings = previous;
      notifyListeners();
      debugPrint('AuthProvider: Error updating notification setting: $e');
      return false;
    }
  }

  // ── Appearance settings ───────────────────────────────────────────────────

  Future<void> loadAppearanceSettings() async {
    if (_user == null) {
      _appearanceSettings = AppearanceSettingsModel.defaults();
      notifyListeners();
      return;
    }

    _isAppearanceSettingsLoading = true;
    notifyListeners();

    try {
      final doc = await _firestore.collection('users').doc(_user!.uid).get();
      _appearanceSettings = AppearanceSettingsModel.fromMap(
        (doc.data() ?? {})['appearanceSettings'] as Map<String, dynamic>?,
      );
    } catch (e) {
      debugPrint('AuthProvider: Error loading appearance settings: $e');
      _appearanceSettings = AppearanceSettingsModel.defaults();
    }

    _isAppearanceSettingsLoading = false;
    notifyListeners();
  }

  Future<bool> updateAppearanceSettings({String? themeMode}) async {
    if (_user == null) return false;

    final previous = _appearanceSettings;
    _appearanceSettings = _appearanceSettings.copyWith(themeMode: themeMode);
    notifyListeners();

    try {
      await _firestore.collection('users').doc(_user!.uid).update({
        'appearanceSettings': _appearanceSettings.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      _appearanceSettings = previous;
      notifyListeners();
      debugPrint('AuthProvider: Error updating appearance settings: $e');
      return false;
    }
  }

  // ── Readings ──────────────────────────────────────────────────────────────

  List<PatientReading> getMyReadings() {
    if (_user == null) return [];
    return _patientReadings[_user!.uid] ?? [];
  }

  List<PatientReading> readingsFor(String patientId) =>
      _patientReadings[patientId] ?? [];

  bool isEmergencyReading(PatientReading reading) =>
      HealthService.isEmergencyVitals(
        heartRate: reading.heartRate,
        spo2: reading.spo2,
        bp: reading.bp,
      );

  List<String> getEmergencyReasons(PatientReading reading) =>
      HealthService.emergencyReasons(
        heartRate: reading.heartRate,
        spo2: reading.spo2,
        bp: reading.bp,
      );

  Future<void> addReading(
      PatientReading reading, {
        bool fromWatch = false,
      }) async {
    if (_user == null || _user!.role != UserRole.patient) return;

    final uid = _user!.uid;
    _patientReadings[uid] ??= [];
    _patientReadings[uid]!.insert(0, reading);
    notifyListeners(); // update UI immediately with local data

    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('readings')
          .add({
        'heartRate': reading.heartRate,
        'bp': reading.bp,
        'spo2': reading.spo2,
        'sleepMinutes': reading.sleepMinutes,
        'stressLevel': reading.stressLevel,
        'waterIntakeLiters': reading.waterIntakeLiters,
        'timestamp': reading.timestamp.toIso8601String(),
        'source': fromWatch ? 'watch' : 'manual',
        'isEmergency': isEmergencyReading(reading),
        'emergencyReasons': getEmergencyReasons(reading),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update consultation history
      final consultInfo =
      await ConsultationService.resolveDoctorForPatient(patientId: uid);

      if (consultInfo != null && consultInfo['consultationId'] != null) {
        await _firestore
            .collection('consultations')
            .doc(consultInfo['consultationId']!)
            .update({
          'history': FieldValue.arrayUnion([
            {
              'heartRate': reading.heartRate,
              'bp': reading.bp,
              'spo2': reading.spo2,
              'sleepMinutes': reading.sleepMinutes,
              'stressLevel': reading.stressLevel,
              'waterIntakeLiters': reading.waterIntakeLiters,
              'timestamp': FieldValue.serverTimestamp(),
              'source': fromWatch ? 'watch' : 'manual',
            }
          ]),
        });
      }
    } catch (e) {
      debugPrint('Error saving reading: $e');
    }

    if (isEmergencyReading(reading)) {
      await _handleEmergencyReading(reading);
    } else {
      await _handleNormalVitalsUpdate(reading);
    }
  }

  Future<void> _handleNormalVitalsUpdate(PatientReading reading) async {
    if (_user == null) return;

    final consultInfo = await ConsultationService.resolveDoctorForPatient(
      patientId: _user!.uid,
    );
    if (consultInfo == null || (consultInfo['doctorId'] ?? '').isEmpty) return;

    final consultationId = consultInfo['consultationId']!;
    final patientName = consultInfo['patientName']?.isNotEmpty == true
        ? consultInfo['patientName']!
        : _user!.name;

    await ConsultationService.addVitalsSystemMessage(
      consultationId: consultationId,
      patientId: _user!.uid,
      patientName: patientName,
      heartRate: reading.heartRate,
      bp: reading.bp,
      spo2: reading.spo2,
      sleepMinutes: reading.sleepMinutes,
      stressLevel: reading.stressLevel,
      waterIntakeLiters: reading.waterIntakeLiters,
      isEmergency: false,
      reasons: const [],
    );

    await ConsultationService.addAutoMedicalNote(
      consultationId: consultationId,
      patientId: _user!.uid,
      patientName: patientName,
      heartRate: reading.heartRate,
      bp: reading.bp,
      spo2: reading.spo2,
      sleepMinutes: reading.sleepMinutes,
      stressLevel: reading.stressLevel,
      waterIntakeLiters: reading.waterIntakeLiters,
      isEmergency: false,
      reasons: const [],
    );
  }

  Future<void> _handleEmergencyReading(PatientReading reading) async {
    if (_user == null) return;

    final consultInfo = await ConsultationService.resolveDoctorForPatient(
      patientId: _user!.uid,
    );
    if (consultInfo == null) return;

    final consultationId = consultInfo['consultationId']!;
    final doctorId = consultInfo['doctorId'] ?? '';
    if (doctorId.isEmpty) return;

    final doctorName = consultInfo['doctorName'] ?? 'Doctor';
    final patientName = consultInfo['patientName']?.isNotEmpty == true
        ? consultInfo['patientName']!
        : _user!.name;
    final reasons = getEmergencyReasons(reading);

    await ConsultationService.addVitalsSystemMessage(
      consultationId: consultationId,
      patientId: _user!.uid,
      patientName: patientName,
      heartRate: reading.heartRate,
      bp: reading.bp,
      spo2: reading.spo2,
      sleepMinutes: reading.sleepMinutes,
      stressLevel: reading.stressLevel,
      waterIntakeLiters: reading.waterIntakeLiters,
      isEmergency: true,
      reasons: reasons,
    );

    await ConsultationService.addAutoMedicalNote(
      consultationId: consultationId,
      patientId: _user!.uid,
      patientName: patientName,
      heartRate: reading.heartRate,
      bp: reading.bp,
      spo2: reading.spo2,
      sleepMinutes: reading.sleepMinutes,
      stressLevel: reading.stressLevel,
      waterIntakeLiters: reading.waterIntakeLiters,
      isEmergency: true,
      reasons: reasons,
    );

    await ConsultationService.createEmergencyAlert(
      consultationId: consultationId,
      patientId: _user!.uid,
      patientName: patientName,
      doctorId: doctorId,
      doctorName: doctorName,
      heartRate: reading.heartRate,
      bp: reading.bp,
      spo2: reading.spo2,
      sleepMinutes: reading.sleepMinutes,
      stressLevel: reading.stressLevel,
      waterIntakeLiters: reading.waterIntakeLiters,
      reasons: reasons,
    );
  }

  Future<void> _loadReadingsFromFirestore(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('readings')
          .orderBy('createdAt', descending: false)
          .limit(50)
          .get();

      _patientReadings[uid] = snapshot.docs.map((doc) {
        final data = doc.data();
        return PatientReading(
          heartRate: data['heartRate'] as int? ?? 0,
          bp: data['bp'] as String? ?? '--',
          spo2: data['spo2'] as int? ?? 0,
          sleepMinutes: data['sleepMinutes'] as int?,
          stressLevel: data['stressLevel'] as int?,
          waterIntakeLiters:
          (data['waterIntakeLiters'] as num?)?.toDouble(),
          timestamp: DateTime.tryParse(data['timestamp'] as String? ?? '') ??
              DateTime.now(),
        );
      }).toList();
    } catch (e) {
      debugPrint('AuthProvider: Error loading readings: $e');
      _patientReadings[uid] = [];
    }
  }

  // ── Patients (doctor only) ────────────────────────────────────────────────

  /// FIX: was called on every app boot for ALL users.
  /// Now fetches on demand, doctor-only.
  Future<List<Map<String, dynamic>>> getAssignedPatients() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'patient')
          .get();

      _registeredUsers = snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc.data(), doc.id))
          .toList();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': data['uid'] ?? doc.id,
          'name': data['name'] ?? '',
          'email': data['email'] ?? '',
          'age': data['age'] ?? '--',
          'bloodGroup': data['bloodGroup'] ?? '--',
          'lastReadingText': 'No readings yet',
          'readingsCount': 0,
        };
      }).toList();
    } catch (e) {
      debugPrint('AuthProvider: Error fetching patients: $e');
      return [];
    }
  }

  // ── Misc ──────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> resetPasswordDirect({
    required String email,
    required String oldPassword,
    required String newPassword,
  }) async {
    return _authService.resetPasswordDirect(
      email: email,
      oldPassword: oldPassword,
      newPassword: newPassword,
    );
  }

  Future<void> _syncFcmTokenIfNeeded() async {
    if (_user == null || _user!.role != UserRole.doctor) return;
    await FcmService.instance.saveDoctorToken(
      doctorId: _user!.uid,
      doctorName: _user!.name,
    );
  }

  String _getNameFromEmail(String email) {
    return email
        .split('@')
        .first
        .split('.')
        .map((p) => p.isEmpty ? '' : p[0].toUpperCase() + p.substring(1))
        .join(' ');
  }
}