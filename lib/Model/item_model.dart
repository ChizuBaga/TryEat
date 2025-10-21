import 'package:cloud_firestore/cloud_firestore.dart';

class Item {
  final String id;
  final String name;
  final double price;
  final List<String> comments;
  // You can add the 'Category' field here if needed
  // final List<String> category;
  
  Item({
    required this.id,
    required this.name,
    required this.price,
    required this.comments,
  });

  // A factory constructor to easily create an Item from a Firestore document
  factory Item.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return Item(
      id: doc.id,
      name: data['Name'] ?? 'No Name',
      price: (data['Price'] ?? 0.0).toDouble(),
      comments: List<String>.from(data['Comments'] ?? []),
    );
  }
}