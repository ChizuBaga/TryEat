import 'package:cloud_firestore/cloud_firestore.dart';

class Orders {
  String itemName;
  Timestamp acceptedAt;
  Timestamp completedAt;
  Timestamp createdAt;
  String customerId;
  String sellerId;
  String itemId; //Temp change
  double total;
  String orderStatus;
  int quantity; // <-- 1. ADDED FIELD


  Orders(
    this.itemName,
    this.acceptedAt,
    this.completedAt,
    this.orderStatus, {
    required this.createdAt,
    required this.customerId,
    required this.sellerId,
    required this.itemId, //Temp change
    required this.total,
    required this.quantity,
    
  });

  factory Orders.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Orders(
      data['itemName'],
      data['acceptedAt'] ?? Timestamp(0, 0),
      data['completedAt'] ?? Timestamp(0, 0),
      data['orderStatus'] ?? 'Unknown',
      createdAt: data['createdAt'] ?? Timestamp(0, 0),
      customerId: data['customer_ID'] ?? '',
      sellerId: data['seller_ID'] ?? '',
      itemId: data['itemId'], //Temp change
      total: (data['total'] is num) ? data['total'].toDouble() : 0.0,
      quantity: (data['quantity'] is num) ? data['quantity'].toInt() : 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'itemName': itemName,
      'acceptedAt': acceptedAt,
      'completedAt': completedAt,
      'orderStatus': orderStatus,
      'createdAt': createdAt,
      'customer_ID': customerId,
      'seller_ID': sellerId,
      'itemId': itemId, //Temp change
      'total': total,
      'quantity': quantity,
    };
  }
}
