import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chikankan/Model/item_model.dart'; 
import 'package:chikankan/Controller/mnb_classifier.dart'; 
import 'package:chikankan/locator.dart';
import 'package:chikankan/Controller/gemini.dart';
import 'package:chikankan/Controller/cart_controller.dart';
import 'dart:math' as math;

class ItemDetailsPage extends StatefulWidget {
  final String sellerId;
  final String itemId;
  const ItemDetailsPage({
    super.key,
    required this.sellerId,
    required this.itemId,
  });

  @override
  State<ItemDetailsPage> createState() => _ItemDetailsPageState();
}

class _ItemDetailsPageState extends State<ItemDetailsPage> {
  int _quantity = 1;
  final CartService _cartService = locator<CartService>();

  void _incrementQuantity() {
    setState(() {
      _quantity++;
    });
  }

  void _decrementQuantity() {
    setState(() {
      if (_quantity > 1) {
        _quantity--;
      }
    });
  }

  Widget _buildChip(String label, {IconData? icon}) { 
    return Container(
      padding: EdgeInsets.symmetric(horizontal: icon != null ? 8.0 : 12.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey,
            spreadRadius: 1, blurRadius: 2, offset: const Offset(0, 1),
          ),
        ]
      ),
      child: Row( 
        mainAxisSize: MainAxisSize.min, 
        children: [
          if (icon != null)
            Icon(
              icon,
              size: 18, 
              color: Colors.grey[700],
            ),
          if (icon != null) 
            const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _addToCart(Item item) {
    _cartService.addItem(item, _quantity);
    
    print('Adding ${item.name} (x$_quantity) to cart. Total: ${item.price * _quantity}');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.all(10),
          height: 40, 
          child: Center(
            child: Text(
              '✅ ${item.name} (x$_quantity) added to cart!',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 8,
        duration: const Duration(seconds: 2),
      ),
    );
    Navigator.pop(context);
  }


  @override
  Widget build(BuildContext context) {
    final DocumentReference docRef = FirebaseFirestore.instance
        .collection('items')
        .doc(widget.itemId);
    final CollectionReference commentsColRef = docRef.collection('comments');

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 254, 246),
      appBar: AppBar(
        title: const Text("Item Details", style: TextStyle(fontWeight: FontWeight.bold),),
        centerTitle: true,
        backgroundColor: Color.fromARGB(255, 255, 229, 143), 
        elevation: 0, 
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: docRef.get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text("Error fetching item: ${snapshot.error}"),
            );
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Item not found."));
          }

          final Item item = Item.fromFirestore(snapshot.data!);

          String orderTypeText;
          IconData? orderTypeIcon;
          final String? fetchedOrderType = item.orderType;
          if (fetchedOrderType != null && fetchedOrderType.toLowerCase() == 'pre-order') {
            final int reservedDays = item.reservedDays ?? 0;
            orderTypeText = 'Pre-order: ${reservedDays}d';
            orderTypeIcon = Icons.calendar_today_outlined; // Calendar icon
          } else if (fetchedOrderType != null && fetchedOrderType.toLowerCase() == 'instant') {
            orderTypeText = 'Instant';
            orderTypeIcon = Icons.bolt; // Bolt/Flash icon
          } else {
            orderTypeText = fetchedOrderType ?? 'N/A';
            orderTypeIcon = null; // No specific icon
          }

          String deliveryModeText = item.deliveryMode;
          IconData? deliveryModeIcon;
          final String deliveryModeLower = deliveryModeText.toLowerCase();
          if (deliveryModeLower.contains('delivery')) {
             deliveryModeIcon = Icons.directions_car_outlined;
          } else if (deliveryModeLower.contains('meet-up') || deliveryModeLower.contains('meetup')) {
             deliveryModeIcon = Icons.people_outline;
          } else if (deliveryModeLower.contains('self-collection') || deliveryModeLower.contains('pickup')) {
             deliveryModeIcon = Icons.storefront_outlined;
          } else if (deliveryModeLower.contains('3rd party') || deliveryModeLower.contains('third party')) {
             deliveryModeIcon = Icons.local_shipping_outlined; 
          } else {
             deliveryModeIcon = Icons.help_outline; 
          }

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0), 
                  children: [
                    // --- Item Image ---
                    Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 20.0),
                        width: MediaQuery.of(context).size.width * 0.5,
                        height: MediaQuery.of(context).size.width * 0.5,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12.0),
                          child: (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                              ? Image.network(
                                  item.imageUrl!,
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
                                    // Error placeholder
                                    return Container(
                                      color: Colors.grey[200],
                                      child: Icon(Icons.broken_image_outlined,
                                          color: Colors.grey[400], size: 60),
                                    );
                                  },
                                )
                              : Container( 
                                  color: Colors.grey[200],
                                  child: Icon(Icons.image_outlined,
                                      color: Colors.grey[400], size: 60),
                                ),
                        ),
                      ),
                    ),

                    // --- Name, Description, Price, ordertype, delivery mode ---
                    Text(
                      item.name,
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.description ?? 'No description available.',
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(color: Colors.grey[600]),
                      textAlign: TextAlign.center, // Center text
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),

                    Text(
                      "RM${item.price.toStringAsFixed(2)}",
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildChip(orderTypeText, icon: orderTypeIcon), 
                        const SizedBox(width: 10),
                        _buildChip(deliveryModeText, icon: deliveryModeIcon), 
                      ],
                    ),

                    const SizedBox(height: 20),
                  StreamBuilder<QuerySnapshot>(
                    stream: commentsColRef.snapshots(), // Stream the subcollection
                    builder: (context, commentsSnapshot) {
                      if (commentsSnapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20.0),
                          child: Center(child: Text("Loading comments...")),
                        );
                      }
                      if (commentsSnapshot.hasError) {
                        return Center(child: Text("Error loading comments: ${commentsSnapshot.error}"));
                      }

                      // --- Process Comments ---
                      final List<DocumentSnapshot> commentDocs = commentsSnapshot.data?.docs ?? []; // Handle null data
                      final List<String> commentDescriptions = commentDocs
                          .map((doc) => (doc.data() as Map<String, dynamic>)['description'] as String? ?? '')
                          .where((desc) => desc.isNotEmpty)
                          .toList();

                      // --- Perform Sentiment Analysis (moved inside) ---
                      final classifier = locator<NaiveBayesClassifier>();
                      int positiveCount = 0;
                      double positivePercentage = 0.0;
                      double negativePercentage = 0.0;

                      if (commentDescriptions.isNotEmpty) {
                        for (final comment in commentDescriptions) {
                          if (classifier.predict(comment) == 1) {
                            positiveCount++;
                          }
                        }
                        positivePercentage = (positiveCount / commentDescriptions.length) * 100;
                        negativePercentage = 100 - positivePercentage;
                      }

                      // --- Prepare comments for Gemini (moved inside) ---
                      final latest10Comments = commentDescriptions.sublist(
                        math.max(0, commentDescriptions.length - 10),
                      );
                      final String commentsText = latest10Comments.join("\n- ");

                      // --- Return the Widgets for Analysis and Comments List ---
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- Comments Analysis Card ---
                          Card(
                            elevation: 2,
                            color: const Color.fromARGB(255, 252, 248, 221),
                            shape: RoundedRectangleBorder( /* ... */ ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Comment Analysis", /* ... style ... */),
                                  const SizedBox(height: 12),
                                  Container( // Inner container
                                    padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
                                    decoration: BoxDecoration( /* ... */ ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        // Good Reviews Column
                                        Column(
                                          children: [
                                            Text('${positivePercentage.toStringAsFixed(0)}%', /* ... style ... */),
                                            const SizedBox(height: 4),
                                            const Text("👍 Good", style: TextStyle(fontSize: 12)),
                                          ],
                                        ),
                                        Container(height: 40, width: 1, color: Colors.grey[300]), // Divider
                                        // Bad Reviews Column
                                        Column(
                                          children: [
                                            Text('${negativePercentage.toStringAsFixed(0)}%', /* ... style ... */),
                                            const SizedBox(height: 4),
                                            const Text("👎 Bad", style: TextStyle(fontSize: 12)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // --- Comments with AI Summary Card ---
                          Card(
                            elevation: 1,
                            color: const Color.fromARGB(255, 252, 248, 221),
                            shape: RoundedRectangleBorder( /* ... */ ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Comments (${commentDocs.length})", /* ... style ... */), // Display count
                                  const SizedBox(height: 12),
                                  Text("✨ AI Summary", /* ... style ... */),
                                  const SizedBox(height: 8),
                                  _GeminiSummaryWidget(commentsText: commentsText), // Assumes this widget exists
                                  const SizedBox(height: 16), // Spacing before list

                                  // --- Display Comments List ---
                                  if (commentDocs.isEmpty)
                                    const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 16.0),
                                      child: Center(child: Text("No comments yet.")),
                                    )
                                  else
                                    ListView.builder(
                                      shrinkWrap: true, // Crucial for nested lists
                                      physics: const NeverScrollableScrollPhysics(), // Crucial
                                      itemCount: commentDocs.length,
                                      itemBuilder: (context, index) {
                                        final commentData = commentDocs[index].data() as Map<String, dynamic>;
                                        final description = commentData['description'] ?? 'No comment';
                                        return ListTile( // Simpler display within the card
                                          leading: const Icon(Icons.person_outline, size: 20),
                                          title: Text(description),
                                          dense: true,
                                        );
                                      },
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          ],
                        );
                      },
                    ),    
                  ],
                ),
              ), 

              // --- Fixed Bottom Bar ---
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0).copyWith(
                  bottom: MediaQuery.of(context).padding.bottom + 12.0 
                ),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 255, 254, 246),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black,
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column( 
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        //- button
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: _decrementQuantity,
                          iconSize: 28,
                          color: _quantity > 1 ? Colors.black : Colors.grey, // Disable visually if 1
                        ),
                        const SizedBox(width: 24),
                        // Quantity Display
                        Text(
                          '$_quantity',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 24),
                        //+ button
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: _incrementQuantity,
                          iconSize: 28,
                          color: Colors.black,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // --- Add to Cart Button ---
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _addToCart(item),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromARGB(255, 255, 153, 0),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          elevation: 5,
                        ),
                        child: const Text(
                          'Add to Cart',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// --- Gemini Summary Widget  ---
class _GeminiSummaryWidget extends StatefulWidget {
  final String commentsText;
  const _GeminiSummaryWidget({required this.commentsText});

  @override
  State<_GeminiSummaryWidget> createState() => _GeminiSummaryWidgetState();
}

class _GeminiSummaryWidgetState extends State<_GeminiSummaryWidget> {
  late Future<String> _summaryFuture;
  final GeminiService _geminiService = GeminiService();

  @override
  void initState() {
    super.initState();
    _callGemini();
  }

  void _callGemini() {
     // --- TEMPORARY DISABLE ---
     _summaryFuture = Future.value("AI Summary is temporarily disabled.");

    /* --- ORIGINAL CODE (now commented out) ---
    if (widget.commentsText.trim().isEmpty) {
      _summaryFuture = Future.value("No comments found to summarize.");
    } else {
      _summaryFuture = _geminiService.summarizeComments(widget.commentsText);
    }
    */
  }


  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _summaryFuture,
      builder: (context, snapshot) {
        // --- State 1: Still Loading ---
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
             padding: const EdgeInsets.all(12.0),
             decoration: BoxDecoration(
               color: Color.fromARGB(255, 255, 254, 246),
               borderRadius: BorderRadius.circular(8.0),
             ),
            child: const Row(
              children: [
                SizedBox(
                  width: 16, height: 16, 
                  child: CircularProgressIndicator(strokeWidth: 2.0),
                ),
                SizedBox(width: 12),
                Text("AI is generating summary...", style: TextStyle(color: Colors.black54)),
              ],
            ),
          );
        }

        // --- State 2: An Error Occurred ---
        if (snapshot.hasError) {
          return Container(
             padding: const EdgeInsets.all(12.0),
             decoration: BoxDecoration(
               color: Colors.red[50],
               borderRadius: BorderRadius.circular(8.0),
             ),
            child: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 18),
                 SizedBox(width: 12),
                Text("Error generating summary.", style: TextStyle(color: Colors.red)),
              ],
            ),
          );
        }

        // --- State 3: Data Loaded Successfully ---
        return Container(
           padding: const EdgeInsets.all(12.0),
           decoration: BoxDecoration(
             color: Color.fromARGB(255, 255, 254, 246),
             borderRadius: BorderRadius.circular(8.0),
           ),
          child: Text(
            snapshot.data ?? "No summary available.",
            style: const TextStyle(height: 1.4, color: Colors.black87), 
          ),
        );
      },
    );
  }
}

