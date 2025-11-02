import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProfileController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<DocumentSnapshot> streamSellerProfile() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    
    if (uid == null) {
      return Stream.error('User not logged in or UID is null.');
    }

    return _firestore.collection('sellers').doc(uid).snapshots();
  }

  Future<String?> uploadProfileImage(File newImage, String userId) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('user_profile')
          .child('${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg');
      
      final uploadTask = storageRef.putFile(newImage);
      final snapshot = await uploadTask.whenComplete(() => {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading profile image: $e');
      return null;
    }
  }

  Future<void> deleteOldProfileImage(String? oldImageUrl) async {
    if (oldImageUrl == null || oldImageUrl.isEmpty || !oldImageUrl.contains('firebasestorage.googleapis.com')) {
      return;
    }
    try {
      final ref = FirebaseStorage.instance.refFromURL(oldImageUrl);
      await ref.delete();
      print('Old profile image deleted from Storage: $oldImageUrl');
    } catch (e) {
      print('Error deleting old profile image from Storage: $e');
    }
  }

  Future<void> updateProfile({
    required String userId,
    required Map<String, dynamic> updateData,
  }) async {
    await _firestore.collection('sellers').doc(userId).update(updateData);
  }
}