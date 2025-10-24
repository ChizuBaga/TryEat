import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chikankan/Model/item_model.dart'; // Import your model
import 'package:chikankan/Controller/mnb_classifier.dart'; // Import your classifier
import 'package:chikankan/locator.dart';
import 'package:chikankan/Controller/gemini.dart';
import 'dart:math' as math;

class ItemDetailsPage extends StatelessWidget {
  final String sellerId;
  final String itemId;
  const ItemDetailsPage({
    super.key,
    required this.sellerId,
    required this.itemId,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Define a reference to the specific document
    final DocumentReference docRef = FirebaseFirestore.instance
        .collection('items')
        .doc(itemId);

    return Scaffold(
      appBar: AppBar(title: const Text("Item Details"), centerTitle: true),
      // 2. Use a FutureBuilder to fetch the data once
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
          // 3. If data exists, create an Item object using our model
          final Item item = Item.fromFirestore(snapshot.data!);

          // --- 4. Perform sentiment analysis (Your existing code) ---
          final classifier = locator<NaiveBayesClassifier>();
          int positiveCount = 0;
          double positivePercentage = 0.0;
          double negativePercentage = 0.0;

          if (item.comments!.isNotEmpty) {
            for (final comment in item.comments ?? []) {
              if (classifier.predict(comment) == 1) {
                positiveCount++;
              }
            }
            positivePercentage = (positiveCount / item.comments!.length) * 100;
            negativePercentage = 100 - positivePercentage;
          }

          // --- 5. NEW: Prepare latest 10 comments for Gemini ---
          // Get the last 10 comments from the list
          final latest10Comments = item.comments!.sublist(
            math.max(0, item.comments!.length - 10),
          );
          // Join them into a single string
          final String commentsText = latest10Comments.join("\n- ");

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // --- Display Name and Price ---
              Text(
                item.name,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                "RM${item.price.toStringAsFixed(2)}",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Divider(height: 32),

              // --- Comments Analyzer Widget ---
              Text(
                "Comments Analysis",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16.0,
                    horizontal: 8.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // --- Good Reviews Column ---
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              '${positivePercentage.toStringAsFixed(0)}%',
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            const Text("👍 Good Reviews"),
                          ],
                        ),
                      ),
                      // --- Bad Reviews Column ---
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              '${negativePercentage.toStringAsFixed(0)}%',
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    color: Colors.red.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            const Text("👎 Bad Reviews"),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 32),

              // --- 6. NEW: AI Summary Section ---
              Text(
                "✨ AI Summary",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),

              // This new widget will handle its own loading state
              _GeminiSummaryWidget(commentsText: commentsText),
              const Divider(height: 32),

              // --- Display Raw Comments ---
              Text("Comments", style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: item.comments!
                    .map(
                      (comment) => Card(
                        child: ListTile(
                          leading: const Icon(Icons.chat_bubble_outline),
                          title: Text(comment),
                        ),
                      ),
                    )
                    .toList(),
              ),

              const SizedBox(height: 30),

              
            ],
          );
        },
      ),
    );
  }
}

class _GeminiSummaryWidget extends StatefulWidget {
  final String commentsText;
  const _GeminiSummaryWidget({required this.commentsText});

  @override
  State<_GeminiSummaryWidget> createState() => _GeminiSummaryWidgetState();
}

class _GeminiSummaryWidgetState extends State<_GeminiSummaryWidget> {
  // This Future will store the result of the Gemini API call
  late Future<String> _summaryFuture;
  final GeminiService _geminiService = GeminiService();

  @override
  void initState() {
    super.initState();
    // Start the API call once when the widget is created
    _callGemini();
  }

  void _callGemini() {
    // --- TEMPORARY DISABLE ---
    // Instantly set the future to a disabled message.
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
    // We use a FutureBuilder to display the summary
    // It will show a loading indicator, then the result
    return FutureBuilder<String>(
      future: _summaryFuture,
      builder: (context, snapshot) {
        // --- State 1: Still Loading ---
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            elevation: 0,
            color: Color.fromARGB(255, 241, 241, 241),
            child: Padding(
              padding: EdgeInsets.all(12.0),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                  SizedBox(width: 16),
                  Text("AI is generating summary..."),
                ],
              ),
            ),
          );
        }

        // --- State 2: An Error Occurred ---
        if (snapshot.hasError) {
          return const Card(
            color: Color.fromARGB(255, 255, 234, 237),
            child: Padding(
              padding: EdgeInsets.all(12.0),
              child: Text("Error generating summary."),
            ),
          );
        }

        // --- State 3: Data Loaded Successfully ---
        return Card(
          elevation: 0,
          color: const Color.fromARGB(255, 241, 241, 241),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            // Display the summary text from Gemini
            child: Text(
              snapshot.data ?? "No summary available.",
              style: const TextStyle(height: 1.4),
            ),
          ),
        );
      },
    );
  }
}
