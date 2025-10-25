import 'package:chikankan/Model/orderItem.dart';
import 'package:chikankan/View/sellers/chat_screen.dart';
import 'package:chikankan/View/sellers/seller_current_order.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chikankan/Model/order_model.dart'; 
import 'package:chikankan/Controller/order_controller.dart'; 



class SellerPendingOrder extends StatefulWidget {
  const SellerPendingOrder({super.key});

  @override
  State<SellerPendingOrder> createState() => _SellerPendingOrderState();
}

class _SellerPendingOrderState extends State<SellerPendingOrder> {
  final OrderController _orderController = OrderController();

  Future<String> fetchCustomerUsername(String customerId) async {
  if (customerId.isEmpty) {
    return 'Customer ID Missing';
  }
  
  try {
    final doc = await FirebaseFirestore.instance
        .collection('customers')
        .doc(customerId)
        .get();

    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      return data['username'] ?? 'Customer Profile'; 
    }
    return 'Customer Profile Not Found';
  } catch (e) {
    print("Error fetching username for ID $customerId: $e");
    return 'Customer (Error)';
  }
}

  void _handleAccept(Orders order) async {
    await FirebaseFirestore.instance.collection('orders').doc(order.orderId).update({
      'orderStatus': 'Preparing', 
      'acceptedAt': FieldValue.serverTimestamp(),
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Order ${order.orderId} accepted!')));
    }
  }

  void _handleReject(Orders order) async {
    await FirebaseFirestore.instance.collection('orders').doc(order.orderId).update({
      'orderStatus': 'Rejected',
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Order ${order.orderId} rejected.')));
    }
  }
  
  void _chatWithCustomer(Orders order) async {
  final sellerId = FirebaseAuth.instance.currentUser?.uid;
  final customerId = order.customerId;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 252, 248, 221),
      appBar: AppBar(
        title: const Text('Pending Orders', style: TextStyle(color: Colors.black)),
        backgroundColor: Color.fromARGB(255, 252, 248, 221),
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<List<Orders>>(
        stream: _orderController.streamPendingOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading orders: ${snapshot.error}'));
          }
          final orders = snapshot.data ?? [];
          if (orders.isEmpty) {
            return const Center(child: Text('No pending orders at this time.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(10.0),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              return _buildOrderCard(orders[index]);
            },
          );
        },
      ),
    );
  }

  // --- Widget Builder for Individual Order Card ---
  Widget _buildOrderCard(Orders order) {      
    Future<String> customerUsername = fetchCustomerUsername(order.customerId);
    Future<List<OrderItemDisplay>> detailedItems = _orderController.getDetailedOrderItems(order.items);

    return Card(
      margin: const EdgeInsets.only(bottom: 15.0),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Username, Paid Status, Price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FutureBuilder<String>(
                  future: customerUsername,
                  builder: (context, snapshot) {
                    String username = snapshot.data ?? 'Loading...';

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      username = 'Loading...'; 
                    }

                    return Text(
                      username, 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    );
                  },
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text('Paid', style: TextStyle(color: Colors.black54)),
                    Text('RM ${order.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 5),

            FutureBuilder<List<OrderItemDisplay>>(
                  future: detailedItems,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Text('Loading order items...', style: TextStyle(fontSize: 20));
                    }
                    if(snapshot.hasError){
                      print(snapshot.error);
                      return const Text('Error loading items.', style: TextStyle(fontSize: 20));
                    }
                    final items = snapshot.data ?? [];
                    String itemsSummary = items
                      .map((item) => '${item.quantity} x ${item.name}')
                      .join(', ');
                    return GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => SellerCurrentOrder(order: order)));
                        print('Navigating to detail for ${order.orderId}');
                      },
                      child: Text(
                        itemsSummary,
                        style: const TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                ),
            const SizedBox(height: 8),

            // Row 3: Action Buttons
            Row(
              children: [
                // Accept Button
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleAccept(order),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(topLeft: Radius.circular(8), bottomLeft: Radius.circular(8)),
                      ),
                    ),
                    child: const Text('Accept', style: TextStyle(fontSize: 16)),
                  ),
                ),
                
                // Reject Button
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleReject(order),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    child: const Text('Reject', style: TextStyle(fontSize: 16)),
                  ),
                ),
                
                // Chat Button
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _chatWithCustomer(order),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      side: const BorderSide(color: Colors.transparent),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(topRight: Radius.circular(8), bottomRight: Radius.circular(8)),
                      ),
                    ),
                    child: const Text('Chat with Customer', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}