import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chikankan/View/item_detail_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chikankan/View/sellers/chat_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CustomerItemListPage extends StatelessWidget {
  final String sellerId;
  final String storeName;

  const CustomerItemListPage({
    super.key,
    required this.sellerId,
    required this.storeName,
  });

  Future<void> _startChatWithSeller(BuildContext context, String sellerId) async {
  // 1. Get current customer ID
  final customerId = FirebaseAuth.instance.currentUser?.uid;

  // Validate IDs
  if (customerId == null || sellerId.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Error: User or Seller ID missing.')),
    );
    return;
  }

  // Prevent user from chatting with themselves (if applicable)
  if (customerId == sellerId) {
     ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cannot start chat with yourself.')),
    );
    return;
  }


  // 2. Create Chat Room ID (same logic ensures uniqueness)
  List<String> ids = [customerId, sellerId];
  ids.sort(); // Sort to ensure consistency regardless of initiator
  final chatRoomId = ids.join('_');

  final chatDocRef = FirebaseFirestore.instance.collection('chats').doc(chatRoomId);

  try {
    // 3. Check if Chat Room Exists
    final chatDoc = await chatDocRef.get();

    String sellerName = 'Seller'; // Default seller name
    String customerName = 'Customer'; // Default customer name (fetch if needed)

    // 4. If chat exists, get names and navigate
    if (chatDoc.exists) {
      print('Chat room already exists: $chatRoomId');
      final data = chatDoc.data() as Map<String, dynamic>;
      sellerName = data['sellerName'] ?? 'Seller';
      customerName = data['customerName'] ?? 'Customer'; // Keep customer name if stored

      // Navigate to existing chat screen
      _navigateToChatScreen(context, chatRoomId, sellerId, sellerName);

    } else {
      // 5. If chat doesn't exist, fetch participant names
      print('Fetching participant names for new chat room...');

      // Get Seller name from 'sellers' collection
      DocumentSnapshot sellerDoc = await FirebaseFirestore.instance
          .collection('sellers') // Use seller collection
          .doc(sellerId)
          .get();
      if (sellerDoc.exists) {
        final sellerData = sellerDoc.data() as Map<String, dynamic>;
        // Assuming 'businessName' is the field for the seller's name
        sellerName = sellerData['businessName'] ?? 'Seller';
      }

      // Get Customer name from 'customers' collection
       DocumentSnapshot customerDoc = await FirebaseFirestore.instance
          .collection('customers') // Use customer collection
          .doc(customerId)
          .get();
       if (customerDoc.exists) {
         final customerData = customerDoc.data() as Map<String, dynamic>;
         // Assuming 'username' is the field for the customer's name
         customerName = customerData['username'] ?? 'Customer';
       }

      // 6. Create New Chat Room document
      print('Creating new chat room: $chatRoomId');
      await chatDocRef.set({
        'chatRoomId': chatRoomId,
        'participants': [customerId, sellerId], // Store both IDs
        'customerName': customerName, // Store customer name
        'sellerName': sellerName,     // Store seller name
        'timestamp': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': '',
        // Consider participant-specific unread counts if needed later
        'unreadCount_customer': 0, 
        'unreadCount_seller': 0, 
      });

      // 7. Navigate to the newly created chat screen
      _navigateToChatScreen(context, chatRoomId, sellerId, sellerName);
    }
  } catch (e) {
    print("Error starting chat: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to start chat: $e')),
    );
  }
}
  
  void _navigateToChatScreen(BuildContext context, String chatRoomId, String sellerId, String sellerName) {
  // Use the passed context
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatScreen( // Assuming ChatScreen exists
          chatRoomId: chatRoomId,
          otherParticipantId: sellerId,
          otherParticipantName: sellerName,
        ),
      ),
    );
    print("Navigating to chat screen with Seller ID: $sellerId");
  }
  
  @override
  Widget build(BuildContext context) {
    // --- Stream for ITEMS from this store ---
    final Stream<QuerySnapshot> itemsStream = FirebaseFirestore.instance
        .collection('items')
        .where('sellerId', isEqualTo: sellerId) 
        .snapshots();

    // --- Future for SELLER info ---
    // We fetch this once and build the UI.
    final Future<DocumentSnapshot> sellerDocFuture = FirebaseFirestore.instance
        .collection('sellers')
        .doc(sellerId) 
        .get();

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 254, 246),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: sellerDocFuture,
        builder: (context, snapshot) {
          // --- Handle Loading ---
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // --- Handle Error ---
          if (snapshot.hasError ||
              !snapshot.hasData ||
              !snapshot.data!.exists) {
            return const Center(child: Text('Could not load store details.'));
          }

          // --- Success! Get seller data ---
          final sellerData = snapshot.data!.data() as Map<String, dynamic>;

          // Build the main UI
          return ListView(
            children: [
              const SizedBox(height: 6),
              // --- Store Header ---
              _buildStoreHeader(sellerData),
              const SizedBox(height: 24),

              // --- Seller Info ---
              _buildSellerInfo(context, sellerData),
              const Divider(thickness: 2, indent: 65, endIndent: 65),
              const SizedBox(height: 16),
              _buildChatWithSeller((){
                _startChatWithSeller(context, sellerId);
              }),

              // --- Items List (StreamBuilder) ---
              StreamBuilder<QuerySnapshot>(
                stream: itemsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(child: Text("Error loading items."));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text("This store has no items."),
                    );
                  }

                  // Build the list of items
                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    shrinkWrap: true, 
                    physics:
                        const NeverScrollableScrollPhysics(), 
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemBuilder: (context, index) {
                      DocumentSnapshot doc = snapshot.data!.docs[index];
                      Map<String, dynamic> data =
                          doc.data() as Map<String, dynamic>;

                      // --- GRAB THE isAvailable FIELD ---
                      // Default to false (unavailable) if the field doesn't exist
                      bool isAvailable = data['isAvailable'] ?? false;

                      return _buildItemTile(
                        sellerId: sellerId,
                        context: context,
                        name: data['Name'] ?? 'No Name',
                        price: (data['Price'] as num?)?.toDouble() ?? 0.0,
                        imageUrl: data['imageUrl'] ?? 'placeholder',
                        itemId: doc.id,
                        isAvailable: isAvailable,
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 32), 
            ],
          );
        },
      ),
    );
  }

  Widget _buildStoreHeader(Map<String, dynamic> sellerData) {
    String address = sellerData['address'] ?? 'No Address Provided';
    String? profileImageUrl = sellerData['profileImageUrl'] as String?;
    return Column(
    children: [
      // Store Image
      SizedBox( // Use SizedBox for consistent sizing
        width: 100,
        height: 100,
        // Use ClipRRect to enforce the rounded corners
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.0),
          child: CachedNetworkImage(
            imageUrl: profileImageUrl ?? '', // Pass the URL (or empty string if null)
            fit: BoxFit.cover, // Make the image fill the box
            
            // This is shown while the image is loading
            placeholder: (context, url) => Container(
              color: Colors.grey[300],
              child: const Icon(Icons.image_outlined, color: Colors.grey, size: 48),
            ),
            
            // This is shown if the URL is invalid or fails to load
            errorWidget: (context, url, error) => Container(
              color: Colors.grey[300],
              child: const Icon(Icons.broken_image_outlined, color: Colors.grey, size: 48),
            ),
          ),
        ),
      ),
        const SizedBox(height: 16),

        // Business Name
        Text(
          storeName,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        // address
        Text(
          address,
          style: const TextStyle(fontSize: 16, color: Colors.black54),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // Seller Info widget
  Widget _buildSellerInfo(
    BuildContext context,
    Map<String, dynamic> sellerData,
  ) {
    // Extract data
    String username = sellerData['username'] ?? 'N/A';
    String phoneNumber = sellerData['phone_number'] ?? 'N/A';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40.0),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Seller Username
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_outline, color: Colors.grey[700], size: 20),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      username,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[800],
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 16),

            // Contact Number
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.phone_outlined, color: Colors.grey[700], size: 20),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      phoneNumber,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[800],
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

