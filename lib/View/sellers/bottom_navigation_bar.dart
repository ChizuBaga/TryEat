import 'package:flutter/material.dart';
class SellerBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  final Stream<int> unreadMessagesStream; 
  final Stream<int> newOrdersStream;

  const SellerBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.unreadMessagesStream, 
    required this.newOrdersStream,
  });

  BottomNavigationBarItem _buildNavItemWithIndicator({
    required IconData icon,
    required String label,
    required Stream<int> stream,
  }) {
    return BottomNavigationBarItem(
      label: label,
      icon: StreamBuilder<int>(
        stream: stream,
        initialData: 0,
        builder: (context, snapshot) {
          final unseenCount = snapshot.data ?? 0;
          
          return Stack(
            children: [
              Icon(icon),
              if (unseenCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 12,
                      minHeight: 12,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Color.fromARGB(255, 255, 235, 180),
      selectedItemColor: Color.fromARGB(255, 255, 153, 0),
      unselectedItemColor: Colors.grey,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      currentIndex: currentIndex,
      items: [
        const BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
        _buildNavItemWithIndicator(
          icon: Icons.chat_bubble_outline,
          label: 'Chat',
          stream: unreadMessagesStream,
        ),
        _buildNavItemWithIndicator(
          icon: Icons.shopping_cart_outlined,
          label: 'Orders',
          stream: newOrdersStream,
        ),
        const BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
      ],
      onTap: onTap,
    );
  }
}
