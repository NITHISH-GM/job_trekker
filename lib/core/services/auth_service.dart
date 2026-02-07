import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/gmail/v1.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  static const List<String> _scopes = [
    'https://www.googleapis.com/auth/gmail.readonly',
    'email',
    'profile',
    'openid',
  ];

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '262880009344-hipvqdeec162msq0lhn2g2q665ft097o.apps.googleusercontent.com',
    scopes: _scopes,
  );

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential?> signInWithGoogle({Function(String)? onError}) async {
    try {
      // Clear previous session to ensure fresh scopes
      await _googleSignIn.signOut();
      
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        if (onError != null) onError('Sign-in was cancelled.');
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      debugPrint('AUTH ERROR: $e');
      if (onError != null) onError('Authentication failed: ${e.toString()}');
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      debugPrint('LOGOUT ERROR: $e');
    }
  }

  Future<Map<String, String>?> getAuthHeaders() async {
    try {
      GoogleSignInAccount? user = _googleSignIn.currentUser;
      
      // Attempt silent sign in to refresh the token if it's expired
      user ??= await _googleSignIn.signInSilently();
      
      if (user == null) {
        debugPrint('AUTH SERVICE: No active user session found.');
        return null;
      }
      
      final headers = await user.authHeaders;
      debugPrint('AUTH SERVICE: Successfully retrieved auth headers.');
      return headers;
    } catch (e) {
      debugPrint('AUTH HEADER ERROR: $e');
      return null;
    }
  }
}
