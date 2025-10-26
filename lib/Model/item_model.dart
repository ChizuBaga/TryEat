import 'package:cloud_firestore/cloud_firestore.dart';

class Item {
  String id;
  String? category;
  String deliveryMode;
  String? description;
  String sellerId;
  String name;
  String orderType;
  double price;
  int? reservedDays;
  Timestamp createdAt;
  String imageUrl;
  bool isAvailable;

  //Item constructor
  Item(
    this.description, 
    this.category, 
    this.imageUrl, 
    this.reservedDays,
    {
      required this.id,
      required this.name, 
      required this.price, 
      required this.sellerId, 
      required this.isAvailable, 
      required this.createdAt,
      required this.orderType,
      required this.deliveryMode
  });

  // Create Item object from Firestore Document
  factory Item.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Item(
      id: doc.id,
      data['Description'] ?? '',
      data['Category'] ?? '',
      data['imageUrl'] ?? '',
      data['ReservedDays'] ?? 0,
      name: data['Name'],
      price: (data['Price']),
      sellerId: data['sellerId'],
      isAvailable: data['isAvailable'],
      createdAt: data['createdAt'],
      orderType: data['OrderType'],
      deliveryMode: data['DeliveryMode']
    );
  }

  // Convert Item to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'Name': name,
      'Price': price,
      'Category': category,
      'Description': description,
      'imageUrl': imageUrl,
      'isAvailable': isAvailable,
      'sellerId': sellerId,
      'createdAt': createdAt,
      'OrderType': orderType,
      'DeliveryMode': deliveryMode,
      'ReservedDays': reservedDays,
    };
  }


}
