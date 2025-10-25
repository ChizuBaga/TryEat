import 'package:chikankan/Model/chat_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

  // Get all seller participate chatroom
  Stream<List<ChatRoom>> streamChatRoomsForUser() {
    if (currentUserId == null) {
      return Stream.value([]); //No user
    }

    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId) 
        .orderBy('timestamp', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final chatRooms = <ChatRoom>[];
      for (var doc in snapshot.docs) {
        final chatRoom = ChatRoom.fromFirestore(doc, currentUserId!);
        
        //Later let it bool check seller or customer then determine which user to access

        // Fetch participants details for each chat room
        final customerDoc = await _firestore.collection('customers').doc(chatRoom.otherParticipantId).get();
        if (customerDoc.exists) {
          final customerData = customerDoc.data();
          chatRoom.otherParticipantUserName = customerData?['username'] ?? 'Unknown Customer';
          chatRoom.otherParticipantProfileImageUrl = customerData?['profileImageUrl'];
        }
        chatRooms.add(chatRoom);
      }
      return chatRooms;
    });
  }

  Stream<int> streamUnreadCount() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    
    if (currentUserId == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .where('lastMessageSenderId', isNotEqualTo: currentUserId) 
        .where('unreadCount', isGreaterThan: 0)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.isNotEmpty ? 1 : 0;
        });
  }
}