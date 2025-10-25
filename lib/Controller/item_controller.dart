// File: item_service.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ItemController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  //add_item.dart
  //Upload Image
  Future<String?> uploadImage(File selectedImage) async {
    try {
      final storageRef = _storage
          .ref()
          .child('item_images')
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
      
      final uploadTask = storageRef.putFile(selectedImage);
      final snapshot = await uploadTask.whenComplete(() => {});
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Service Error (Image Upload): $e');
      return null;
    }
  }

  // Save Item Details 
  Future<bool> saveItemDetails({
    required String sellerId,
    required String itemName,
    required double itemPrice,
    required String itemCategory,
    required String itemDescription,
    required String orderType,
    required String deliveryMode,
    required int reservedDays,
    String? imageUrl,
  }) async {
    try {
      await _firestore.collection('items').add({
        'Name': itemName,
        'Price': itemPrice,
        'Category': itemCategory,
        'Description': itemDescription,
        'imageUrl': imageUrl, 
        'isAvailable': true,
        'sellerId': sellerId,
        'createdAt': FieldValue.serverTimestamp(),
        'OrderType': orderType,
        'DeliveryMode': deliveryMode,
        'ReservedDays': orderType == 'Pre-order' ? reservedDays : 0, // Only save days if Pre-order
      });
      return true; // Success
    } catch (e) {
      print('Service Error (Firestore Save): $e');
      return false; // Failure
    }
  }

  //edit_item.dart
  Future<String?> uploadNewImage(File? newSelectedImage) async {
    if (newSelectedImage == null) return null; // No new image to upload

    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('item_images')
          .child('${DateTime.now().millisecondsSinceEpoch}_${newSelectedImage.path.split('/').last}');
      
      final uploadTask = storageRef.putFile(newSelectedImage);
      final snapshot = await uploadTask.whenComplete(() => {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Service Error (Image Upload): $e');
      return null;
    }
  }

  Future<void> updateItem({
    required String itemId,
    required Map<String, dynamic> updateItems,
  }) async {
    await _firestore.collection('items').doc(itemId).update(updateItems); 
  }

  Future<void> deleteOldImage(String? oldImageUrl) async {
    if (oldImageUrl == null || oldImageUrl.isEmpty) return;
    if (!oldImageUrl.contains('firebasestorage.googleapis.com')) return; // Not a Firebase Storage URL

    try {
      final ref = FirebaseStorage.instance.refFromURL(oldImageUrl);
      await ref.delete();
    } catch (e) {
      print('Error deleting old image from Storage: $e');
    }
  }

  Future<bool> deleteItem(String itemId, String? imageUrl) async {
    try {
      await deleteOldImage(imageUrl); //Delete image in firebase storage

      // Delete document from Firestore
      await _firestore.collection('items').doc(itemId).delete();
      
      return true; // Success
    } catch (e) {
      print('Service Error (Delete Item): $e');
      return false; // Failure
    }
  }

}