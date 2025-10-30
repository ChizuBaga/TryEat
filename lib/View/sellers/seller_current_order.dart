import 'package:chikankan/Controller/order_controller.dart';
import 'package:chikankan/Model/orderItem_model.dart';
import 'package:chikankan/Model/order_model.dart';
import 'package:chikankan/View/sellers/chat_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swipe_to/swipe_to.dart';
import 'package:url_launcher/url_launcher.dart';

class SellerCurrentOrder extends StatefulWidget {
  final Orders order; // The Order object passed from the Seller Homepage

  const SellerCurrentOrder({super.key, required this.order});

  @override
  State<SellerCurrentOrder> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<SellerCurrentOrder> {
  final OrderController _orderService = OrderController();
  late Future<List<OrderItemDisplay>> _detailedItemsFuture;
  bool _isProcessing = false;
  late bool _isPreparingOrder;

  @override
  void initState() {
    super.initState();
    _detailedItemsFuture = _orderService.getDetailedOrderItems(widget.order.items);
    _isPreparingOrder = (widget.order.orderStatus == "Preparing") ? true : false;
  }
  
  // --- Actions ---
  void _chatWithCustomer() async {
  final sellerId = FirebaseAuth.instance.currentUser?.uid;
  final customerId = widget.order.customerId;

  if (sellerId == null || customerId.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Error: Seller or Customer ID missing.')),
    );
    return;
  }

  List<String> ids = [sellerId, customerId];
  ids.sort();
  final chatRoomId = ids.join('_');

  final chatDocRef = FirebaseFirestore.instance.collection('chats').doc(chatRoomId);

  // Check Existence
  final chatDoc = await chatDocRef.get();

  // If chat exist go to chatroom
  if (chatDoc.exists) {
    print('Chat room already exists: $chatRoomId');
    String customerName = chatDoc['customerName'];
    // Navigate to existing chat screen
    _navigateToChatScreen(chatRoomId, customerId, customerName);

  } else {
    // Get Customer name
    DocumentSnapshot customerDoc = await FirebaseFirestore.instance
        .collection('customers')
        .doc(customerId)
        .get();
    String customerName = 'Customer'; // Default name
    if (customerDoc.exists) {
      final data = customerDoc.data() as Map<String, dynamic>;
      // Assuming 'username' is the field for the customer's name
      customerName = data['username'] ?? 'Customer'; 

    }
    // Create New Chat Room
    print('Creating new chat room: $chatRoomId');
    try {
      await chatDocRef.set({
        'chatRoomId': chatRoomId,
        'participants': [sellerId, customerId],
        'customerName': customerName,
        'timestamp': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': '',
        'unreadCount': 0,                
      });
      
      _navigateToChatScreen(chatRoomId, customerId, customerName);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create chat: $e')),
      );
    }
  }
}

void _navigateToChatScreen(String chatRoomId, String customerId, String customerName) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => ChatScreen(
        chatRoomId: chatRoomId,
        otherParticipantId: customerId,
        otherParticipantName: customerName,
      ),
    ),
  );
  print("Navigating to chat screen with ID: $chatRoomId");
}

  void _callCustomer() async {
  final String customerId = widget.order.customerId;
  String? customerPhone;

  setState(() {
    _isProcessing = true;
  });

  try {
    // 1. Access firebase
    DocumentSnapshot customerDoc = await FirebaseFirestore.instance
        .collection('customers')
        .doc(customerId)
        .get();

    if (customerDoc.exists) {
      final data = customerDoc.data() as Map<String, dynamic>;
      customerPhone = data['phone_number']; 
      
      if (customerPhone != null && customerPhone.isNotEmpty) {
        // Format the launch URI
        final Uri phoneLaunchUri = Uri(
          scheme: 'tel',
          path: customerPhone,
        );

        // Launch the dialer
        if (await canLaunchUrl(phoneLaunchUri)) {
          await launchUrl(phoneLaunchUri);
        } else {
          throw Exception('Could not launch dialer.');
        }
      } else {
        throw Exception('Customer phone number not found in profile.');
      }
    } else {
      throw Exception('Customer not exist.');
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to call customer: ${e.toString().split(':').last}')),
    );
  } finally {
    setState(() { _isProcessing = false; });
  }
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
            'orderStatus': 'Ready for pickup',
            'completedAt': FieldValue.serverTimestamp(),
          });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order status updated!')),
        );
        Navigator.of(context).pop(); 
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to complete order: $e')),
        );
        setState(() {
          _isProcessing = false; 
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 252, 248, 221),
      appBar: AppBar(
        title: Text(widget.order.orderId, style: const TextStyle(color: Colors.black)),
        backgroundColor: Color.fromARGB(255, 252, 248, 221),
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
                  if(_isPreparingOrder)
                    ...[const SizedBox(height: 30),
                    _buildSwipeToCompleteButton(),]
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

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
              child: (item.imageUrl != null && item.imageUrl.isNotEmpty)
                ? Image.network(
                    item.imageUrl,
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