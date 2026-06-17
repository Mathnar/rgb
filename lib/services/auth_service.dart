import 'dart:io' show Platform;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Auth strategy optimized for casual games:
///  - Every player starts ANONYMOUS (zero friction, instant play).
///  - They can later UPGRADE that same account to Email/Google/Apple to keep
///    their progress across devices, without losing their score history.
class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _google = GoogleSignIn();

  User? get user => _auth.currentUser;
  bool get isSignedIn => _auth.currentUser != null;
  bool get isAnonymous => _auth.currentUser?.isAnonymous ?? true;
  String get uid => _auth.currentUser?.uid ?? '';

  AuthService() {
    _auth.authStateChanges().listen((_) => notifyListeners());
  }

  /// Call once at boot so the player can play immediately.
  Future<void> ensureSignedIn() async {
    if (_auth.currentUser == null) {
      await _auth.signInAnonymously();
    }
  }

  Future<void> signOut() async {
    await _google.signOut();
    await _auth.signOut();
    // Drop straight back into an anonymous session so the game still works.
    await ensureSignedIn();
  }

  Future<void> setDisplayName(String name) async {
    await _auth.currentUser?.updateDisplayName(name.trim());
    await _auth.currentUser?.reload();
    notifyListeners();
  }

  /// Links credentials to the current (anonymous) user when possible so the
  /// player keeps their uid; falls back to a plain sign-in otherwise.
  Future<void> _linkOrSignIn(AuthCredential cred) async {
    final current = _auth.currentUser;
    try {
      if (current != null && current.isAnonymous) {
        await current.linkWithCredential(cred);
      } else {
        await _auth.signInWithCredential(cred);
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use' ||
          e.code == 'email-already-in-use') {
        await _auth.signInWithCredential(cred);
      } else {
        rethrow;
      }
    }
    notifyListeners();
  }

  Future<void> signInWithEmail(String email, String password) async {
    final cred = EmailAuthProvider.credential(
      email: email.trim(),
      password: password,
    );
    final current = _auth.currentUser;
    try {
      if (current != null && current.isAnonymous) {
        await current.linkWithCredential(cred);
      } else {
        await _auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        // First time with this email -> create the account.
        await _auth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
      } else if (e.code == 'email-already-in-use' ||
          e.code == 'credential-already-in-use') {
        await _auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
      } else {
        rethrow;
      }
    }
    notifyListeners();
  }

  Future<void> signInWithGoogle() async {
    final account = await _google.signIn();
    if (account == null) return; // user cancelled
    final auth = await account.authentication;
    final cred = GoogleAuthProvider.credential(
      accessToken: auth.accessToken,
      idToken: auth.idToken,
    );
    await _linkOrSignIn(cred);
  }

  bool get appleAvailable => !kIsWeb && Platform.isIOS;

  Future<void> signInWithApple() async {
    final apple = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );
    final cred = OAuthProvider('apple.com').credential(
      idToken: apple.identityToken,
      accessToken: apple.authorizationCode,
    );
    await _linkOrSignIn(cred);
    if (apple.givenName != null) {
      await setDisplayName(apple.givenName!);
    }
  }
}
