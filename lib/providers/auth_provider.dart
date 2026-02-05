import 'package:flutter/material.dart';
import 'package:auramed/models/user.dart';
import 'package:auramed/models/reading.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  List<UserModel> _registeredUsers = []; // Track ALL registered users
  final Map<String, List<PatientReading>> _patientReadings = {};

  UserModel? get user => _user;
  List<UserModel> get registeredUsers => _registeredUsers;

  AuthProvider() {
    // Initialize with some sample patient users who have "registered"
    _initializeSampleData();
  }

  void _initializeSampleData() {
    // Add some pre-registered patients (simulating existing users)
    _registeredUsers = [
      UserModel(uid: 'p1', name: 'Ali Khan', email: 'ali@test.com', role: UserRole.patient),
      UserModel(uid: 'p2', name: 'Sarah Ali', email: 'sarah@test.com', role: UserRole.patient),
      UserModel(uid: 'p3', name: 'Mike Johnson', email: 'mike@test.com', role: UserRole.patient),
      UserModel(uid: 'd1', name: 'Dr. Fatima', email: 'doctor@test.com', role: UserRole.doctor),
    ];

    // Initialize sample readings for patients
    _patientReadings['p1'] = List.generate(7, (i) {
      final now = DateTime.now().subtract(Duration(hours: 6 - i));
      return PatientReading(
          timestamp: now,
          heartRate: 60 + i * 2,
          bp: '${110 + i}/${70 + i}',
          spo2: 96 + (i % 2)
      );
    });

    _patientReadings['p2'] = List.generate(7, (i) {
      final now = DateTime.now().subtract(Duration(days: i));
      return PatientReading(
          timestamp: now,
          heartRate: 70 + i,
          bp: '${120 + i}/${78 + i}',
          spo2: 95 + (i % 2)
      );
    });

    _patientReadings['p3'] = List.generate(5, (i) {
      final now = DateTime.now().subtract(Duration(hours: i * 2));
      return PatientReading(
          timestamp: now,
          heartRate: 65 + i,
          bp: '${115 + i}/${75 + i}',
          spo2: 97
      );
    });
  }

  // Enhanced login that tracks real users
  Future<bool> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 600));

    // Check if user already exists in registered users
    final existingUser = _registeredUsers.firstWhere(
          (user) => user.email.toLowerCase() == email.toLowerCase(),
      orElse: () => UserModel(uid: '', name: '', email: '', role: UserRole.patient),
    );

    UserRole role;
    String uid;
    String name;

    if (email.toLowerCase().contains('doc') ||
        email.toLowerCase().contains('doctor') ||
        email.toLowerCase().contains('dr.') ||
        email.toLowerCase().contains('dr ')) {
      role = UserRole.doctor;

      // If doctor exists, use existing data, else create new
      if (existingUser.uid.isNotEmpty && existingUser.role == UserRole.doctor) {
        uid = existingUser.uid;
        name = existingUser.name;
      } else {
        uid = 'd_${DateTime.now().millisecondsSinceEpoch}';
        name = 'Dr. ${_getNameFromEmail(email)}';
        // Add new doctor to registered users
        _registeredUsers.add(UserModel(uid: uid, name: name, email: email, role: role));
      }
    } else {
      role = UserRole.patient;

      // If patient exists, use existing data, else create new
      if (existingUser.uid.isNotEmpty && existingUser.role == UserRole.patient) {
        uid = existingUser.uid;
        name = existingUser.name;
      } else {
        uid = 'p_${DateTime.now().millisecondsSinceEpoch}';
        name = _getNameFromEmail(email);
        // Add new patient to registered users
        final newPatient = UserModel(uid: uid, name: name, email: email, role: role);
        _registeredUsers.add(newPatient);

        // Initialize empty readings for new patient
        _patientReadings[uid] = [];
      }
    }

    _user = UserModel(uid: uid, name: name, email: email, role: role);

    notifyListeners();
    return true;
  }

  // Enhanced login with more role detection options
  Future<bool> loginEnhanced(String email, String password) async {
    return login(email, password); // Now using the main login method
  }

  // Simple login that always returns doctor for testing
  Future<bool> loginAsDoctor(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 600));

    // Check if doctor already exists
    final existingDoctor = _registeredUsers.firstWhere(
          (user) => user.role == UserRole.doctor,
      orElse: () => UserModel(uid: '', name: '', email: '', role: UserRole.patient),
    );

    if (existingDoctor.uid.isNotEmpty) {
      _user = existingDoctor;
    } else {
      _user = UserModel(
          uid: 'd1',
          name: 'Dr. Test Doctor',
          email: email,
          role: UserRole.doctor
      );
      _registeredUsers.add(_user!);
    }

    notifyListeners();
    return true;
  }

  Future<bool> signup(String name, String email, String password, UserRole role) async {
    await Future.delayed(const Duration(milliseconds: 700));

    final uid = role == UserRole.doctor ?
    'd_${DateTime.now().millisecondsSinceEpoch}' :
    'p_${DateTime.now().millisecondsSinceEpoch}';

    // Create new user
    final newUser = UserModel(uid: uid, name: name, email: email, role: role);

    // Add to registered users list
    _registeredUsers.add(newUser);

    // Set as current user
    _user = newUser;

    // Initialize empty readings for new patients
    if (role == UserRole.patient) {
      _patientReadings[uid] = [];
    }

    notifyListeners();
    return true;
  }

  void logout() {
    _user = null;
    notifyListeners();
  }

  // Get REAL patients from registered users
  List<Map<String, dynamic>> getAssignedPatients() {
    // Filter only patient users from registered users
    final patientUsers = _registeredUsers.where((user) => user.role == UserRole.patient).toList();

    // Convert to the format expected by the dashboard
    final patients = patientUsers.map((patient) {
      final patientId = patient.uid;
      final readings = _patientReadings[patientId] ?? [];
      final lastReading = readings.isNotEmpty ? readings.last : null;

      // Calculate age from email or use default
      final age = _calculateAgeFromEmail(patient.email);

      String lastReadingText = 'No readings yet';
      if (lastReading != null) {
        lastReadingText = '${lastReading.heartRate} bpm • ${lastReading.bp} • SpO2: ${lastReading.spo2}%';
      }

      return {
        'id': patientId,
        'name': patient.name,
        'email': patient.email,
        'age': age,
        'last': lastReading,
        'lastReadingText': lastReadingText,
        'readingsCount': readings.length,
      };
    }).toList();

    return patients;
  }

  // Get readings for a specific patient id
  List<PatientReading> readingsFor(String patientId) {
    final readings = _patientReadings[patientId] ?? [];
    return readings;
  }

  // for patient screen: return readings for current user
  List<PatientReading> getMyReadings() {
    if (_user == null) {
      return [];
    }

    if (_user!.role == UserRole.doctor) {
      // Doctor sees sample data of first patient
      return _patientReadings['p1'] ?? [];
    } else {
      // Patient sees their own readings
      final readings = _patientReadings[_user!.uid] ?? [];
      return readings;
    }
  }

  // Add a new reading for current patient
  void addReading(PatientReading reading) {
    if (_user == null || _user!.role != UserRole.patient) {
      return;
    }

    final patientId = _user!.uid;
    if (_patientReadings[patientId] == null) {
      _patientReadings[patientId] = [];
    }

    _patientReadings[patientId]!.insert(0, reading); // Add to beginning
    notifyListeners();
  }

  // Helper method to extract name from email
  String _getNameFromEmail(String email) {
    final namePart = email.split('@').first;
    // Capitalize first letter of each word
    return namePart.split('.').map((part) {
      if (part.isEmpty) return '';
      return part[0].toUpperCase() + part.substring(1);
    }).join(' ');
  }

  // Helper method to calculate age (for demo purposes)
  int _calculateAgeFromEmail(String email) {
    // In a real app, this would come from user profile
    // For demo, we'll use a simple hash-based approach
    final hash = email.hashCode.abs();
    return 25 + (hash % 30); // Age between 25-55
  }

  // Method to simulate patient activity (for testing)
  void simulatePatientActivity() {
    final patients = _registeredUsers.where((user) => user.role == UserRole.patient).toList();
    for (final patient in patients) {
      if (_patientReadings[patient.uid] == null) {
        _patientReadings[patient.uid] = [];
      }

      // Add a new reading for each patient
      final newReading = PatientReading(
        timestamp: DateTime.now(),
        heartRate: 60 + (patient.uid.hashCode % 40),
        bp: '${110 + (patient.uid.hashCode % 20)}/${70 + (patient.uid.hashCode % 15)}',
        spo2: 95 + (patient.uid.hashCode % 4),
      );

      _patientReadings[patient.uid]!.insert(0, newReading);
    }
    notifyListeners();
  }
}

// Add this extension to your UserModel for better debugging
extension UserModelExtensions on UserModel {
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role.toString(),
    };
  }
}
