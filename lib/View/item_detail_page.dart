import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chikankan/Model/item_model.dart'; 
import 'package:chikankan/Controller/mnb_classifier.dart'; 
import 'package:chikankan/locator.dart';
import 'package:chikankan/Controller/gemini.dart';
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

  void _addToCart(Item item) {
    print(
        'Adding ${item.name} (x$_quantity) to cart. Total: ${item.price * _quantity}');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.all(14),
          height: 50, 
          child: Center(
            child: Text(
              '✅ ${item.name} (x$_quantity) added to cart!',
              style: const TextStyle(
                fontSize: 16,
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

          // Perform sentiment analysis
          final classifier = locator<NaiveBayesClassifier>();
          int positiveCount = 0;
          double positivePercentage = 0.0;
          double negativePercentage = 0.0;

          if (item.comments != null && item.comments!.isNotEmpty) {
            for (final comment in item.comments!) {
              if (classifier.predict(comment) == 1) {
                positiveCount++;
              }
            }
            positivePercentage = (positiveCount / item.comments!.length) * 100;
            negativePercentage = 100 - positivePercentage;
          }

          // Prepare latest 10 comments for Gemini
          final latest10Comments = item.comments != null
              ? item.comments!.sublist(
                  math.max(0, item.comments!.length - 10),
                )
              : <String>[]; // Empty list if comments are null
          final String commentsText = latest10Comments.join("\n- ");

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

                    // --- Name, Description, Price ---
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
                      item.orderType ?? 'N/A',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.black87,
                        fontStyle: FontStyle.italic,
                        fontSize: 20,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 16),
                    Text(
                      "RM${item.price.toStringAsFixed(2)}",
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 24),

                    // --- Comments Analysis ---
                    Card(
                      elevation: 2,
                      color: const Color.fromARGB(255, 252, 248, 221),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                             Text(
                              "Comment Analysis",
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                             const SizedBox(height: 12),
                             Container( // Inner container for results
                               padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
                               decoration: BoxDecoration(
                                 color: const Color.fromARGB(255, 255, 254, 246),
                                 borderRadius: BorderRadius.circular(8.0),
                               ),
                               child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  // Good Reviews
                                  Column(
                                    children: [
                                      Text(
                                        '${positivePercentage.toStringAsFixed(0)}%',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall
                                            ?.copyWith(
                                              color: Colors.green.shade700,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text("👍 Good", style: TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                  // Divider
                                  Container(height: 40, width: 1, color: Colors.grey[300]),
                                  // Bad Reviews
                                  Column(
                                    children: [
                                      Text(
                                        '${negativePercentage.toStringAsFixed(0)}%',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall
                                            ?.copyWith(
                                              color: Colors.red.shade700,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
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

                    // --- Comments with AI Summary ---
                    Card(
                       elevation: 2,
                       color: const Color.fromARGB(255, 252, 248, 221),
                       shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        side: BorderSide(color: Colors.grey[300]!), // Border
                      ),
                       child: Padding(
                         padding: const EdgeInsets.all(16.0),
                         child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                              Text(
                                "Comments",
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "✨ AI Summary",
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              // AI Summary Widget (Handles its own loading/error)
                              _GeminiSummaryWidget(commentsText: commentsText),
                              
                           ],
                         ),
                       ),
                    ),
                    const SizedBox(height: 20), 
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

