import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Sign in with Email and Password
  Future<User?> signIn({
    required String email, 
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return userCredential.user;
    } on FirebaseAuthException {
      rethrow; 
    } catch (e) {
      throw Exception('An unexpected error occurred during sign-in.');
    }
  }

  Future<void> _saveUserDetails({
    required String uid,
    required String username,
    required String phoneNumber,
    required String email,
  }) async {
    // User's UID as the document ID.
    return _db.collection('users').doc(uid).set({
      'username': username,
      'phone_number': phoneNumber,
      'email': email,
      'role': 'customer', // Optional: useful for application logic
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  Future<User?> signUp({
    required String email, 
    required String password,
    required String username,
    required String phoneNumber,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      final user = userCredential.user;
      if(user != null){
        await _saveUserDetails(uid: user.uid, username: username, phoneNumber: phoneNumber, email: email);
      }
      return user;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw Exception('An unexpected error occurred during sign-up.');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}