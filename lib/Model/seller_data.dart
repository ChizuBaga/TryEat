import 'package:cloud_firestore/cloud_firestore.dart';

class SellerData {
  final String? id;

  String? username;
  String? phoneNumber;
  String? email;
  String? password;
  GeoPoint? coordinates;
  String? icName;
  String? icNumber;
  String? icFrontImagePath; // Store file path or URL after upload
  String? bankStatementImagePath; // Store file path or URL after upload

  String? businessName;
  String? address;
  String? postcode;
  String? state;

  //Additional Data
  String? profileImageUrl;
  DateTime? joinDate;
  Timestamp? lastBusinessNamemodified;

  SellerData(
    
    {
    this.id,

    this.username, 
    this.phoneNumber,
    this.email,
    this.password, 
    this.coordinates,
    this.icName,
    this.icNumber,
    this.icFrontImagePath, 
    this.bankStatementImagePath,
    this.businessName,
    this.address, 
    this.postcode,
    this.state,

    this.profileImageUrl,
    this.joinDate,
    this.lastBusinessNamemodified
  });

  factory SellerData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    GeoPoint? coordinatesData;

    if (data == null) {
      throw StateError('Missing data for seller document ${doc.id}');
    }
    if (data['location'] is GeoPoint){
      coordinatesData = data['location'] as GeoPoint?;
    }

    return SellerData(
      id: doc.id,
      username: data['username'],
      phoneNumber: data['phone_number'], 
      email: data['email'],
      businessName: data['businessName'],
      address: data['address'],
      postcode: data['postcode'],
      state: data['state'],
      lastBusinessNamemodified: data['modifyBusinessNameAt'],
      joinDate: (data['created_at'] is Timestamp) ? (data['created_at'] as Timestamp).toDate() : null,
      profileImageUrl: data['profileImageUrl'],
      coordinates: coordinatesData,
    );
  }
  Map<String, dynamic> toFirestoreUpdate() {
    return {
      'username': username,
      'phone_number': phoneNumber,
      'email': email,
      'businessName': businessName,
      'address': address,
      'postcode': postcode,
      'state': state,
      'profileImageUrl': profileImageUrl,
    };
  }
}