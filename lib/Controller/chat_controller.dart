import 'package:chikankan/Controller/user_auth.dart';
import 'package:chikankan/Model/chat_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

  // Get all seller participate chatroom
  Stream<List<ChatRoom>> streamChatRoomsForUser(UserRole currentUserRole) {
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

        final targetCollection = currentUserRole == UserRole.seller ? 'customers' : 'sellers';
        // Fetch participants details for each chat room
        final participantDoc = await _firestore.collection(targetCollection).doc(chatRoom.otherParticipantId).get();
        if (participantDoc.exists) {
          final participantData = participantDoc.data();
          chatRoom.otherParticipantUserName = participantData?['username'] ?? 'Unknown Customer';
          chatRoom.otherParticipantProfileImageUrl = participantData?['profileImageUrl'];
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
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.length > 0 ? 1 : 0;
        });
}
}