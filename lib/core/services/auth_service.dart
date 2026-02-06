import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/gmail/v1.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Explicitly defining all necessary scopes for Gmail access
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
      // Force account selection to refresh token and permissions
      await _googleSignIn.signOut();
      
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        if (onError != null) onError('Sign-in cancelled');
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
      if (onError != null) onError(e.toString());
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<Map<String, String>?> getAuthHeaders() async {
    GoogleSignInAccount? user = _googleSignIn.currentUser;
    // Attempt to refresh user session silently if null
    user ??= await _googleSignIn.signInSilently();
    
    if (user == null) {
      debugPrint('AUTH SERVICE: No user found for headers');
      return null;
    }
    return await user.authHeaders;
  }
}
