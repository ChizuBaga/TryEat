import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chikankan/locator.dart';

class NewRecommendationController {

  final FirebaseFirestore _firestore = locator<FirebaseFirestore>();

  final Timestamp twentyEightDaysAgoTimeStamp = Timestamp.fromDate(
    DateTime.now().subtract(const Duration(days: 28)),
  );
  
  Future<List<DocumentSnapshot>> getRecentlyCreatedSellers() async {
    try {
      Query query = _firestore
          .collection('items')
          .where('createdAt', isGreaterThanOrEqualTo: twentyEightDaysAgoTimeStamp)
          .orderBy('createdAt', descending: true);

      final QuerySnapshot querySnapshot = await query.get();
      return querySnapshot.docs;
    } catch (e) {
      print("Error fetching recently created sellers: $e");
      return [];
    }
  }
}