import 'package:chikankan/Controller/order_service.dart';
import 'package:chikankan/Controller/seller_navigation_handler.dart';
import 'package:chikankan/Model/orderItem.dart';
import 'package:chikankan/Model/order_model.dart';
import 'package:chikankan/View/sellers/bottom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swipe_to/swipe_to.dart';

class SellerCurrentOrder extends StatefulWidget {
  final Orders order; // The Order object passed from the Seller Homepage

  const SellerCurrentOrder({super.key, required this.order});

  @override
  State<SellerCurrentOrder> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<SellerCurrentOrder> {
  final OrderService _orderService = OrderService();
  late Future<List<OrderItemDisplay>> _detailedItemsFuture;
  bool _isProcessing = false;

  int _selectedIndex = 0; 
  void _onNavTap(int index) {
    final handler = SellerNavigationHandler(context);
    setState(() {
      _selectedIndex = index;
    });
    handler.navigate(index);
  }

  @override
  void initState() {
    super.initState();
    _detailedItemsFuture = _orderService.getDetailedOrderItems(widget.order.items);
  }
  
  // --- Actions ---
  void _chatWithCustomer() {
    print('Starting chat with customer: ${widget.order.customerId}');
    // Navigate to chat screen
  }

  void _callCustomer() {
    print('Calling customer: ${widget.order.customerId}');
    // Use url_launcher to dial the customer's phone number
  }

  // Final Action to mark order as complete/shipped/ready
  void _swipeToComplete(DragUpdateDetails details) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.order.orderId)
          .update({
            'orderStatus': 'Completed',
            'completedAt': FieldValue.serverTimestamp(),
          });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order status updated!')),
        );
        Navigator.of(context).pop(); // Go back to orders list
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to complete order: $e')),
        );
        setState(() {
          _isProcessing = false; // Reset swipe button
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Note: The UI is very similar to the image, but we replace the hardcoded
    // list with the actual data from the widget.
    
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 252, 248, 221),
      appBar: AppBar(
        title: Text('#${widget.order.orderId}', style: const TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FutureBuilder<List<OrderItemDisplay>>(
                    future: _detailedItemsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Failed to load item details: ${snapshot.error}'));
                      }
                      
                      final items = snapshot.data ?? [];
                      int totalItemsCount = items.fold(0, (sum, item) => sum + item.quantity);
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          // --- Order Item List ---
                          ...items.map((item) => _buildOrderItemRow(item)),                          
                          const Divider(height: 30),

                          // --- Totals Summary ---
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total: $totalItemsCount items', // Dynamic total count
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                              ),
                              Text(
                                'RM ${widget.order.total.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                        ],
                      );
                    },
                  ),
                  
                  // --- Customer Contact Buttons and Swipe ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                     Expanded(child:  _buildContactButton('Chat with Customer',Icons.chat_bubble_outline, _chatWithCustomer),),
                     SizedBox(width:10),
                     Expanded(child: _buildContactButton('Call Customer', Icons.call, _callCustomer),)
                    ],
                  ),
                  const SizedBox(height: 30),
                  _buildSwipeToCompleteButton(),
                ],
              ),
            ),
          ),
          SellerBottomNavBar(currentIndex: 2, onTap: _onNavTap) 
        ],
      ),
    );
  }

  // Helper for Order Item Row
  Widget _buildOrderItemRow(OrderItemDisplay item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Item Image
          Container(
            width: 130,
            height: 130,
            margin: const EdgeInsets.only(right: 15.0),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: ClipRRect(
              child: (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                ? Image.network(
                    item.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 100, color: Colors.grey),
                  )
                : const Icon(Icons.person, size: 100, color: Colors.grey),
            ),
          ),
          
          // Food Name Text
          Expanded(
            child: Text(
              item.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),

          // Quantity
          Text(
            'x ${item.quantity}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // Helper for Chat/Call Buttons
  Widget _buildContactButton(String text, IconData icon, VoidCallback onPressed) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.black,
        backgroundColor: Colors.grey[200],
        padding: const EdgeInsets.symmetric(vertical: 15),
        side: const BorderSide(color: Colors.transparent),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: Icon(icon, size: 20),
      label: Text(text, style: const TextStyle(fontSize: 14)),
    );
  }

  Widget _buildSwipeToCompleteButton() {
    final Color trackColor = _isProcessing ? Colors.grey[400]! : const Color(0xFFE0E0E0);
    
    return SwipeTo(
      onRightSwipe: _swipeToComplete,
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          color: trackColor, 
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.blue, width: 2), // Blue border
        ),
        child: Center(
          child: _isProcessing
              ? const CircularProgressIndicator(color: Colors.black)
              : const Text(
                  'Swipe to complete',
                  style: TextStyle(fontSize: 18, color: Colors.black),
                ),
        ),
      ),
    );
  }
}