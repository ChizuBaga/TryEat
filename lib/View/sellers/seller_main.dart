import 'package:flutter/material.dart';
import 'package:chikankan/Controller/chat_controller.dart';
import 'package:chikankan/Controller/order_controller.dart';
import 'bottom_navigation_bar.dart';
import 'seller_homepage.dart';
import 'seller_chat.dart';
import 'seller_pending_order.dart'; 
import 'seller_profile.dart';

class SellerMain extends StatefulWidget {
  const SellerMain({super.key});

  @override
  State<SellerMain> createState() => _SellerMainState();
}

class _SellerMainState extends State<SellerMain> {
  int _selectedIndex = 0; // Starts on Home

  final ChatController _chatService = ChatController();
  final OrderController _orderService = OrderController();

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const SellerHomepage(),
      const SellerChat(),
      const SellerPendingOrder(),
      const SellerProfile(),
    ];
  }

  void _onNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages, 
      ),
      
      bottomNavigationBar: SellerBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onNavTap,
        unreadMessagesStream: _chatService.streamUnreadCount(), 
        newOrdersStream: _orderService.streamPendingOrderCount(),
      ),
    );
  }
}