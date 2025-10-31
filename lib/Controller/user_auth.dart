// lib/Controller/user_auth.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:huawei_push/huawei_push.dart';

enum UserRole { customer, seller }

// Define a structure to hold the core status
class AuthStatus {
  final UserRole role;
  final bool? isVerified; // Primarily for sellers

  AuthStatus(this.role, {this.isVerified});
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  // --- END OF ADDED GETTER ---

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

  // Save User Details
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

  // Sign Up
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
       final userrole = role == UserRole.customer ? "customers" : "sellers";
       print("Role is $userrole");
       if(user != null){
        await _saveUserDetails(uid: user.uid, username: username, phoneNumber: phoneNumber, email: email, role: role, additionalData: additionalData);
        await _getCustomerDeviceToken(user.uid, userrole);
       }
       return user;
     } on FirebaseAuthException catch (e) { // <-- Catch the exception object 'e'
       return null; 
     } catch (e) {
       return null;
     }
   }

  // Sign Out
  Future<void> signOut() async {
     await _auth.signOut();
  }

  // Get User Auth Status (Role and Verification)
  Future<AuthStatus?> getUserAuthStatus(String uid) async {
     try {
       //Check the 'customers' collection
       final customerDoc = await _db.collection('customers').doc(uid).get();
       if (customerDoc.exists) {
         return AuthStatus(UserRole.customer);
       }

       //Check the 'sellers' collection
       final sellerDoc = await _db.collection('sellers').doc(uid).get();
       if (sellerDoc.exists) {
         final data = sellerDoc.data();
         // Default false
         final isVerified = data?['isVerified'] ?? false;
         // Return status
         return AuthStatus(
           UserRole.seller,
           isVerified: isVerified,
         );
       }

       // User exists in Auth but not in a role collection (should ideally not happen)
       print("Warning: User $uid exists in Auth but not in 'customers' or 'sellers' collection.");
       return null;

     } catch (e) {
       print("Error fetching user status for $uid: $e");
       return null;
     }
  }

  // (Optional but recommended) Get Current User Synchronously
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  //Store user device token for push notification
  Future<void> _getCustomerDeviceToken(String userId, String role) async {
  try {
    print("🔥 Fetching HMS token...");
    Push.getTokenStream.listen((String? token) {
      if (token != null) {
        print('Device token: $token');
        //Update customer/seller with device token
        FirebaseFirestore.instance
            .collection(role)
            .doc(userId)         
            .set({'hmsPushToken': token}, SetOptions(merge: true));
      }
    });

    Push.getToken("");

  } catch (e) {
    print("Failed to get device token: $e");
  }
}
}