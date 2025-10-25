import 'package:chikankan/Model/chat_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  final String chatRoomId;
  final String otherParticipantName;
  final String otherParticipantId;

  const ChatScreen({
    super.key,
    required this.chatRoomId,
    required this.otherParticipantName,
    required this.otherParticipantId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final currentUserId = FirebaseAuth.instance.currentUser?.uid; // Get sender ID
  void _sendMessage() async {
    final text = _messageController.text.trim();

    if (text.isEmpty || currentUserId == null) return;

    final newMessage = ChatMessage(
      senderId: currentUserId!,
      text: text,
      time: DateTime.now(), 
    );

    _messageController.clear(); // Clear input immediately for better UX

    try {
      // 2. Add the message to the subcollection
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatRoomId)
          .collection('messages')
          .add(newMessage.toFirestore()); // Use the toFirestore map method

      // 3. Update the main chat document (for lastMessage summary in the list view)
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatRoomId)
          .update({
            'lastMessage': text,
            'timestamp': FieldValue.serverTimestamp(),
            'lastMessageSenderId': currentUserId,
            'unreadCount': FieldValue.increment(1), // Increment counter for the receiver
            // You would need a Cloud Function or complex rules to increment only for the *other* user
          });

    } catch (e) {
      print("Error sending message: $e");
      // Handle error feedback
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesStream = FirebaseFirestore.instance
      .collection('chats')
      .doc(widget.chatRoomId) // Use the ID passed from the previous screen
      .collection('messages')
      .orderBy('timestamp', descending: true) // Get latest messages first
      .snapshots()
      .map((snapshot) {
        // Map Firestore documents to your ChatMessage model
        return snapshot.docs.map((doc) => ChatMessage.fromFirestore(doc)).toList();
      });
      
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1, // Add shadow for sation
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: _buildAppBarTitle(),
      ),
      body: Column(
      children: [
        // 2. Wrap the message list in a StreamBuilder
        Expanded(
          child: StreamBuilder<List<ChatMessage>>(
            stream: messagesStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error loading messages: ${snapshot.error}'));
              }
              
              final messages = snapshot.data ?? [];
              
              if (messages.isEmpty) {
                return const Center(child: Text('Start the conversation!'));
              }

              // 3. Display the real-time message list
              return ListView.builder(
                reverse: true, // Display latest message at the bottom
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  return _buildMessageBubble(messages[index]);
                },
              );
            },
          ),
        ),        
        _buildMessageInput(),
      ],
    ),
  );
  }

  // --- Widget Builders ---
  Widget _buildAppBarTitle() {
    final String customerName = widget.otherParticipantName;
    
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        const CircleAvatar(
          radius: 20,
          backgroundColor: Colors.grey,
          child: Icon(Icons.person, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Text(
          customerName,
          style: const TextStyle(color: Colors.black, fontSize: 18),
        ),
      ],
    );
  }

  // Individual Message Bubble
  Widget _buildMessageBubble(ChatMessage message) {
    final bool isMe = message.senderId == currentUserId;
    final bubbleColor = isMe ? Colors.black : Colors.grey[200];
    final textColor = isMe ? Colors.white : Colors.black;
    final alignment = isMe ? Alignment.centerRight : Alignment.centerLeft;

    return Align(
      alignment: alignment,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Message Bubble
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.circular(15).copyWith(
              bottomRight: isMe ? Radius.zero : const Radius.circular(15),
              bottomLeft: isMe ? const Radius.circular(15) : Radius.zero,
            ),
            ),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
            child: Text(
              message.text,
              style: TextStyle(color: textColor, fontSize: 16),
            ),
          ),
          
          // Timestamp (Simplified from the long date in the screenshot)
          Padding(
            padding: EdgeInsets.only(
              right: isMe ? 8.0 : 0, 
              left: isMe ? 0 : 8.0, 
              bottom: 12.0
            ),
            child: Text(
              '${message.time.hour}:${message.time.minute} ${message.time.day}/${message.time.month}/${message.time.year}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // Input Field and Action Buttons
  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          // Text Input Field
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide.none, // Remove border line
                ),
                fillColor: Colors.grey[100],
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onSubmitted: (_) => _sendMessage(), // Send message on enter key
            ),
          ),
          
          // Smile/Emoji Button
          IconButton(
            icon: const Icon(Icons.sentiment_satisfied_alt_outlined, color: Colors.grey),
            onPressed: () {
              print("Emoji picker opened");
            },
          ),
          
          // Image/Gallery Button (Send Button replacement)
          IconButton(
            icon: const Icon(Icons.send, color: Colors.black), // Use send icon to match common chat apps
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}