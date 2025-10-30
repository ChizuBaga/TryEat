class OrderItem {
  final String itemId;
  final int quantity;

  OrderItem({
    required this.itemId,
    required this.quantity,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      itemId: json['itemID'] ?? 'N/A',
      quantity: (json['quantity'] is num) ? json['quantity'].toInt() : 0,
    );
  }
  @override
  String toString() {
    return 'OrderItem{'
           'itemId: $itemId, '
           'quantity: $quantity, '
           '}';
  }
}

class OrderItemDisplay {
  final String itemId;
  final int quantity;
  final String name;
  final String imageUrl;
  final double price;

  OrderItemDisplay({
    required this.itemId,
    required this.quantity,
    required this.name,
    required this.imageUrl,    
    required this.price,
  });
}