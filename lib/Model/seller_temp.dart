import 'package:cloud_firestore/cloud_firestore.dart';

class SellerTemp{
  String address;
  GeoPoint coordinates;

  SellerTemp({
    required this.address,
    required this.coordinates,
  });
  
  factory SellerTemp.fromDocument(DocumentSnapshot doc){
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return SellerTemp(
      address: data['Address'] ?? '',
      coordinates: data['Coordinates'] ?? GeoPoint(0,0),
    );
  }
}


