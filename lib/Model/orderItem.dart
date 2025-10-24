class OrderItem {
  final String itemId;
  final int quantity;
  final String? foodName; 

  OrderItem({
    required this.itemId,
    required this.quantity,
    this.foodName,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      itemId: json['itemID'] ?? 'N/A',
      quantity: (json['quantity'] is num) ? json['quantity'].toInt() : 0,
      foodName: json['foodName'], 
    );
  }
}

class OrderItemDisplay {
  final String itemId;
  final int quantity;
  final String name;
  final String imageUrl;

  OrderItemDisplay({
    required this.itemId,
    required this.quantity,
    required this.name,
    required this.imageUrl,
  });
}