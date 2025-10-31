import 'package:flutter/material.dart';
import 'package:chikankan/locator.dart';
import 'package:chikankan/Controller/customer_order_controller.dart';
import 'package:chikankan/Model/order_model_temp.dart'; // Import Orders model
import 'package:chikankan/Controller/user_auth.dart'; // Import AuthService to get user
import 'package:firebase_auth/firebase_auth.dart'; // Import User type
import 'package:intl/intl.dart'; // Import for date formatting

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  // Get controller and auth service instances
  final CustomerOrderController _orderController =
      locator<CustomerOrderController>();
  final AuthService _authService = locator<AuthService>();

  // Future to hold the list of orders
  late Future<List<Orders>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    // Start fetching orders when the widget is initialized
    _fetchOrders();
  }

  // Helper function to get current user ID and fetch orders
  void _fetchOrders() {
    final User? currentUser = _authService.getCurrentUser();
    if (currentUser != null) {
      setState(() {
        // Assign the future returned by the controller method
        _ordersFuture = _orderController.fetchCustomerOrders(currentUser.uid);
      });
    } else {
      // Handle case where user is not logged in
      setState(() {
        _ordersFuture = Future.value([]); // Set to empty list
      });
      print("Error: Cannot fetch orders, user not logged in.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 254, 246),
      appBar: AppBar(
        title: const Text(
          'Order History',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromRGBO(251, 192, 45, 1), // Kept this color
        centerTitle: true,
      ),
      // --- Use FutureBuilder to handle async fetching ---
      body: FutureBuilder<List<Orders>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          // --- Handle Loading State ---
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // --- Handle Error State ---
          if (snapshot.hasError) {
            return Center(
                child: Text("Error loading order history: ${snapshot.error}"));
          }

          // --- Handle No Data ---
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(
              child: Text(
                'Your order history is empty.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          // --- Data Loaded Successfully ---
          // --- MODIFIED: FILTER FOR COMPLETED ORDERS ONLY ---
          final List<Orders> historyOrders = snapshot.data!
              .where((order) =>
                  order.orderStatus.toLowerCase() == 'completed')
              .toList();

          // --- Handle Empty History List State ---
          if (historyOrders.isEmpty) {
            return const Center(
              child: Text(
                'Your past orders will appear here.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          // --- Display Orders using ListView.builder and ListTile ---
          return ListView.builder(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            itemCount: historyOrders.length,
            itemBuilder: (context, index) {
              final order = historyOrders[index];
              // --- FORMAT DATE ---
              // Use completedAt if it exists, otherwise fall back to createdAt
              final timestamp = order.completedAt ?? order.createdAt;
              final String formattedDate =
                  DateFormat('dd MMM yyyy, hh:mm a').format(timestamp.toDate());

              // Set the label based on status
              const String dateLabel = 'Completed'; // Only show completed

              return Card(
                color: const Color.fromARGB(255, 252, 248, 221),
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0)),
                elevation: 2,
                // --- MODIFIED LISTTILE ---
                child: ListTile(
                  leading: _getStatusIcon(order.orderStatus),
                  
                  // --- Title: Item Name, Quantity, and Status Chip ---
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Item name
                            Text(
                              order.itemName,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                            // 2. Quantity
                            Padding(
                              padding: const EdgeInsets.only(top: 2.0),
                              child: Text(
                                'Quantity: ${order.quantity}', // Use the quantity field
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.normal,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8), // Space between text and chip
                      Chip(
                        label: Text(
                          order.orderStatus,
                          style: const TextStyle(
                            fontSize: 14, // Matched customer_order.dart
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        backgroundColor: _getStatusColor(order.orderStatus),
                        labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  // --- END OF TITLE CHANGE ---

                  // --- Subtitle: Date and Total ---
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4.0), // Space from title row
                      Text('$dateLabel: $formattedDate'), // Use the new date label
                      const SizedBox(height: 4.0), // <-- This adds the space
                      Text('Total: RM${order.total.toStringAsFixed(2)}'),
                    ],
                  ),

                  isThreeLine: true,
                  onTap: () {
                    // Optional: navigation to a detailed view
                    print('Tapped on history item: ${order.itemId}');
                  },
                ),
                // --- END OF MODIFIED LISTTILE ---
              );
            },
          );
        },
      ),
    );
  }

  // --- MODIFIED Helper Functions for Status Icon and Color ---
  Icon _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        // Added size to match customer_order.dart
        return const Icon(Icons.check_circle_outline, size: 32, color: Colors.green);
      default:
        // Added size to match customer_order.dart
        return const Icon(Icons.help_outline, size: 32, color: Colors.grey);
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green.shade100;
      default:
        return Colors.grey.shade200;
    }
  }
}

