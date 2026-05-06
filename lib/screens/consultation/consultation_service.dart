import 'package:cloud_firestore/cloud_firestore.dart';

class ConsultationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<String?> createConsultation({
    required String patientId,
    required String patientName,
    required String doctorId,
    required String doctorName,
  }) async {
    try {
      final existing = await _firestore
          .collection('consultations')
          .where('patientId', isEqualTo: patientId)
          .where('doctorId', isEqualTo: doctorId)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        return existing.docs.first.id;
      }

      final ref = await _firestore.collection('consultations').add({
        'patientId': patientId,
        'patientName': patientName,
        'doctorId': doctorId,
        'doctorName': doctorName,
        'status': 'active',
        'lastMessage': '',
        'lastSenderId': '',
        'isReadByDoctor': true,
        'isReadByPatient': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return ref.id;
    } catch (e) {
      return null;
    }
  }

  static Future<void> completeConsultation(String consultationId) async {
    await _firestore.collection('consultations').doc(consultationId).update({
      'status': 'completed',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<Map<String, String>?> resolveDoctorForPatient({
    required String patientId,
  }) async {
    try {
      final consultSnap = await _firestore
          .collection('consultations')
          .where('patientId', isEqualTo: patientId)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      if (consultSnap.docs.isNotEmpty) {
        final data = consultSnap.docs.first.data();
        return {
          'consultationId': consultSnap.docs.first.id,
          'doctorId': data['doctorId'] as String? ?? '',
          'doctorName': data['doctorName'] as String? ?? 'Doctor',
          'patientName': data['patientName'] as String? ?? 'Patient',
        };
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> getOrCreateConsultationForEmergency({
    required String patientId,
    required String patientName,
    required String doctorId,
    required String doctorName,
  }) async {
    final existing = await _firestore
        .collection('consultations')
        .where('patientId', isEqualTo: patientId)
        .where('doctorId', isEqualTo: doctorId)
        .where('status', isEqualTo: 'active')
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      return existing.docs.first.id;
    }

    return createConsultation(
      patientId: patientId,
      patientName: patientName,
      doctorId: doctorId,
      doctorName: doctorName,
    );
  }

  static String _formatSleep(int? sleepMinutes) {
    if (sleepMinutes == null || sleepMinutes <= 0) return '--';
    final hours = sleepMinutes ~/ 60;
    final minutes = sleepMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  static String _formatStress(int? stressLevel) {
    if (stressLevel == null || stressLevel <= 0) return '--';
    return '$stressLevel%';
  }

  static String _formatWater(double? waterIntakeLiters) {
    if (waterIntakeLiters == null || waterIntakeLiters <= 0) return '--';
    return '${waterIntakeLiters.toStringAsFixed(1)} L';
  }

  static Future<void> addVitalsSystemMessage({
    required String consultationId,
    required String patientId,
    required String patientName,
    required int heartRate,
    required String bp,
    required int spo2,
    int? sleepMinutes,
    int? stressLevel,
    double? waterIntakeLiters,
    required bool isEmergency,
    required List<String> reasons,
  }) async {
    final sleepText = _formatSleep(sleepMinutes);
    final stressText = _formatStress(stressLevel);
    final waterText = _formatWater(waterIntakeLiters);

    final messageText = isEmergency
        ? '🚨 Emergency Alert\n'
        'Patient: $patientName\n'
        'HR: $heartRate bpm\n'
        'BP: $bp\n'
        'SpO₂: $spo2%\n'
        'Sleep: $sleepText\n'
        'Stress: $stressText\n'
        'Water: $waterText\n'
        '${reasons.join('\n')}'
        : '📈 New Vitals Update\n'
        'Patient: $patientName\n'
        'HR: $heartRate bpm\n'
        'BP: $bp\n'
        'SpO₂: $spo2%\n'
        'Sleep: $sleepText\n'
        'Stress: $stressText\n'
        'Water: $waterText';

    final msgRef = _firestore
        .collection('consultations')
        .doc(consultationId)
        .collection('messages')
        .doc();

    final consultationRef =
    _firestore.collection('consultations').doc(consultationId);

    final batch = _firestore.batch();

    batch.set(msgRef, {
      'text': messageText,
      'senderName': patientName,
      'senderId': patientId,
      'isSystemMessage': true,
      'messageType': isEmergency ? 'emergency_vitals' : 'vitals_update',
      'heartRate': heartRate,
      'bp': bp,
      'spo2': spo2,
      'sleepMinutes': sleepMinutes,
      'stressLevel': stressLevel,
      'waterIntakeLiters': waterIntakeLiters,
      'reasons': reasons,
      'createdAt': FieldValue.serverTimestamp(),
    });

    batch.update(consultationRef, {
      'lastMessage': messageText,
      'lastSenderId': patientId,
      'isReadByDoctor': false,
      'isReadByPatient': true,
      'latestVitals': {
        'heartRate': heartRate,
        'bp': bp,
        'spo2': spo2,
        'sleepMinutes': sleepMinutes,
        'stressLevel': stressLevel,
        'waterIntakeLiters': waterIntakeLiters,
        'timestamp': FieldValue.serverTimestamp(),
      },
      'hasEmergency': isEmergency,
      'lastEmergencyText': isEmergency ? reasons.join(', ') : '',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  static Future<void> addAutoMedicalNote({
    required String consultationId,
    required String patientId,
    required String patientName,
    required int heartRate,
    required String bp,
    required int spo2,
    int? sleepMinutes,
    int? stressLevel,
    double? waterIntakeLiters,
    required bool isEmergency,
    required List<String> reasons,
  }) async {
    final sleepText = _formatSleep(sleepMinutes);
    final stressText = _formatStress(stressLevel);
    final waterText = _formatWater(waterIntakeLiters);

    await _firestore
        .collection('consultations')
        .doc(consultationId)
        .collection('medical_notes')
        .add({
      'title': isEmergency ? 'Emergency Vitals Alert' : 'Vitals Update',
      'content':
      'Patient: $patientName\n'
          'HR: $heartRate bpm\n'
          'BP: $bp\n'
          'SpO₂: $spo2%\n'
          'Sleep: $sleepText\n'
          'Stress: $stressText\n'
          'Water: $waterText\n'
          '${reasons.join('\n')}',
      'patientId': patientId,
      'patientName': patientName,
      'heartRate': heartRate,
      'bp': bp,
      'spo2': spo2,
      'sleepMinutes': sleepMinutes,
      'stressLevel': stressLevel,
      'waterIntakeLiters': waterIntakeLiters,
      'reasons': reasons,
      'isEmergency': isEmergency,
      'autoGenerated': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> createEmergencyAlert({
    required String consultationId,
    required String patientId,
    required String patientName,
    required String doctorId,
    required String doctorName,
    required int heartRate,
    required String bp,
    required int spo2,
    int? sleepMinutes,
    int? stressLevel,
    double? waterIntakeLiters,
    required List<String> reasons,
  }) async {
    await _firestore.collection('emergency_alerts').add({
      'consultationId': consultationId,
      'patientId': patientId,
      'patientName': patientName,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'heartRate': heartRate,
      'bp': bp,
      'spo2': spo2,
      'sleepMinutes': sleepMinutes,
      'stressLevel': stressLevel,
      'waterIntakeLiters': waterIntakeLiters,
      'reasons': reasons,
      'status': 'open',
      'isReadByDoctor': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}