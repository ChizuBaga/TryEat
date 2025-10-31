import 'package:chikankan/Model/orderItem_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chikankan/Model/order_model.dart';

class OrderController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String? _currentSellerId = FirebaseAuth.instance.currentUser?.uid;

  // Stream current orders relevant to the logged-in seller
  Stream<List<Orders>> streamCurrentOrders() {
    if (_currentSellerId == null) {
      return Stream.value([]); 
    }

    return _db
        .collection('orders')
        .where('seller_ID', isEqualTo: _currentSellerId)
        .where('orderStatus', whereIn: ['Preparing', 'Ready for Pickup'])
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Orders.fromFirestore(doc)).toList();
    });
  }
  
  // seller_current_orders.dart
  // Fetches detailed information for a single item ID
  Future<Map<String, dynamic>?> getItemDetails(String itemId) async {
    try {
      final doc = await _db.collection('items').doc(itemId).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      print("Error fetching item $itemId details: $e");
      return null;
    }
  }

  // Fetches all item details for a list of OrderItem objects
  Future<List<OrderItemDisplay>> getDetailedOrderItems(List<OrderItem> orderItems) async {
    final List<Future<OrderItemDisplay>> futures = orderItems.map((orderItem) async {
      final itemData = await getItemDetails(orderItem.itemId);
      return OrderItemDisplay(
        itemId: orderItem.itemId,
        quantity: orderItem.quantity,
        name: itemData?['Name'] ?? 'Unknown',
        imageUrl: itemData?['imageUrl'],
        price: itemData?['Price'],
      );
    }).toList();

    return Future.wait(futures);
  }

  //Pending Order
  Stream<List<Orders>> streamPendingOrders() {
    if (_currentSellerId == null) {
      return Stream.value([]); // Return empty stream if no user is logged in
    }

    return _db
        .collection('orders')
        .where('seller_ID', isEqualTo: _currentSellerId)
        .where('orderStatus', isEqualTo: 'Pending')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Orders.fromFirestore(doc)).toList();
    });
  }

  Stream<int> streamPendingOrderCount() {
    final currentSellerId = FirebaseAuth.instance.currentUser?.uid;
    
    if (currentSellerId == null) {
      return Stream.value(0);
    }

    return _db
        .collection('orders')
        .where('seller_ID', isEqualTo: currentSellerId) 
        .where('orderStatus', isEqualTo: 'Placed') 
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.length;
        });
  }

  // seller_dashboard.dart
  Stream<List<Orders>> streamCompletedOrders() {
    if (_currentSellerId == null) {
      return Stream.value([]); // Return empty stream if no user is logged in
    }

    return _db
        .collection('orders')
        .where('seller_ID', isEqualTo: _currentSellerId)
        .where('orderStatus', isEqualTo: 'Completed')
        .orderBy('completedAt')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Orders.fromFirestore(doc)).toList();
    });
  }
}