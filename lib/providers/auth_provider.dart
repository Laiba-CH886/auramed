import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:auramed/models/user.dart';
import 'package:auramed/models/reading.dart';
import 'package:auramed/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  // ── Services ──────────────────────────────────────────────────────────────
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ── State ─────────────────────────────────────────────────────────────────
  UserModel? _user;
  List<UserModel> _registeredUsers = [];
  bool _isLoading = false;
  String? _errorMessage;
  final Map<String, List<PatientReading>> _patientReadings = {};

  // ── Getters ───────────────────────────────────────────────────────────────
  UserModel? get user => _user;
  List<UserModel> get registeredUsers => _registeredUsers;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;
  String? get errorMessage => _errorMessage;

  /// Raw Firebase user — used for displayName / photoURL fallback
  User? get firebaseUser => _auth.currentUser;

  AuthProvider() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
    _loadAllUsers();
  }

  // ── Auth State Listener ───────────────────────────────────────────────────
  Future<void> _onAuthStateChanged(User? fbUser) async {
    if (fbUser == null) {
      _user = null;
      _patientReadings.clear();
      notifyListeners();
      return;
    }
    await _loadUserFromFirestore(fbUser.uid);
  }

  Future<void> _loadAllUsers() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      _registeredUsers = snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc.data(), doc.id))
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('AuthProvider: Error loading all users: $e');
    }
  }

  Future<void> _loadUserFromFirestore(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      final fb = firebaseUser;

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final roleStr = data['role'] as String? ?? 'patient';
        final role =
        roleStr == 'doctor' ? UserRole.doctor : UserRole.patient;

        _user = UserModel(
          uid: uid,
          name: data['name'] as String? ??
              fb?.displayName ??
              _getNameFromEmail(data['email'] as String? ?? ''),
          email: data['email'] as String? ?? fb?.email ?? '',
          role: role,
          phone: data['phone'] as String?,
          age: data['age'] as int?,
          bloodGroup: data['bloodGroup'] as String?,
          photoUrl: data['photoUrl'] as String? ?? fb?.photoURL,
        );

        if (role == UserRole.patient && _patientReadings[uid] == null) {
          _patientReadings[uid] = [];
          await _loadReadingsFromFirestore(uid);
        }
      } else {
        if (fb != null) {
          _user = UserModel(
            uid: uid,
            name: fb.displayName ?? _getNameFromEmail(fb.email ?? ''),
            email: fb.email ?? '',
            role: UserRole.patient,
            photoUrl: fb.photoURL,
          );
          await _firestore.collection('users').doc(uid).set({
            'uid': uid,
            'name': _user!.name,
            'email': _user!.email,
            'role': 'patient',
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      debugPrint('AuthProvider: Error loading user from Firestore: $e');
    }
    notifyListeners();
  }

  // ── Login ─────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.signInWithEmail(
      email: email,
      password: password,
    );

    if (result['success'] == true) {
      await _loadUserFromFirestore(result['uid'] as String);
    } else {
      _errorMessage = result['message'] as String?;
    }

    _isLoading = false;
    notifyListeners();
    return result;
  }

  // ── Signup ────────────────────────────────────────────────────────────────
  Future<bool> signup(
      String name, String email, String password, UserRole role) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final UserCredential credential =
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? fbUser = credential.user;
      if (fbUser == null) throw Exception("User creation failed");

      await fbUser.updateDisplayName(name);

      final roleStr = role == UserRole.doctor ? 'doctor' : 'patient';
      await _firestore.collection('users').doc(fbUser.uid).set({
        'uid': fbUser.uid,
        'name': name,
        'email': email,
        'role': roleStr,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _user = UserModel(
        uid: fbUser.uid,
        name: name,
        email: email,
        role: role,
      );

      _isLoading = false;
      notifyListeners();
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

  Future<bool> loginEnhanced(String email, String password) async {
    final result = await login(email, password);
    return result['success'] == true;
  }

  // ── Google Sign-In ────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> signInWithGoogle({required String role}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // ✅ 30-second timeout prevents infinite spinner
      final result = await _authService
          .signInWithGoogle(role: role)
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () => {
          'success': false,
          'message':
          'Google Sign-In timed out. Please check your internet and try again.',
        },
      );

      if (result['success'] == true) {
        await _loadUserFromFirestore(result['uid'] as String);
      } else {
        _errorMessage = result['message'] as String?;
      }

      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Google Sign-In failed. Please try again.';
      notifyListeners();
      return {'success': false, 'message': _errorMessage};
    }
  }

  // ── Password Reset ────────────────────────────────────────────────────────
  Future<void> sendPasswordReset({required String email}) async {
    await _authService.sendPasswordResetEmail(email: email);
  }

  // ── Sign Out ──────────────────────────────────────────────────────────────
  Future<void> logout() async {
    await _authService.signOut();
    _user = null;
    _patientReadings.clear();
    notifyListeners();
  }

  // ── Update Profile ────────────────────────────────────────────────────────
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

    try {
      await _firestore.collection('users').doc(_user!.uid).update({
        'name': name,
        'phone': phone,
        'age': age,
        'bloodGroup': bloodGroup,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('AuthProvider: Error updating profile: $e');
    }

    notifyListeners();
  }

  // ── Readings ──────────────────────────────────────────────────────────────
  List<PatientReading> getMyReadings() {
    if (_user == null) return [];
    return _patientReadings[_user!.uid] ?? [];
  }

  List<PatientReading> readingsFor(String patientId) {
    return _patientReadings[patientId] ?? [];
  }

  void addReading(PatientReading reading) {
    if (_user == null || _user!.role != UserRole.patient) return;

    final uid = _user!.uid;
    _patientReadings[uid] ??= [];
    _patientReadings[uid]!.insert(0, reading);

    _firestore
        .collection('users')
        .doc(uid)
        .collection('readings')
        .add({
      'heartRate': reading.heartRate,
      'bp': reading.bp,
      'spo2': reading.spo2,
      'timestamp': reading.timestamp.toIso8601String(),
      'createdAt': FieldValue.serverTimestamp(),
    }).catchError((e) {
      debugPrint('Error saving reading: $e');
      return null;
    });

    notifyListeners();
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
          timestamp:
          DateTime.tryParse(data['timestamp'] as String? ?? '') ??
              DateTime.now(),
        );
      }).toList();
    } catch (e) {
      debugPrint('AuthProvider: Error loading readings: $e');
      _patientReadings[uid] = [];
    }
  }

  // ── Doctor helpers ────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getAssignedPatients() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'patient')
          .get();

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

  // ── Helpers ───────────────────────────────────────────────────────────────
  String _getNameFromEmail(String email) {
    final namePart = email.split('@').first;
    return namePart.split('.').map((part) {
      if (part.isEmpty) return '';
      return part[0].toUpperCase() + part.substring(1);
    }).join(' ');
  }
}