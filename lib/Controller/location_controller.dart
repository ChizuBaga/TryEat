import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:huawei_location/huawei_location.dart';
import 'package:chikankan/locator.dart';
import 'package:chikankan/Model/seller_temp.dart';
import 'package:chikankan/utils/harversine.dart';

class LocationController {

  late FusedLocationProviderClient _locationService;
  final FirebaseFirestore _firestore = locator<FirebaseFirestore>();

  LocationController(){
    _locationService = locator<FusedLocationProviderClient>();
  }

  Future<Location> getLocation() async {
  LocationSettingsStates lState = await checkLocationSettings();
  try {
    if(lState.locationUsable == true){
      Location location = await _locationService.getLastLocation();
      return location;
    }else{
      throw Exception("Location not usable");
    }
  } catch (e) {
    print(e.toString());
    rethrow;
    }
  }

  //Returns a GeoPoint object
  Future<GeoPoint> getCoordinates(Future<Location> lState) async {
    Location location = await lState;
    if (location.latitude == null && location.longitude == null) {
      throw Exception("Location is NULL");
    }else {
      GeoPoint geoPoint = GeoPoint(location.latitude!, location.longitude!);
      return geoPoint;
    }
  }

  //Check location settings
  Future<LocationSettingsStates> checkLocationSettings() async {
    LocationRequest locationRequest = LocationRequest();
    LocationSettingsRequest locationSettingsRequest = LocationSettingsRequest(
    requests: <LocationRequest>[locationRequest],
    needBle: true,
    alwaysShow: true,
    );

    try{
      LocationSettingsStates states = await _locationService.checkLocationSettings(locationSettingsRequest);
      return states;
    } catch (e) {
      print(e.toString());
      rethrow;
    }
  }

  //getDistance of cus to seller
  Future<double> getDistance(SellerTemp seller) async{
    Location customerLoc = await getLocation();

    if (customerLoc.latitude == null || customerLoc.longitude == null){
      throw Exception("Customer location is null!");
    }

    GeoPoint sellerCoordinate = seller.coordinates;

    Harversine calculate = Harversine(
      customerLat: customerLoc.latitude!, 
      customerLon: customerLoc.longitude!, 
      sellerLat: sellerCoordinate.latitude,
      sellerLon: sellerCoordinate.longitude
      );

    double distance = calculate.calcDistance();
    return distance;
  }

  Future<List<DocumentSnapshot>> getNearbySellers({required double radiusKm}) async {
    try {
      // 1. Get customer's current location
      Location customerLoc = await getLocation();
      if (customerLoc.latitude == null || customerLoc.longitude == null) {
        throw Exception("Could not get customer location.");
      }

      // 2. Fetch ALL verified sellers from Firestore
      QuerySnapshot sellerSnapshot = await _firestore
          .collection('sellers') // Ensure this matches your collection name
          .where('isVerified', isEqualTo: true)
          .get();

      List<DocumentSnapshot> nearbySellers = [];

      for (var doc in sellerSnapshot.docs) {
        // Use your factory constructor to create a SellerTemp object
        SellerTemp seller = SellerTemp.fromDocument(doc);

        // Ensure seller coordinates are valid before calculating
        // Check against 0.0 or specific invalid coordinates if needed
        if (seller.coordinates.latitude != 0 || seller.coordinates.longitude != 0) { // Example check
          // Initialize Harversine with customer's location and seller's info
          Harversine calculator = Harversine(
            customerLat: customerLoc.latitude!,
            customerLon: customerLoc.longitude!,
            sellerLat: seller.coordinates.latitude,
            sellerLon: seller.coordinates.longitude,
          );

          // Calculate distance to this seller
          double distanceInKm = calculator.calcDistance();

          // 4. Add to list if within radius
          if (distanceInKm <= radiusKm) {
            nearbySellers.add(doc);
          }
        }
      }
      return nearbySellers;
    } catch (e) {
      print("Error getting nearby sellers: $e");
      rethrow; // Re-throwing allows the FutureBuilder to catch the error
    }
  }

}