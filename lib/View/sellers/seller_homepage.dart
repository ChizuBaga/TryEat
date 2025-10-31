import 'package:chikankan/View/sellers/seller_current_order.dart';
import 'package:chikankan/View/sellers/seller_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:chikankan/Model/order_model.dart';
import 'package:chikankan/View/sellers/seller_view_catalogue.dart';
import 'package:chikankan/Controller/order_controller.dart';

class SellerHomepage extends StatefulWidget {
  const SellerHomepage({super.key});

  @override
  State<SellerHomepage> createState() => _SellerHomepageState();
}

class _SellerHomepageState extends State<SellerHomepage> {

  final String uid = FirebaseAuth.instance.currentUser!.uid; 
  late final Future<DocumentSnapshot> _sellerDataFuture;

  final OrderController _orderService = OrderController();
   
  @override
  void initState() {
    super.initState();
    if (uid != null) {
      _sellerDataFuture = FirebaseFirestore.instance.collection('sellers').doc(uid).get();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(156, 255, 255, 255),
      appBar: AppBar(
        toolbarHeight: 1,
        backgroundColor: const Color.fromRGBO(255, 191, 0, 100),
        elevation: 1,
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
          ],
        ),
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
        color: Color.fromRGBO(255, 255, 255, 1),
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
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color.fromRGBO(251, 192, 45, 1)),
            ),
            SizedBox(height: 8),
            Text(
              'RM0.00',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color.fromRGBO(251, 192, 45, 1)),
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
    
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => SellerCurrentOrder(order: order),),
        );
      },
      child: Container(
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
          color: const Color.fromARGB(255, 255, 255, 255)
        ),
        _buildActionCard(
          title: 'View Catalogue',
          icon: Icons.menu_book,
          color: const Color.fromARGB(255, 255, 255, 255)
        ),
      ],
    );
  }

  Widget _buildActionCard({required String title, required IconData icon, required Color color}) {
    return Card(
      elevation: 4,
      shadowColor: Color.fromRGBO(135, 99, 8, 1),
      color: color,
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
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color.fromRGBO(109, 109, 109, 1)),
              ),
              Icon(icon, color: Color.fromRGBO(108, 108, 108, 1)),
            ],
          ),
        ),
      ),
    );
  }
}