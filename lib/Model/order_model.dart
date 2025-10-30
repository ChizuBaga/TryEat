import 'package:chikankan/Model/orderItem_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Orders {
  final String orderId;
  final String orderStatus;
  final String customerId;
  final String sellerId;
  final double total;
  final List<OrderItem> items; 

  Orders({
    required this.orderId,
    required this.orderStatus,
    required this.customerId,
    required this.sellerId,
    required this.total,
    required this.items, 
  });

  factory Orders.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final rawItems = data['items'] as List<dynamic>? ?? [];
    final List<OrderItem> parsedItems = rawItems
        .map((itemMap) => OrderItem.fromJson(itemMap as Map<String, dynamic>))
        .toList();
    
    return Orders(
      orderId: doc.id,
      orderStatus: data['orderStatus'] ?? 'Unknown',
      customerId: data['customer_ID'] ?? '',
      sellerId: data['seller_ID'] ?? '',
      total: (data['total'] is num) ? data['total'].toDouble() : 0.0,
      items: parsedItems,
    );
  }
}