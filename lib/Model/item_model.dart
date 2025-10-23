import 'package:cloud_firestore/cloud_firestore.dart';

class Item {
  String id;
  String name;
  double price;
  String category;
  String description;
  String imageUrl;
  bool isAvailable;
  String orderType;
  String deliveryMode;
  int? reservedDays; 
  final List<String>? comments; 

  Item({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.description,
    required this.imageUrl,
    this.isAvailable = true,
    required this.orderType,
    required this.deliveryMode,
    this.reservedDays,
    this.comments,
  });

  factory Item.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Item(
      id: doc.id,
      name: data['Name'] ?? 'No Name',
      category: data['Category'] ?? 'General',
      description: data['Description'] ?? 'No description',
      price: (data['Price'] is num) ? data['Price'].toDouble() : 0.00,
      imageUrl: data['imageUrl'] ?? 'Unknown',
      isAvailable: data['isAvailable'] ?? false,
      comments: data['Comments'] != null
          ? List<String>.from(data['Comments'])
          : null,
      orderType: data['OrderType'] ?? 'Instant',
      deliveryMode: data['DeliveryMode'] ?? 'Seller-Delivery',
      reservedDays: data['ReservedDays'] ?? 0,
    );
  }
}
