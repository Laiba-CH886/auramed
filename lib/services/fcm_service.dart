import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:auramed/screens/consultation/consultation_chat_screen.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('🔔 Background message received: ${message.messageId}');
}

class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await _requestPermission();

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('🔔 Foreground message: ${message.messageId}');
      _showForegroundSnack(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('📲 Notification opened app: ${message.messageId}');
      _handleNotificationTap(message);
    });
  }

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: true,
      provisional: false,
      sound: true,
    );

    debugPrint('🔐 FCM permission status: ${settings.authorizationStatus}');
  }

  Future<String?> getToken() async {
    try {
      debugPrint('➡️ Trying to get FCM token...');
      final token = await _messaging.getToken();
      debugPrint('📱 FCM token: $token');
      return token;
    } catch (e) {
      debugPrint('❌ Error getting FCM token: $e');
      return null;
    }
  }

  Future<void> saveDoctorToken({
    required String doctorId,
    required String? doctorName,
  }) async {
    try {
      debugPrint('➡️ saveDoctorToken called for doctorId: $doctorId');

      final token = await getToken();

      if (token == null || token.isEmpty) {
        debugPrint('❌ Token is null or empty, not saving.');
        return;
      }

      await _firestore
          .collection('users')
          .doc(doctorId)
          .collection('fcm_tokens')
          .doc(token)
          .set({
        'token': token,
        'platform': 'android',
        'ownerRole': 'doctor',
        'ownerName': doctorName ?? 'Doctor',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _firestore.collection('users').doc(doctorId).set({
        'hasFcmToken': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('✅ Doctor FCM token saved successfully.');

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        try {
          debugPrint('♻️ Token refreshed: $newToken');

          await _firestore
              .collection('users')
              .doc(doctorId)
              .collection('fcm_tokens')
              .doc(newToken)
              .set({
            'token': newToken,
            'platform': 'android',
            'ownerRole': 'doctor',
            'ownerName': doctorName ?? 'Doctor',
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          await _firestore.collection('users').doc(doctorId).set({
            'hasFcmToken': true,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          debugPrint('✅ Refreshed FCM token saved successfully.');
        } catch (e) {
          debugPrint('❌ Error saving refreshed FCM token: $e');
        }
      });
    } catch (e) {
      debugPrint('❌ Error saving doctor FCM token: $e');
    }
  }

  Future<void> deleteDoctorToken({
    required String doctorId,
  }) async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) return;

      await _firestore
          .collection('users')
          .doc(doctorId)
          .collection('fcm_tokens')
          .doc(token)
          .delete();

      debugPrint('🗑️ Doctor FCM token deleted successfully.');
    } catch (e) {
      debugPrint('❌ Error deleting doctor FCM token: $e');
    }
  }

  void _showForegroundSnack(RemoteMessage message) {
    final context = appNavigatorKey.currentContext;
    if (context == null) return;

    final title = message.notification?.title ?? 'Notification';
    final body = message.notification?.body ?? 'You have a new alert';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title\n$body'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _handleNotificationTap(RemoteMessage message) {
    final navigator = appNavigatorKey.currentState;
    if (navigator == null) return;

    final data = message.data;
    final type = data['type']?.toString() ?? '';
    final consultationId = data['consultationId']?.toString() ?? '';
    final patientName = data['patientName']?.toString() ?? 'Patient';
    final doctorName = data['doctorName']?.toString() ?? 'Doctor';

    if (type == 'emergency_alert' && consultationId.isNotEmpty) {
      navigator.pushNamed(
        '/consultation-chat',
        arguments: ConsultationChatArgs(
          consultationId: consultationId,
          patientName: patientName,
          doctorName: doctorName,
          isActive: true,
          isDoctor: true,
        ),
      );
      return;
    }

    navigator.pushNamed('/doctor_dashboard');
  }
}