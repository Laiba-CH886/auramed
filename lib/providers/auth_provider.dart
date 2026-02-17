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
    _initializeSampleData();
  }

  void _initializeSampleData() {
    _registeredUsers = [
      UserModel(uid: 'p1', name: 'Ali Khan', email: 'ali@test.com', role: UserRole.patient, phone: '+923001234567', age: 25, bloodGroup: 'A+'),
      UserModel(uid: 'p2', name: 'Sarah Ali', email: 'sarah@test.com', role: UserRole.patient, phone: '+923007654321', age: 22, bloodGroup: 'O-'),
      UserModel(uid: 'p3', name: 'Mike Johnson', email: 'mike@test.com', role: UserRole.patient),
      UserModel(uid: 'd1', name: 'Dr. Fatima', email: 'doctor@test.com', role: UserRole.doctor),
    ];

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

  Future<void> updateProfile({
    required String name,
    required String phone,
    required int age,
    required String bloodGroup,
  }) async {
    if (_user == null) return;

    // Update current user
    _user = _user!.copyWith(
      name: name,
      phone: phone,
      age: age,
      bloodGroup: bloodGroup,
    );

    // Update in registered users list
    final index = _registeredUsers.indexWhere((u) => u.uid == _user!.uid);
    if (index != -1) {
      _registeredUsers[index] = _user!;
    }

    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 600));

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

      if (existingUser.uid.isNotEmpty && existingUser.role == UserRole.doctor) {
        uid = existingUser.uid;
        _user = existingUser;
      } else {
        uid = 'd_${DateTime.now().millisecondsSinceEpoch}';
        name = 'Dr. ${_getNameFromEmail(email)}';
        _user = UserModel(uid: uid, name: name, email: email, role: role);
        _registeredUsers.add(_user!);
      }
    } else {
      role = UserRole.patient;

      if (existingUser.uid.isNotEmpty && existingUser.role == UserRole.patient) {
        uid = existingUser.uid;
        _user = existingUser;
      } else {
        uid = 'p_${DateTime.now().millisecondsSinceEpoch}';
        name = _getNameFromEmail(email);
        _user = UserModel(uid: uid, name: name, email: email, role: role);
        _registeredUsers.add(_user!);
        _patientReadings[uid] = [];
      }
    }

    notifyListeners();
    return true;
  }

  Future<bool> loginEnhanced(String email, String password) async {
    return login(email, password);
  }

  Future<bool> loginAsDoctor(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 600));

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

    final newUser = UserModel(uid: uid, name: name, email: email, role: role);
    _registeredUsers.add(newUser);
    _user = newUser;

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

  List<Map<String, dynamic>> getAssignedPatients() {
    final patientUsers = _registeredUsers.where((user) => user.role == UserRole.patient).toList();

    return patientUsers.map((patient) {
      final patientId = patient.uid;
      final readings = _patientReadings[patientId] ?? [];
      final lastReading = readings.isNotEmpty ? readings.last : null;
      final age = patient.age ?? _calculateAgeFromEmail(patient.email);

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
  }

  List<PatientReading> readingsFor(String patientId) {
    return _patientReadings[patientId] ?? [];
  }

  List<PatientReading> getMyReadings() {
    if (_user == null) return [];

    if (_user!.role == UserRole.doctor) {
      return _patientReadings['p1'] ?? [];
    } else {
      return _patientReadings[_user!.uid] ?? [];
    }
  }

  void addReading(PatientReading reading) {
    if (_user == null || _user!.role != UserRole.patient) return;

    final patientId = _user!.uid;
    if (_patientReadings[patientId] == null) {
      _patientReadings[patientId] = [];
    }

    _patientReadings[patientId]!.insert(0, reading);
    notifyListeners();
  }

  String _getNameFromEmail(String email) {
    final namePart = email.split('@').first;
    return namePart.split('.').map((part) {
      if (part.isEmpty) return '';
      return part[0].toUpperCase() + part.substring(1);
    }).join(' ');
  }

  int _calculateAgeFromEmail(String email) {
    final hash = email.hashCode.abs();
    return 25 + (hash % 30);
  }

  void simulatePatientActivity() {
    final patients = _registeredUsers.where((user) => user.role == UserRole.patient).toList();
    for (final patient in patients) {
      if (_patientReadings[patient.uid] == null) {
        _patientReadings[patient.uid] = [];
      }

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