Widget _buildChatWithSeller(VoidCallback onPressed){
  return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: InkWell(
        onTap: onPressed,
        child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40.0),
          border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
          children: [
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chat_bubble_outline, color: Colors.grey[700], size: 20),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Chat with Seller',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[800],
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              )
            )
          ]
        ),
        )
      )
    ); 
  }
}

 Widget _buildItemTile({
  required String sellerId,
   required BuildContext context,
   required String name,
   required double price,
   required String imageUrl,
   required String itemId,
   required bool isAvailable,
 }) {
   final Color tileColor = isAvailable ? const Color.fromARGB(255, 252, 248, 221) : Colors.grey[300]!; 
   final Color textColor = isAvailable ? Colors.black : Colors.grey[600]!;
   final Color iconColor = isAvailable ? Colors.black54 : Colors.grey[600]!;
   final VoidCallback? onTap = isAvailable
       ? () {
           Navigator.push(
             context,
             MaterialPageRoute(
               builder: (context) =>
                   ItemDetailsPage(sellerId: sellerId, itemId: itemId),
             ),
           );
         }
       : null;

   // --- Build the image widget ---
   Widget imageWidget;
   if (imageUrl == 'placeholder' || imageUrl.isEmpty) {
     imageWidget = Icon(Icons.image_outlined, color: iconColor, size: 24);
   } else {
     imageWidget = Image.network(
       imageUrl,
       fit: BoxFit.cover,
       loadingBuilder: (context, child, loadingProgress) {
         if (loadingProgress == null) return child;
         return Center(
           child: CircularProgressIndicator(
             value: loadingProgress.expectedTotalBytes != null
                 ? loadingProgress.cumulativeBytesLoaded /
                     loadingProgress.expectedTotalBytes!
                 : null,
           ),
         );
       },
       errorBuilder: (context, error, stackTrace) {
         return Icon(Icons.broken_image, color: iconColor, size: 24);
       },
     );
   }

   // --- Apply fade effect if unavailable ---
   if (!isAvailable) {
     imageWidget = Opacity(
       opacity: 0.5,
       child: imageWidget,
     );
   }

   return Padding(
     padding: const EdgeInsets.symmetric(vertical: 6.0),
     child: Card( 
       elevation: isAvailable ? 6.0 : 0.0, 
       shadowColor: Colors.black,
       shape: RoundedRectangleBorder(
         borderRadius: BorderRadius.circular(12.0),
       ),
       color: tileColor, 
       clipBehavior: Clip.antiAlias, 
       child: ListTile(
         leading: ClipRRect(
           borderRadius: BorderRadius.circular(8.0),
           child: SizedBox(
             width: 60, 
             height: 60,
             child: imageWidget,
           ),
         ),
         title: Text(
           name,
           style: TextStyle(
             fontWeight: FontWeight.bold,
             color: textColor,
             decoration: !isAvailable ? TextDecoration.lineThrough : null,
           ),
         ),
         subtitle: Text(
           isAvailable
               ? 'RM${price.toStringAsFixed(2)}'
               : 'Unavailable',
           style: TextStyle(color: textColor),
         ),
         trailing: Icon(Icons.arrow_forward_ios, size: 16, color: iconColor),
         onTap: onTap,
       ),
     ),
   );
 }

