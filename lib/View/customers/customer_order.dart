import 'package:flutter/material.dart';
import 'package:chikankan/locator.dart';
import 'package:chikankan/Controller/customer_order_controller.dart';
import 'package:chikankan/Model/order_model_temp.dart'; // Import Orders model
import 'package:chikankan/Controller/user_auth.dart'; // Import AuthService to get user
import 'package:firebase_auth/firebase_auth.dart'; // Import User type
import 'package:intl/intl.dart'; // Import for date formatting
import 'customer_history.dart';

class CustomerOrder extends StatefulWidget {
  // <-- Changed to StatefulWidget
  const CustomerOrder({super.key});

  @override
  State<CustomerOrder> createState() => _CustomerOrderState(); // <-- Create state
}

class _CustomerOrderState extends State<CustomerOrder> {
  // <-- State class
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
      // Handle case where user is not logged in (though ideally shouldn't reach here if auth is checked earlier)
      setState(() {
        _ordersFuture = Future.value([]); // Set to empty list or handle error
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
          'My Orders',
          style: TextStyle(fontWeight: FontWeight.bold),
        ), // Changed title
        backgroundColor: Color.fromRGBO(251, 192, 45, 1),
        automaticallyImplyLeading: false,
        centerTitle: true,

        actions: [
          IconButton(
            icon: const Icon(Icons.history, size: 28),
            onPressed: () {
              // Navigate to the Order History page
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OrderHistoryPage(),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
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
              child: Text("Error loading orders: ${snapshot.error}"),
            );
          }

          // --- Handle No Data / Empty List State ---
          // Check if data is null OR empty
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'You have no orders yet.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          // --- Data Loaded Successfully ---
          final List<Orders> orders = snapshot.data!;

          // --- Display Orders using ListView.builder and ListTile ---
          return ListView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              // Format the date nicely
              final String formattedDate = DateFormat(
                'dd MMM yyyy, hh:mm a',
              ).format(order.createdAt.toDate());

              return Card(
                color: const Color.fromARGB(255, 252, 248, 221),
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                elevation: 2,
                child: ListTile(
                  // --- Leading: Status Icon (Example) ---
                  leading: _getStatusIcon(order.orderStatus),
                  // --- Title: Item ID (or Item Name if you fetch it) ---
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. The original item name Text
                            Text(
                              order.itemName,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                            // 2. The new quantity Text
                            Padding(
                              padding: const EdgeInsets.only(top: 2.0), // Adds a small space
                              child: Text(
                                'Quantity: ${order.quantity}', // Use the quantity field
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.normal, // Not bold
                                  color: Colors.black54, // A bit lighter
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
                            fontSize: 15,
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
                  // --- Subtitle: Date and Total ---
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4.0), // Space from title row
                      Text('Placed: $formattedDate'),
                      const SizedBox(height: 4.0), // <-- This adds the space
                      Text('Total: RM${order.total.toStringAsFixed(2)}'),
                    ],
                  ),
                  // --- Trailing: Order Status ---
                  // trailing: Chip(
                  //   label: Text(
                  //     order.orderStatus,
                  //     style: const TextStyle(
                  //       fontSize: 14,
                  //       fontWeight: FontWeight.w500,
                  //     ),
                  //   ),
                  //   backgroundColor: _getStatusColor(order.orderStatus),
                  //   labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                  //   padding: EdgeInsets.zero,
                  //   visualDensity: VisualDensity.compact,
                  // ),
                  isThreeLine: true, // Allows subtitle to have two lines
                  onTap: () {
                    // Implement navigation to a detailed order view if needed
                    print('Tapped on order for item: ${order.itemId}');
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  // --- Helper Functions for Status Icon and Color ---
  Icon _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'placed':
        return const Icon(Icons.shopping_bag_outlined, size: 32, color: Colors.blue);
      case 'accepted':
        return const Icon(Icons.assignment_turned_in_outlined, size: 32, color: Colors.orange,
        );
      case 'processing': // Example status
        return const Icon(Icons.hourglass_top_rounded, size: 32, color: Colors.purple);
      case 'completed':
        return const Icon(Icons.check_circle_outline, size: 32, color: Colors.green);
      case 'cancelled': // Example status
        return const Icon(Icons.cancel_outlined, size: 32, color: Colors.red);
      default:
        return const Icon(Icons.help_outline, size: 32, color: Colors.grey);
    }
  }

  Color _getStatusColor(String status) {
     switch (status.toLowerCase()) {
      case 'placed':
        return Colors.blue.shade100;
      case 'accepted':
        return Colors.orange.shade100;
      case 'processing':
        return Colors.purple.shade100;
      case 'completed':
        return Colors.green.shade100;
      case 'cancelled':
        return Colors.red.shade100;
      default:
        return Colors.grey.shade200;
    }
  }

} // End _CustomerOrderState
