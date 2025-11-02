import 'package:chikankan/Controller/order_controller.dart';
import 'package:chikankan/Model/orderItem_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DashboardController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
  final OrderController _orderController = OrderController();

  Future<Map<String, dynamic>> getDailySalesData() async {

    DateTime now = DateTime.now();
    DateTime startOfToday = DateTime(now.year, now.month, now.day);
    Timestamp startTimestamp = Timestamp.fromDate(startOfToday);

    final QuerySnapshot snapshot = await _firestore
        .collection('orders')
        .where('seller_ID', isEqualTo: currentUserId)
        .where('orderStatus', isEqualTo: 'Completed')
        .where('completedAt', isGreaterThanOrEqualTo: startTimestamp)
        .get();

    double totalSales = 0.0; 
    int completedOrders = 0;
    Map<String, double> itemSales = {};

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final orderTotal = (data['total'] is num) ? data['total'].toDouble() : 0.0;
      totalSales += orderTotal;
      completedOrders++;


      final List<dynamic> rawItems = data['items'] ?? [];
      final List<OrderItem> orderItems = rawItems
          .map((itemMap) => OrderItem.fromJson(itemMap as Map<String, dynamic>))
          .toList();

      //Fetch Item price
      final List<OrderItemDisplay> detailedItems = await _orderController.getDetailedOrderItems(orderItems);
        for (var item in detailedItems) {
          if(item.price == 0.0 || item.name == 'Unknown') continue;
          int quantity = item.quantity;
          double price = item.price;
          double subtotal = (quantity * price);
          itemSales[item.name] = (itemSales[item.name] ?? 0.0) + subtotal;
        } // Build pie chart
    }
    List<Map<String, dynamic>> pieChartData = itemSales.entries
        .map((entry) => {'name': entry.key, 'sales': entry.value})
        .toList();

    // Return Final Data
    return {
      'totalSales': totalSales,
      'completedOrders': completedOrders,
      'pieChartData': pieChartData,
    };
  }

  Future<Map<String, double>> getSalesHistory() async {
    DateTime now = DateTime.now();
    DateTime startOfTheWeek = now.subtract(Duration(days: now.weekday -1));
    startOfTheWeek = DateTime(startOfTheWeek.year, startOfTheWeek.month, startOfTheWeek.day);
    DateTime startOfTheMonth = DateTime(now.year, now.month, 1);
    Timestamp startTime = Timestamp.fromDate(startOfTheMonth);

    final QuerySnapshot snapshot = await _firestore.collection('orders')
                                                  .where('seller_ID', isEqualTo: currentUserId)
                                                  .where('orderStatus', isEqualTo: 'Completed')
                                                  .where('completedAt', isGreaterThanOrEqualTo: startTime)
                                                  .get();

    double totalSalesMonth = 0.0;
    double totalSalesWeek = 0.0;

    for(var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final orderTotal = data['total'].toDouble();

      final Timestamp? completedAt = data['completedAt'] as Timestamp?;
      if (completedAt == null) continue;

      final completedDate = completedAt.toDate();
      totalSalesMonth += orderTotal;

      if (completedDate.isAfter(startOfTheWeek) || completedDate.isAtSameMomentAs(startOfTheWeek)) {
        totalSalesWeek += orderTotal;
      }                                                 
    }
    return {
      'thisWeek' : totalSalesWeek,
      'thisMonth' : totalSalesMonth,
    };
  }
}