import 'package:cloud_firestore/cloud_firestore.dart';

class CartItem {
  final String id;
  final String name;
  final double price;
  final String imageUrl;
  final int quantity;
  final String deliveryMode;
  final String sellerId;
  // bool isSelected; //multiple item

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.quantity,
    required this.deliveryMode,
    required this.sellerId,
    // this.isSelected = false,
  });

  // Factory constructor to create a CartItem from a Firestore document
  factory CartItem.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CartItem(
      id: doc.id, // Use the document ID as the CartItem ID
      name: data['itemName'] ?? 'Unknown Item', // Field names in cart doc
      price: (data['itemPrice'] ?? 0.0).toDouble(),
      imageUrl: data['itemImageUrl'] ?? '',
      quantity: data['quantity'] ?? 1,
      deliveryMode: data['deliveryMode'],
      sellerId: data['sellerId'],
    );
  }

  // Method to convert a CartItem object into a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      // Don't store 'id' inside the document data itself
      'itemName': name,
      'itemPrice': price,
      'itemImageUrl': imageUrl,
      'quantity': quantity,
      'deliveryMode': deliveryMode,
      'sellerId': sellerId,
      // You might add a timestamp here if needed
      // 'addedAt': FieldValue.serverTimestamp(),
    };
  }
}