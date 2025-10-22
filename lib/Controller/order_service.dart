import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chikankan/Model/order_model.dart';

class OrderService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String? _currentSellerId = FirebaseAuth.instance.currentUser?.uid;

  // Stream current orders relevant to the logged-in seller
  Stream<List<Orders>> streamCurrentOrders() {
    if (_currentSellerId == null) {
      return Stream.value([]); // Return empty stream if no user is logged in
    }

    return _db
        .collection('orders')
        // ⭐️ Filter orders where seller_ID matches the logged-in user's UID
        .where('seller_ID', isEqualTo: _currentSellerId)
        // ⭐️ Optional: Add a filter for status if you only want 'Preparing', 'Ready for Pickup', etc.
        // .where('orderStatus', isNotEqualTo: 'Completed')
        .snapshots()
        .map((snapshot) {
      // Map the Firestore documents to your Order model
      return snapshot.docs.map((doc) => Orders.fromFirestore(doc)).toList();
    });
  }
}