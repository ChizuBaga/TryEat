//Change after chat and order module done
import 'package:flutter/material.dart';

// ⭐️ This widget must be Stateful if it manages its own streams,
// but since we're using placeholder streams, we'll keep them internal.

class SellerBottomNavBar extends StatelessWidget {
  // ⭐️ You would normally pass the current index and onTap handler here
  final int currentIndex;
  final ValueChanged<int> onTap;

  const SellerBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  // ⭐️ Placeholder Streams (defined inside the StatelessWidget for safety)
  // In a real app, these would come from a global provider or service.
  final Stream<int> _unreadMessagesStream = 
      const Stream.empty(); // Use empty stream for simplicity here
      
  final Stream<int> _newOrdersStream = 
      const Stream.empty(); // Use empty stream for simplicity here

  // NOTE: If you wanted actual *live* data here, you would typically 
  // define this widget as StatefulWidget and manage the streams in initState.

  // Helper function to create BottomNavigationBarItem with a real-time indicator
  BottomNavigationBarItem _buildNavItemWithIndicator({
    required IconData icon,
    required String label,
    required Stream<int> stream,
    int initialCount = 0,
  }) {
    return BottomNavigationBarItem(
      label: label,
      icon: StreamBuilder<int>(
        stream: stream,
        initialData: initialCount,
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
      backgroundColor: Colors.white,
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.grey,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      currentIndex: currentIndex,
      items: [
        const BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
        _buildNavItemWithIndicator(
          icon: Icons.chat_bubble_outline,
          label: 'Chat',
          stream: _unreadMessagesStream,
          initialCount: 2, // Example initial red dot for Chat
        ),
        _buildNavItemWithIndicator(
          icon: Icons.shopping_cart_outlined,
          label: 'Orders',
          stream: _newOrdersStream,
          initialCount: 1, // Example initial red dot for Orders
        ),
        const BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
      ],
      onTap: onTap,
    );
  }
}
