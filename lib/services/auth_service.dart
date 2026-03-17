import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

const String adminPassword = 'finsheAdmin@123';

/// Web client ID (type 3) - must match the one in your android/app/google-services.json (oauth_client where client_type: 3).
const String _webClientId = '1097114677782-o7n2c75bv0b1ffvmjgpl8sa5lje4l4bh.apps.googleusercontent.com';

/// Build troubleshooting message for Google Sign-In failures.
String buildGoogleSignInHelp(String? errorCode, String? rawMessage) {
  final code = errorCode ?? 'unknown';
  final sb = StringBuffer('Google Sign-In failed');
  if (code != 'unknown') sb.write(' (Error $code)');
  sb.write('.\n\n');
  if (code == '10' || code == '10:') {
    sb.writeln('SHA-1 still not accepted. Do this exactly:');
    sb.writeln('1. In project folder run: cd android && gradlew signingReport');
    sb.writeln('   (Or: keytool -list -v -keystore %USERPROFILE%\\.android\\debug.keystore -alias androiddebugkey -storepass android)');
    sb.writeln('2. Copy the SHA-1 line (e.g. A1:B2:C3:...).');
    sb.writeln('3. Firebase Console → Project settings (gear) → Your apps → Android app → Add fingerprint → paste SHA-1 and SHA-256.');
    sb.writeln('4. Download the NEW google-services.json and REPLACE android/app/google-services.json completely.');
    sb.writeln('5. In Firebase: Authentication → Sign-in method → enable "Google".');
    sb.writeln('6. Run: flutter clean');
    sb.writeln('7. Run: flutter run');
    sb.writeln('\nAlso: Uninstall the app from the device and install again after step 7.');
  } else {
    sb.writeln('Error code: $code');
    if (rawMessage != null && rawMessage.isNotEmpty) sb.writeln('Details: $rawMessage');
    sb.writeln('\nCheck: Firebase → Authentication → Sign-in method → Google is enabled.');
    sb.writeln('Check: android/app/google-services.json is the file you downloaded after adding SHA-1.');
  }
  return sb.toString();
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: _webClientId,
    scopes: ['email', 'profile'],
  );

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Last sign-in error message (for UI).
  String? lastError;

  /// Google Sign-In for users.
  Future<UserModel?> signInWithGoogle() async {
    lastError = null;
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      if (googleAuth.idToken == null) {
        lastError = 'Google Sign-In did not return an id token. '
            'Ensure the Web Client ID in Firebase (client_type 3 in google-services.json) is correct and SHA-1 is added.';
        return null;
      }
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCred = await _auth.signInWithCredential(credential);
      final fbUser = userCred.user;
      if (fbUser == null) return null;

      final userDoc = await _firestore.collection('users').doc(fbUser.uid).get();
      final lastLogin = DateTime.now().toIso8601String();

      if (userDoc.exists && userDoc.data() != null) {
        await _firestore.collection('users').doc(fbUser.uid).update({'lastLoginDate': lastLogin});
        return UserModel.fromMap(fbUser.uid, userDoc.data()!);
      }

      final newUser = UserModel(
        uid: fbUser.uid,
        name: fbUser.displayName ?? 'User',
        email: fbUser.email ?? '',
        role: 'user',
        lastLoginDate: lastLogin,
      );
      await _firestore.collection('users').doc(fbUser.uid).set(newUser.toMap());
      return newUser;
    } catch (e, st) {
      String? errorCode;
      String? errorMessage;
      if (e is PlatformException) {
        errorCode = e.code;
        errorMessage = e.message;
      }
      final msg = e.toString();
      if (msg.contains('ApiException: 10') || msg.contains('sign_in_failed') || errorCode == '10' || errorCode == 'sign_in_failed') {
        lastError = kIsWeb ? 'Google Sign-In failed. Check OAuth config.' : buildGoogleSignInHelp(errorCode ?? '10', errorMessage);
      } else {
        lastError = buildGoogleSignInHelp(errorCode, errorMessage ?? msg);
      }
      if (kDebugMode) debugPrint('Google Sign-In error: $e\ncode=$errorCode message=$errorMessage\n$st');
      rethrow;
    }
  }

  /// Admin login: password must be finsheAdmin@123, then signs in with Firebase Email/Password.
  /// Create the admin user in Firebase Console (Authentication → Add user) with this password.
  Future<UserModel?> signInAsAdmin({
    required String email,
    required String password,
  }) async {
    lastError = null;
    if (password != adminPassword) {
      lastError = 'Invalid Admin Password';
      return null;
    }
    try {
      final userCred = await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
      final fbUser = userCred.user;
      if (fbUser == null) return null;

      final lastLogin = DateTime.now().toIso8601String();
      final userDoc = await _firestore.collection('users').doc(fbUser.uid).get();

      if (userDoc.exists && userDoc.data() != null) {
        await _firestore.collection('users').doc(fbUser.uid).update({'lastLoginDate': lastLogin});
        return UserModel.fromMap(fbUser.uid, userDoc.data()!);
      }

      final admin = UserModel(
        uid: fbUser.uid,
        name: fbUser.displayName ?? 'Admin',
        email: fbUser.email ?? email,
        role: 'admin',
        lastLoginDate: lastLogin,
      );
      await _firestore.collection('users').doc(fbUser.uid).set(admin.toMap());
      return admin;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        lastError = 'Invalid Admin Password';
      } else {
        lastError = e.message ?? e.code;
      }
      return null;
    } catch (e) {
      lastError = e.toString();
      return null;
    }
  }

  /// Get current user profile from Firestore (for users signed in with Google).
  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return UserModel.fromMap(doc.id, doc.data()!);
    }
    return null;
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
