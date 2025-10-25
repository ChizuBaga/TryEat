import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chikankan/locator.dart'; // Import locator
import 'package:chikankan/Controller/user_auth.dart'; // Import AuthService
import 'package:chikankan/Model/item_model.dart';
import 'package:chikankan/Model/cart_model.dart';
import 'package:firebase_auth/firebase_auth.dart';


class CartService{
  final FirebaseFirestore _firestore = locator<FirebaseFirestore>();
  final AuthService _authService = locator<AuthService>();

  // Helper to get the current user's cart collection reference
  CollectionReference? _getCartCollectionRef() {
    
    final User? user = _authService.getCurrentUser(); // Use the service method
    if (user == null) {
      print("Error: User not logged in (CartService).");
      return null;
    }
    return _firestore.collection('customers').doc(user.uid).collection('cart');
  }

  // --- addItem ---
  Future<void> addItem(Item item, int quantity) async {
    final cartRef = _getCartCollectionRef(); // Uses the updated helper
    if (cartRef == null) return;
    // The document ID in the cart subcollection IS the item's ID
    final docRef = cartRef.doc(item.id);
    
    try {
      // Use a transaction for safe quantity updates
      await _firestore.runTransaction((transaction) async {
        final docSnapshot = await transaction.get(docRef);

        if (docSnapshot.exists) {
          // Item exists, update quantity
          final existingData = docSnapshot.data() as Map<String, dynamic>?;
          final existingQuantity = existingData?['quantity'] ?? 0;
          transaction.update(docRef, {'quantity': existingQuantity + quantity});
        } else {
          // Item doesn't exist, create it using CartItem's toMap
          // Create a temporary CartItem object to leverage its toMap method
          final newCartItem = CartItem(
            id: item.id, // Corresponds to Firestore doc ID
            name: item.name,
            price: item.price,
            imageUrl: item.imageUrl,
            quantity: quantity,
            deliveryMode: item.deliveryMode
          );
          transaction.set(docRef, newCartItem.toMap());
        }
      });
      print("Item ${item.id} added/updated in cart.");
    } catch (e) {
      print("Error adding item to cart: $e");
      // Optionally rethrow or handle error
    }
  }

  // --- removeItem ---
  Future<void> removeItem(String itemId) async {
    final cartRef = _getCartCollectionRef(); // Uses the updated helper
    if (cartRef == null) return;
    try {
      await cartRef.doc(itemId).delete();
      print("Item $itemId removed from cart.");
    } catch (e) {
      print("Error removing item from cart: $e");
    }
  }

  // --- clearCart ---
  Future<void> clearCart() async {
    final cartRef = _getCartCollectionRef(); // Uses the updated helper
    if (cartRef == null) return;
    try {
      final QuerySnapshot snapshot = await cartRef.get();
      // Use batch write for efficiency
      final WriteBatch batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      print("Cart cleared.");
    } catch (e) {
      print("Error clearing cart: $e");
    }
  }

  // --- getCartStream ---
  Stream<QuerySnapshot>? getCartStream() {
    final cartRef = _getCartCollectionRef(); // Uses the updated helper
    return cartRef?.snapshots();
  }
}