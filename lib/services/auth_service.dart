import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

// This service handles all authentication actions for the app.
// It also saves basic user information to Cloud Firestore after sign-up.
class AuthService {
  // This gives access to Firebase Authentication.
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // This gives access to Cloud Firestore.
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // This returns the currently signed-in user if one exists.
  User? get currentUser => _auth.currentUser;

  // This lets the app listen for login/logout changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // This saves a user's profile in Firestore if it does not already exist.
  Future<void> _saveUserToFirestore(User user, {String? fullName}) async {
    final userDoc = _firestore.collection('users').doc(user.uid);
    final docSnapshot = await userDoc.get();

    if (!docSnapshot.exists) {
      await userDoc.set({
        'uid': user.uid,
        'fullName': fullName?.trim().isNotEmpty == true
            ? fullName!.trim()
            : (user.displayName ?? ''),
        'email': user.email ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // This creates a new user account with email and password.
  // After creating the account, it also saves the user's details in Firestore.
  Future<String?> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password.trim(),
          );

      final User? user = userCredential.user;

      if (user != null) {
        await _saveUserToFirestore(user, fullName: fullName);
      }

      return null;
    } on FirebaseAuthException catch (e) {
      return 'FirebaseAuthException: ${e.code} - ${e.message}';
    } on FirebaseException catch (e) {
      return 'FirebaseException: ${e.code} - ${e.message}';
    } catch (e) {
      return 'Unexpected error: $e';
    }
  }

  // This signs in an existing user with email and password.
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      return null;
    } on FirebaseAuthException catch (e) {
      return 'FirebaseAuthException: ${e.code} - ${e.message}';
    } on FirebaseException catch (e) {
      return 'FirebaseException: ${e.code} - ${e.message}';
    } catch (e) {
      return 'Unexpected error: $e';
    }
  }

  // This signs in a user with Google and saves their profile in Firestore.
  Future<String?> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        return 'Google sign-in was cancelled.';
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      final User? user = userCredential.user;

      if (user != null) {
        await _saveUserToFirestore(user);
      }

      return null;
    } on FirebaseAuthException catch (e) {
      return 'FirebaseAuthException: ${e.code} - ${e.message}';
    } on FirebaseException catch (e) {
      return 'FirebaseException: ${e.code} - ${e.message}';
    } catch (e) {
      return 'Unexpected error: $e';
    }
  }

  // This signs out the currently logged-in user.
  Future<void> signOut() async {
    final GoogleSignIn googleSignIn = GoogleSignIn();
    await googleSignIn.signOut();
    await _auth.signOut();
  }
}
