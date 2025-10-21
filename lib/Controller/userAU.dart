import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


enum UserRole { customer, seller }

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String _getCollectionName(UserRole role) {
    return role == UserRole.seller ? 'sellers' : 'customers';
  }

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
    required UserRole role,
    Map<String, dynamic>? additionalData,
  }) async {
    final collectionName = _getCollectionName(role);
    // User's UID as the document ID.
    return _db.collection(collectionName).doc(uid).set({
      'username': username,
      'phone_number': phoneNumber,
      'email': email,
      'role': role.name, 
      'created_at': FieldValue.serverTimestamp(),
      if(additionalData != null) ...additionalData
    });
  }

  Future<User?> signUp({
    required String email, 
    required String password,
    required String username,
    required String phoneNumber,
    required UserRole role,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      final user = userCredential.user;
      if(user != null){
        await _saveUserDetails(uid: user.uid, username: username, phoneNumber: phoneNumber, email: email, role: role, additionalData: additionalData);
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