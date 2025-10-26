import 'package:chikankan/Model/order_model_temp.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth
import 'package:chikankan/locator.dart';
import 'package:chikankan/Model/item_model.dart'; // Import Item model

class CustomerOrderController {
  final FirebaseFirestore _firestore = locator<FirebaseFirestore>();
  
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<List<Orders>> fetchCustomerOrders(String customerId) async {
    QuerySnapshot querySnapshot = await _firestore
        .collection('orders')
        .where('customer_ID', isEqualTo: customerId)
        // Optionally order by creation date
        .orderBy('createdAt', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) => Orders.fromFirestore(doc))
        .toList();
  }

  Future<String?> placeOrder({
    required Item item,
    required int quantity,
  }) async {
    // 1. Get the current logged-in customer's ID
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      print("Error placing order: User not logged in.");
      return null; // Can't place order without a user
    }
    final String customerId = currentUser.uid;

    // 2. Extract necessary info from the Item object
    // Assuming 'item.id' is the Firestore document ID for the item
    final String itemId = item.id;
    // Assuming your Item model now includes sellerId
    final String? sellerId = item.sellerId;

    if (sellerId == null || sellerId.isEmpty) {
      print("Error placing order: Seller ID is missing in the item data.");
      return null; // Can't place order without seller info
    }

    // 3. Calculate the total price
    final double total = item.price * quantity;

    final Orders newOrder = Orders(
      item.name,
      Timestamp(0, 0),
      Timestamp(0, 0), 
      'Placed', 
      createdAt: Timestamp.now(), // Use current time for creation
      customerId: customerId,
      sellerId: sellerId,
      itemId: itemId,
      total: total,
      quantity: quantity,
    );

    try {
      // 5. Add the order to the 'orders' collection
      DocumentReference docRef =
          await _firestore.collection('orders').add(newOrder.toMap());

      print("Order placed successfully with ID: ${docRef.id}");
      return docRef.id; // Return the new order ID on success
    } catch (e) {
      print("Error placing order in Firestore: $e");
      return null; // Return null on failure
    }
  }
  
}