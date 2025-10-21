import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chikankan/View/ItemDetail_View.dart'; // Import the details page we will create next

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Define the reference to your Firestore collection
    final Stream<QuerySnapshot> itemsStream = FirebaseFirestore.instance
        .collection('Seller')
        .doc('Seller1')
        .collection('items')
        .limit(2) // We only want to display 2 items
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text("Menu")),
      // 2. Use a StreamBuilder to listen for real-time updates
      body: StreamBuilder<QuerySnapshot>(
        stream: itemsStream,
        builder: (context, snapshot) {
          // Handle loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // Handle error state
          if (snapshot.hasError) {
            return Center(child: Text("Something went wrong: ${snapshot.error}"));
          }
          // Handle empty state
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No items found."));
          }

          // 3. If data exists, display it in a ListView
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              // Get the document for the current item
              DocumentSnapshot doc = snapshot.data!.docs[index];
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(doc['Name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("\$${doc['Price'].toStringAsFixed(2)}"),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // 4. Navigate to the ItemDetailsPage on tap
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ItemDetailsPage(
                          sellerId: "Seller1", // Pass the IDs needed
                          itemId: doc.id,       // Pass the unique document ID
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}