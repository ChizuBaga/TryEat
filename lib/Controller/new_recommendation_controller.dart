import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chikankan/locator.dart';

class NewRecommendationController {

  final FirebaseFirestore _firestore = locator<FirebaseFirestore>();

  final Timestamp twentyEightDaysAgoTimeStamp = Timestamp.fromDate(
    DateTime.now().subtract(const Duration(days: 28)),
  );
  
  Future<List<DocumentSnapshot>> getRecentlyCreatedSellers() async {
    try {
      // 1. Build the query
      Query query = _firestore
          .collection('items')
          .where('createdAt', isGreaterThanOrEqualTo: twentyEightDaysAgoTimeStamp) // Filter by date
          .orderBy('createdAt', descending: true); // Show newest first

      // 3. Execute the query ONCE using .get()
      final QuerySnapshot querySnapshot = await query.get();

      // 4. Return the list of documents
      return querySnapshot.docs;
    } catch (e) {
      print("Error fetching recently created sellers: $e");
      return [];
    }
  }
}