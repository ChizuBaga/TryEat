import 'package:cloud_firestore/cloud_firestore.dart';

class Item {
  final String id;
  final String name;
  final double price;
  final String category;
  final String description;
  final String imageUrl;
  bool isAvailable;
  final List<String>? comments; 

  Item({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.description,
    required this.imageUrl,
    this.isAvailable = true,
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
    );
  }
}
