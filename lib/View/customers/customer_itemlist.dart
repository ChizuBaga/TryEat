import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chikankan/View/item_detail_page.dart'; // Make sure this path is correct

class CustomerItemListPage extends StatelessWidget {
  final String storeId;
  final String storeName;

  const CustomerItemListPage({
    super.key,
    required this.storeId,
    required this.storeName,
  });

  @override
  Widget build(BuildContext context) {
    // --- Stream for ITEMS from this store ---
    final Stream<QuerySnapshot> itemsStream = FirebaseFirestore.instance
        .collection('items')
        .where('storeId', isEqualTo: storeId)
        .snapshots();

    // --- Future for SELLER info ---
    // We fetch this once and build the UI.
    final Future<DocumentSnapshot> sellerDocFuture =
        FirebaseFirestore.instance.collection('sellers').doc(storeId).get();

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 252, 248, 221),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // Standard back button
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      // --- WRAPPED IN FUTUREBUILDER ---
      // This fetches the seller data (address, username, phone) once.
      body: FutureBuilder<DocumentSnapshot>(
        future: sellerDocFuture,
        builder: (context, snapshot) {
          // --- Handle Loading ---
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // --- Handle Error ---
          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Could not load store details.'));
          }

          // --- Success! Get seller data ---
          final sellerData = snapshot.data!.data() as Map<String, dynamic>;

          // Build the main UI
          return ListView(
            children: [
              // --- Store Header ---
              _buildStoreHeader(sellerData),
              const SizedBox(height: 24),

              // --- Seller Info ---
              _buildSellerInfo(context, sellerData),
              const SizedBox(height: 16),

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
                    return const Center(child: Text("This store has no items."));
                  }

                  // Build the list of items
                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    shrinkWrap: true, // Important inside a parent ListView
                    physics:
                        const NeverScrollableScrollPhysics(), // Parent handles scrolling
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemBuilder: (context, index) {
                      DocumentSnapshot doc = snapshot.data!.docs[index];
                      Map<String, dynamic> data =
                          doc.data() as Map<String, dynamic>;

                      return _buildItemTile(
                        context: context,
                        name: data['Name'] ?? 'No Name',
                        price: (data['Price'] as num?)?.toDouble() ?? 0.0,
                        imageUrl: data['imageUrl'] ?? 'placeholder',
                        itemId: doc.id,
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 32), // Padding at the bottom
            ],
          );
        },
      ),
    );
  }

  // --- UPDATED WIDGET ---
  // Header widget now accepts sellerData
  Widget _buildStoreHeader(Map<String, dynamic> sellerData) {
    // Get address from the seller data
    String address = sellerData['address'] ?? 'No Address Provided';

    return Column(
      children: [
        // Store Image
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12.0),
          ),
          child:
              const Icon(Icons.image_outlined, color: Colors.black, size: 48),
          // TODO: Replace with Image.network
        ),
        const SizedBox(height: 16),

        // Business Name
        Text(
          storeName,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4), // Reduced space

        // --- ADDED ADDRESS ---
        Text(
          address,
          style: const TextStyle(fontSize: 16, color: Colors.black54),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        
        // Removed Star Rating
      ],
    );
  }

  // --- UPDATED WIDGET ---
  // Now a simple widget that receives sellerData
  Widget _buildSellerInfo(
      BuildContext context, Map<String, dynamic> sellerData) {
    // Extract data
    String username = sellerData['username'] ?? 'N/A';
    String phoneNumber = sellerData['phone_number'] ?? 'N/A';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40.0), // Pill shape
          border: Border.all(color: Colors.grey[300]!), // Light border
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Seller Username
            Flexible( // Added Flexible to prevent overflow
              child: Row(
                mainAxisSize: MainAxisSize.min, // Keeps content snug
                children: [
                  Icon( // <-- ADDED ICON
                    Icons.person_outline,
                    color: Colors.grey[700],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Flexible( // Added Flexible to prevent text overflow
                    child: Text(
                      username,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[800],
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis, // Handle long text
                    ),
                  ),
                ],
              ),
            ),
            
            // Added some spacing between the two elements
            const SizedBox(width: 16), 

            // Contact Number
            Flexible( // Added Flexible to prevent overflow
              child: Row(
                mainAxisSize: MainAxisSize.min, // Keeps content snug
                children: [
                  Icon( // <-- ADDED ICON
                    Icons.phone_outlined,
                    color: Colors.grey[700],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Flexible( // Added Flexible to prevent text overflow
                    child: Text(
                      phoneNumber,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[800],
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis, // Handle long text
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

  // --- UPDATED WIDGET ---
  // Item list tile widget now has new styling
  Widget _buildItemTile({
    required BuildContext context,
    required String name,
    required double price,
    required String imageUrl,
    required String itemId,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0), // A bit less space
      // Use ListTile's built-in properties for styling
      child: ListTile(
        tileColor: Colors.grey[200], // Background color from screenshot
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        // Image
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(8.0),
          ),
          child:
              const Icon(Icons.image_outlined, color: Colors.black, size: 24),
          // TODO: Replace with ClipRRect(...)
        ),

        // Title & Price
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('RM${price.toStringAsFixed(2)}'),

        // Arrow
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // Navigate to the ItemDetailsPage
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ItemDetailsPage(
                sellerId: storeId, // Pass the storeId as the sellerId
                itemId: itemId, // Pass the specific item's ID
              ),
            ),
          );
        },
      ),
    );
  }
}


