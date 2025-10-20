// // lib/item_details_page.dart
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:chikankan/Controller/MNB_classifier.dart'; // Import your classifier

// class ItemDetailsPage extends StatelessWidget {
//   final String sellerId;
//   final String itemId;
//   const ItemDetailsPage({
//     super.key,
//     required this.sellerId,
//     required this.itemId,
//   });

//   @override
//   Widget build(BuildContext context) {
    
//     // 1. Define a reference to the specific document
//     final DocumentReference docRef = FirebaseFirestore.instance
//         .collection('Seller')
//         .doc(sellerId)
//         .collection('items')
//         .doc(itemId);

//     return Scaffold(
//       appBar: AppBar(title: const Text("Item Details")),
//       // 2. Use a FutureBuilder to fetch the data once
//       body: FutureBuilder<DocumentSnapshot>(
//         future: docRef.get(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
//           if (snapshot.hasError) {
//             return Center(child: Text("Error fetching item: ${snapshot.error}"));
//           }
//           if (!snapshot.hasData || !snapshot.data!.exists) {
//             return const Center(child: Text("Item not found."));
//           }

//           // 3. If data exists, create an Item object using our model
//           final Item item = Item.fromFirestore(snapshot.data!);

//           return ListView(
//             padding: const EdgeInsets.all(16.0),
//             children: [
//               // --- Display Name and Price ---
//               Text(item.name, style: Theme.of(context).textTheme.headlineMedium),
//               const SizedBox(height: 8),
//               Text("\$${item.price.toStringAsFixed(2)}", style: Theme.of(context).textTheme.titleLarge),
//               const Divider(height: 32),

//               // --- Placeholder for Comment Analyzer ---
//               Text("Comments Analysis", style: Theme.of(context).textTheme.titleLarge),
//               const SizedBox(height: 8),
//               Card(
//                 color: Colors.blue.shade50,
//                 child: const Padding(
//                   padding: EdgeInsets.all(12.0),
//                   // TODO: Input comments into your classifier and display the result here
                  
//                   child: Text("Analysis results will be shown here."),
//                 ),
//               ),
//               const Divider(height: 32),

//               // --- Display Raw Comments ---
//               Text("Comments", style: Theme.of(context).textTheme.titleLarge),
//               const SizedBox(height: 8),
//               // Use a Column for a short list, or ListView.builder for a long one
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: item.comments.map((comment) => Card(
//                   child: ListTile(
//                     leading: const Icon(Icons.chat_bubble_outline),
//                     title: Text(comment),
//                   ),
//                 )).toList(),
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }
//   void runPrediction(String input) {
//   try {
//     // 1. Get the Singleton instance
//     final classifier = NaiveBayesClassifier(); 

//     // 2. Call the synchronous predict function
//     final int predictedClass = classifier.predict(input);
    

//   } catch (e) {

//     print('Prediction Failed: $e'); 
//   }
// }

// }
