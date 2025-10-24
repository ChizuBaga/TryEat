import 'package:chikankan/Controller/seller_navigation_controller.dart';
import 'package:chikankan/View/sellers/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For formatting dates
import 'package:chikankan/Controller/chat_controller.dart'; // Your ChatService
import 'package:chikankan/Model/chat_model.dart'; // Your ChatRoom model
import 'package:chikankan/View/sellers/bottom_navigation_bar.dart';


class SellerChat extends StatefulWidget {
  const SellerChat({super.key});

  @override
  State<SellerChat> createState() => _SellerChatState();
}

class _SellerChatState extends State<SellerChat> {
  final ChatController _chatService = ChatController();

  int _selectedIndex = 1; 
  void _onNavTap(int index) {
    final handler = SellerNavigationHandler(context);
    setState(() {
      _selectedIndex = index;
    });
    handler.navigate(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 252, 248, 221),
      appBar: AppBar(
        title: const Text('Chats', style: TextStyle(fontSize: 30, color: Colors.black)),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 252, 248, 221),
        elevation: 0,
        automaticallyImplyLeading: false, // No back button on this main page
      ),
      body: StreamBuilder<List<ChatRoom>>(
        stream: _chatService.streamChatRoomsForUser(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No active chats.'));
          }

          final chatRooms = snapshot.data!;

          return ListView.builder(
            itemCount: chatRooms.length,
            itemBuilder: (context, index) {
              final chatRoom = chatRooms[index];
              return _buildChatListItem(context, chatRoom); 
            },
          );
        },
      ),
      bottomNavigationBar: SellerBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onNavTap,
      ),
    );
  }

  // Helper widget to build each chat list item
  Widget _buildChatListItem(BuildContext context, ChatRoom chatRoom) {
    // Determine if the red dot (unread indicator) should be shown
    // if last message sender is NOT current user AND it's unread
    //debug
    // final bool showUnreadIndicator = chatRoom.unreadCount > 0;
    print(_chatService.currentUserId);
    final bool showUnreadIndicator = chatRoom.lastMessageSenderId != _chatService.currentUserId && chatRoom.unreadCount > 0;

    return InkWell(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => ChatScreen(
            chatRoomId: chatRoom.chatRoomId,
            otherParticipantName: chatRoom.otherParticipantName,
            otherParticipantId: chatRoom.otherParticipantId,
          ),
        ));
        print('Tapped on chat with ${chatRoom.otherParticipantName}');
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        child: Row(
          children: [
            // Profile Picture
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.grey[300],
              backgroundImage: chatRoom.otherParticipantProfileImageUrl != null && chatRoom.otherParticipantProfileImageUrl!.isNotEmpty
                  ? NetworkImage(chatRoom.otherParticipantProfileImageUrl!)
                  : null, // Fallback to child if no image
              child: chatRoom.otherParticipantProfileImageUrl == null || chatRoom.otherParticipantProfileImageUrl!.isEmpty
                  ? const Icon(Icons.person, color: Colors.white, size: 30)
                  : null,
            ),
            const SizedBox(width: 15),

            // Customer Name & Last Message
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chatRoom.otherParticipantName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    chatRoom.lastMessage,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Time & Unread Indicator
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatChatTime(chatRoom.lastMessageTime),
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                if (showUnreadIndicator) // Show red dot only if there are unread messages
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper function to format time (e.g., "1d", "5h", "Dec 25")
  String _formatChatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 7) {
      return DateFormat('MMM dd').format(time); // e.g., "Dec 25"
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d'; // e.g., "1d"
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h'; // e.g., "5h"
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m'; // e.g., "10m"
    } else {
      return 'Now';
    }
  }
}