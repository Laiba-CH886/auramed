import 'package:cloud_firestore/cloud_firestore.dart';

class ConsultationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Call this when a patient starts a consultation with a doctor
  /// (e.g. from BookAppointmentScreen or a "Start Consultation" button)
  static Future<String?> createConsultation({
    required String patientId,
    required String patientName,
    required String doctorId,
    required String doctorName,
  }) async {
    try {
      final ref = await _firestore.collection('consultations').add({
        'patientId': patientId,
        'patientName': patientName,
        'doctorId': doctorId,
        'doctorName': doctorName,
        'status': 'active',         // 'active' | 'completed'
        'lastMessage': '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return ref.id;
    } catch (e) {
      return null;
    }
  }

  /// Mark a consultation as completed
  static Future<void> completeConsultation(String consultationId) async {
    await _firestore.collection('consultations').doc(consultationId).update({
      'status': 'completed',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}