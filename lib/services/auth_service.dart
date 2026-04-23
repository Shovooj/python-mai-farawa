import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// This service handles all authentication actions for the app.
// It also saves basic user information to Cloud Firestore after sign-up.
class AuthService {
  // This gives access to Firebase Authentication.
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // This gives access to Cloud Firestore.
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // This returns the currently signed-in user if one exists.
  User? get currentUser => _auth.currentUser;

  // This creates a new user account with email and password.
  // After creating the account, it also saves the user's details in Firestore.
  Future<String?> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      // Create the user account in Firebase Authentication.
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password.trim(),
          );

      final User? user = userCredential.user;

      // If the user was created successfully, save their profile in Firestore.
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'fullName': fullName.trim(),
          'email': email.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // Return null to show that sign-up was successful.
      return null;
    } on FirebaseAuthException catch (e) {
      // Return the exact Firebase Authentication error.
      return 'FirebaseAuthException: ${e.code} - ${e.message}';
    } on FirebaseException catch (e) {
      // Return Firestore or other Firebase-related errors.
      return 'FirebaseException: ${e.code} - ${e.message}';
    } catch (e) {
      // Return any other unexpected error in full.
      return 'Unexpected error: $e';
    }
  }

  // This signs in an existing user with email and password.
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // Sign in the user with Firebase Authentication.
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      // Return null to show that login was successful.
      return null;
    } on FirebaseAuthException catch (e) {
      // Return the exact Firebase Authentication error.
      return 'FirebaseAuthException: ${e.code} - ${e.message}';
    } on FirebaseException catch (e) {
      // Return any Firebase-related error.
      return 'FirebaseException: ${e.code} - ${e.message}';
    } catch (e) {
      // Return any other unexpected error in full.
      return 'Unexpected error: $e';
    }
  }

  // This signs out the currently logged-in user.
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
