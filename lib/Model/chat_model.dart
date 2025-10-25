import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoom {
  final String chatRoomId;
  final String lastMessage;
  final DateTime lastMessageTime;
  final String otherParticipantId;
  final String? lastMessageSenderId;
  final int unreadCount;
  String otherParticipantUserName;
  String? otherParticipantProfileImageUrl;

  ChatRoom({
    required this.chatRoomId,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.otherParticipantId,  
    required this.otherParticipantUserName,
    this.lastMessageSenderId,
    this.unreadCount = 0, // Default to 0 unread
  });

  factory ChatRoom.fromFirestore(DocumentSnapshot doc, String currentUserId) {
    final data = doc.data() as Map<String, dynamic>;

    // Determine the other participant's ID
   final List<dynamic> participants = data['participants'] ?? [];
    String otherParticipantId = participants.firstWhere(
      (id) => id != currentUserId, // Not current user's id eg. u are customer, other is seller; u are seller, other is customer
      orElse: () => '', 
    );

    return ChatRoom(
      chatRoomId: doc.id,
      lastMessage: data['lastMessage'] ?? 'No messages yet.',
      lastMessageTime: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      otherParticipantId: otherParticipantId,
      otherParticipantUserName: 'Loading...',
      lastMessageSenderId: data['lastMessageSenderId'],
      unreadCount: (data['unreadCount'] is num) ? (data['unreadCount'] as num).toInt() : 0,
    );
  }
}

class ChatMessage {
  final String text;
  final DateTime time;
  final String senderId; //Who send this message

  ChatMessage({required this.text, required this.time, required this.senderId});

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      time: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}