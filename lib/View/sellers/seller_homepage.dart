import 'package:chikankan/View/sellers/seller_chat.dart';
import 'package:chikankan/View/sellers/seller_dashboard.dart';
import 'package:chikankan/View/sellers/seller_pending_order.dart';
import 'package:chikankan/View/sellers/seller_profile.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart' hide Order; 
import 'package:chikankan/Model/order_model.dart';
import 'package:chikankan/View/sellers/seller_view_catalogue.dart';
import 'package:chikankan/Controller/order_service.dart';
import 'package:chikankan/View/sellers/bottom_navigation_bar.dart';

// Data model for orders
class Order {
  final String id;
  final String status;

  Order(this.id, this.status); 
}

class SellerHomepage extends StatefulWidget {
  const SellerHomepage({super.key});

  @override
  State<SellerHomepage> createState() => _SellerHomepageState();
}

class _SellerHomepageState extends State<SellerHomepage> {

  final String uid = FirebaseAuth.instance.currentUser!.uid; 
  late final Future<DocumentSnapshot> _sellerDataFuture;

  final OrderService _orderService = OrderService();
  
  int _selectedIndex = 0; 

  void _onNavTap(int index) {
      setState(() {
          _selectedIndex = index;
          if (index == 0) {
            Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const SellerHomepage()));
          } else if (index == 1) {
            Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const SellerChat()));
          } else if (index == 2) {
            Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const SellerPendingOrder()));
          } else {
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const SellerProfile()));
      }});
  }
  
  @override
  void initState() {
    super.initState();
    if (uid != null) {
      // Set up the future to fetch the document once
      _sellerDataFuture = FirebaseFirestore.instance.collection('sellers').doc(uid).get();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 252, 248, 221),
      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 20),
            // --- Welcome Title ---
            _buildWelcomeHeader(),
            const SizedBox(height: 30),

            // --- 1. Today's Sales Card ---
            _buildSalesCard(),
            const SizedBox(height: 30),

            // --- 2. Current Orders List ---
            const Text(
              'Current Orders',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildOrdersList(),
            
            const SizedBox(height: 30),

            // --- 3. Quick Actions Grid ---
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildQuickActionsGrid(),
            
            const SizedBox(height: 30),

            // --- 4. Average Rating ---
            _buildAverageRatingCard(),
            const SizedBox(height: 20),
          ],
        ),
      ),
      // --- Bottom Navigation Bar with Notification Dots ---
      bottomNavigationBar: SellerBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onNavTap,
      ), 
    );
  }

  // --- WIDGET BUILDERS ---
  Widget _buildWelcomeHeader() {
    // Use FutureBuilder to handle the asynchronous data fetch
    return FutureBuilder<DocumentSnapshot>(
      future: _sellerDataFuture,
      builder: (context, snapshot) {
        // 1. Loading State
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: double.infinity,
            alignment: Alignment.center,
            child: Text(
              'Welcome, loading...',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
          );
        }

        // 2. Error State
        if (snapshot.hasError) {
          return Container(
            width: double.infinity,
            alignment: Alignment.center,
            child: Text(
              'Welcome, Error!',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.red),
            ),
          );
        }

        // 3. Data Available State
        if (snapshot.hasData && snapshot.data!.exists) {
          // Safely cast the data map
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final username = data['username'] ?? 'User'; // Use 'User' as fallback
          
          return Container(
            width: double.infinity,
            alignment: Alignment.center,
            child: Text(
              'Welcome, $username!',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          );
        }
        
        // 4. No Data/Document Not Found
        return Container(
          width: double.infinity,
          alignment: Alignment.center,
          child: Text(
            'Welcome, Seller!',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
        );
      },
    );
  }

  Widget _buildSalesCard() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 255, 153, 0),
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey,
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Container(
        width: double.infinity,
        alignment: Alignment.centerLeft,
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Today's Sales",
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
            SizedBox(height: 8),
            Text(
              'RM0.00',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersList() {
    return StreamBuilder<List<Orders>>(
      stream: _orderService.streamCurrentOrders(),
      builder: (context, snapshot) {
        // 1. Loading State
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // 2. Error State
        if (snapshot.hasError) {
          return Center(child: Text('Error loading orders: ${snapshot.error}'));
        }

        // 3. No Data / Empty List
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 16.0),
              child: Text('No current orders.', style: TextStyle(color: Colors.grey)),
            ),
          );
        }

        // 4. Data Available State
        final orders = snapshot.data!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          // Map the fetched orders to the tile widget
          children: orders.map((order) => _buildOrderTile(order)).toList(),
        );
      },
    );
  }

  Widget _buildOrderTile(Orders order) {
    Color statusColor = Colors.grey;
    if (order.orderStatus == 'Preparing') {
      statusColor = Colors.orange;
    } else if (order.orderStatus == 'Ready for Pickup') {
      statusColor = Colors.green;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 10.0),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey, width: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            order.orderId,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
          Text(
            order.orderStatus,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      crossAxisSpacing: 16.0,
      mainAxisSpacing: 16.0,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.2,
      children: [
        _buildActionCard(
          title: 'Dashboard',
          icon: Icons.bar_chart,
          color: const Color.fromARGB(255, 255, 153, 0)
        ),
        _buildActionCard(
          title: 'View Catalogue',
          icon: Icons.menu_book,
          color: const Color.fromARGB(255, 255, 153, 0)
        ),
      ],
    );
  }

  Widget _buildActionCard({required String title, required IconData icon, required Color color}) {
    return Card(
      elevation: 0,
      color: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
        onTap: () {
        Widget destination;

        if (title == 'Dashboard') {
          destination = const SellerDashboard(); 
          
        } else if (title == 'View Catalogue') {
          destination = const SellerCataloguePage(); 
          
        } else {
          return; 
        }

        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => destination),
        );
      },
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Icon(icon, size: 80, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAverageRatingCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 10.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Average Rating',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          // Simple Star Rating Placeholder
          Row(
            children: List.generate(
              5,
              (index) => Icon(
                index < 4 ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  } 
}