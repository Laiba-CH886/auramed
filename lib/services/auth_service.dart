// auth_service.dart - DEBUG VERSION
// Replace with this temporarily to see exact error in console

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Email / Password Sign-In ──────────────────────────────────────────────
  Future<Map<String, dynamic>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    // ── DEBUG: print exactly what we receive ──
    print('=== LOGIN ATTEMPT ===');
    print('Email: "$email"');
    print('Password length: ${password.length}');
    print('Email trimmed: "${email.trim()}"');

    try {
      print('Calling Firebase signInWithEmailAndPassword...');

      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      print('Firebase Auth SUCCESS');
      print('UID: ${credential.user?.uid}');
      print('Email verified: ${credential.user?.emailVerified}');

      final user = credential.user;
      if (user == null) {
        print('ERROR: user is null after successful auth');
        return {'success': false, 'message': 'Sign-in failed. Please try again.'};
      }

      print('Fetching Firestore role for uid: ${user.uid}');
      final role = await _getUserRole(user.uid);
      print('Role from Firestore: "$role"');

      if (role == 'unknown') {
        print('ERROR: role is unknown — Firestore doc missing or no role field');
        await _auth.signOut();
        return {
          'success': false,
          'message': 'Your account profile is incomplete. Please sign up again.',
        };
      }

      print('=== LOGIN SUCCESS, role: $role ===');

      _sendLoginNotificationEmail(
        toEmail: user.email ?? email,
        role: role,
        loginMethod: 'Email & Password',
      );

      return {'success': true, 'role': role, 'uid': user.uid};

    } on FirebaseAuthException catch (e) {
      // ── DEBUG: print full Firebase error ──
      print('=== FIREBASE AUTH ERROR ===');
      print('Code: ${e.code}');
      print('Message: ${e.message}');
      print('Details: ${e.toString()}');
      return {'success': false, 'message': _friendlyAuthError(e)};

    } catch (e, stackTrace) {
      // ── DEBUG: print unexpected error ──
      print('=== UNEXPECTED ERROR ===');
      print('Error: $e');
      print('StackTrace: $stackTrace');
      return {
        'success': false,
        'message': 'Unexpected error: ${e.toString()}',
      };
    }
  }

  // ── Google Sign-In ────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> signInWithGoogle({required String role}) async {
    try {
      await _googleSignIn.signOut();
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return {'success': false, 'message': 'Sign in canceled'};
      }

      GoogleSignInAuthentication googleAuth;
      try {
        googleAuth = await googleUser.authentication;
      } on TypeError catch (typeError) {
        return {
          'success': false,
          'message': 'Google Sign-In failed due to a plugin compatibility issue. '
              'Please update the app or use Email login. (Detail: $typeError)',
        };
      }

      final oauthCredential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(oauthCredential);
      final user = userCredential.user;
      if (user == null) {
        return {'success': false, 'message': 'Google sign-in failed. Please try again.'};
      }

      final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;
      String resolvedRole;

      if (isNewUser) {
        resolvedRole = role;
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email ?? '',
          'name': user.displayName ?? '',
          'photoUrl': user.photoURL ?? '',
          'role': role,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
          'authProvider': 'google',
        });
      } else {
        resolvedRole = await _getUserRole(user.uid);
        if (resolvedRole == 'unknown') {
          resolvedRole = role;
          await _firestore.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'email': user.email ?? '',
            'name': user.displayName ?? '',
            'photoUrl': user.photoURL ?? '',
            'role': role,
            'createdAt': FieldValue.serverTimestamp(),
            'lastLoginAt': FieldValue.serverTimestamp(),
            'authProvider': 'google',
          });
        } else {
          await _firestore.collection('users').doc(user.uid).update({
            'lastLoginAt': FieldValue.serverTimestamp(),
          });
        }
      }

      _sendLoginNotificationEmail(
        toEmail: user.email ?? '',
        role: resolvedRole,
        loginMethod: 'Google Sign-In',
      );

      return {
        'success': true,
        'role': resolvedRole,
        'isNewUser': isNewUser,
        'uid': user.uid,
      };
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _friendlyAuthError(e)};
    } on TypeError catch (typeError) {
      return {
        'success': false,
        'message': 'Google Sign-In failed due to a plugin compatibility issue. '
            'Please use Email login or update the app. (Detail: $typeError)',
      };
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('ApiException: 10') || msg.contains('sign_in_failed')) {
        return {
          'success': false,
          'message': 'Google Sign-In is not configured. Please add SHA-1 to Firebase.',
        };
      }
      return {'success': false, 'message': 'Google sign-in failed: $msg'};
    }
  }

  // ── Password Reset ────────────────────────────────────────────────────────
  Future<void> sendPasswordResetEmail({required String email}) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  // ── Sign Out ──────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // ── Get User Role ─────────────────────────────────────────────────────────
  Future<String> _getUserRole(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      print('Firestore doc exists: ${doc.exists}');
      if (doc.exists) {
        print('Firestore doc data: ${doc.data()}');
        return doc.data()?['role'] as String? ?? 'unknown';
      }
      return 'unknown';
    } catch (e) {
      print('Firestore error: $e');
      return 'unknown';
    }
  }

  // ── Login Notification Email ──────────────────────────────────────────────
  void _sendLoginNotificationEmail({
    required String toEmail,
    required String role,
    required String loginMethod,
  }) {
    if (toEmail.isEmpty) return;
    final roleName = role[0].toUpperCase() + role.substring(1);
    final now = DateTime.now().toUtc();
    final timeStr = '${now.year}-${_pad(now.month)}-${_pad(now.day)} '
        '${_pad(now.hour)}:${_pad(now.minute)} UTC';

    _firestore.collection('mail').add({
      'to': [toEmail],
      'message': {
        'subject': '🔐 AuraMed — New login to your account',
        'html': '''
<!DOCTYPE html>
<html>
<body style="margin:0;padding:0;background:#f4f4f4;font-family:Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0">
    <tr><td align="center" style="padding:40px 0;">
      <table width="560" cellpadding="0" cellspacing="0"
             style="background:#fff;border-radius:12px;overflow:hidden;
                    box-shadow:0 2px 8px rgba(0,0,0,0.08);">
        <tr>
          <td style="background:linear-gradient(135deg,#6200EE,#03DAC5);
                      padding:32px;text-align:center;">
            <h1 style="margin:0;color:#fff;font-size:24px;font-weight:bold;">
              🏥 AuraMed
            </h1>
            <p style="margin:8px 0 0;color:rgba(255,255,255,0.85);font-size:14px;">
              Login Security Alert
            </p>
          </td>
        </tr>
        <tr>
          <td style="padding:32px;">
            <h2 style="margin:0 0 8px;color:#212121;font-size:18px;">
              New Login Detected
            </h2>
            <p style="margin:0 0 24px;color:#555;font-size:14px;line-height:1.6;">
              A successful login was made to your AuraMed <strong>$roleName</strong> account.
            </p>
            <table width="100%" cellpadding="0" cellspacing="0"
                   style="background:#f8f8f8;border-radius:8px;overflow:hidden;">
              <tr><td style="padding:12px 16px;border-bottom:1px solid #eee;">
                <span style="color:#888;font-size:12px;">ACCOUNT</span><br/>
                <strong style="color:#212121;font-size:14px;">$toEmail</strong>
              </td></tr>
              <tr><td style="padding:12px 16px;border-bottom:1px solid #eee;">
                <span style="color:#888;font-size:12px;">METHOD</span><br/>
                <strong style="color:#212121;font-size:14px;">$loginMethod</strong>
              </td></tr>
              <tr><td style="padding:12px 16px;">
                <span style="color:#888;font-size:12px;">TIME</span><br/>
                <strong style="color:#212121;font-size:14px;">$timeStr</strong>
              </td></tr>
            </table>
            <table width="100%" cellpadding="0" cellspacing="0"
                   style="margin-top:24px;background:#FFF3E0;border-radius:8px;
                          border-left:4px solid #FF9800;">
              <tr><td style="padding:16px;">
                <p style="margin:0;color:#E65100;font-size:13px;line-height:1.5;">
                  ⚠️ <strong>Wasn't you?</strong> Contact
                  <a href="mailto:support@auramed.example" style="color:#E65100;">
                    support immediately
                  </a> and change your password.
                </p>
              </td></tr>
            </table>
          </td>
        </tr>
        <tr>
          <td style="padding:20px 32px;background:#fafafa;
                      border-top:1px solid #eee;text-align:center;">
            <p style="margin:0;color:#aaa;font-size:12px;">
              Automated security notification from AuraMed. Do not reply.
            </p>
          </td>
        </tr>
      </table>
    </td></tr>
  </table>
</body>
</html>''',
      },
      'createdAt': FieldValue.serverTimestamp(),
    }).catchError((_) {});
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  String _friendlyAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email. Please sign up first.';
      case 'wrong-password':
        return 'Incorrect password. Please try again or use Forgot Password.';
      case 'invalid-credential':
        return 'Incorrect email or password. Please check and try again.';
      case 'invalid-email':
        return 'The email address format is not valid.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please wait a moment and try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password is too weak. Please use at least 6 characters.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled. Contact support.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'account-exists-with-different-credential':
        return 'An account exists with this email using a different sign-in method.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }
}