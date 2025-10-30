import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:huawei_location/huawei_location.dart';
import 'package:chikankan/locator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:chikankan/Model/seller_data.dart';
import 'package:chikankan/utils/harversine.dart';

class LocationController {

  late FusedLocationProviderClient _locationService;
  final FirebaseFirestore _firestore = locator<FirebaseFirestore>();

  LocationController(){
    _locationService = locator<FusedLocationProviderClient>();
  }
  
  Future<Location> getLocation() async {

    // --- 1. NEW: Check and Request App-Level Permission ---
    PermissionStatus status = await Permission.location.status;
    
    if (status.isDenied) {
      // If permission is denied, request it from the user
      status = await Permission.location.request();
    }

    if (status.isPermanentlyDenied) {
      // If user permanently denies, you must guide them to settings
      // For now, throw an error. In production, show a dialog.
      print("Location permission is permanently denied.");
      // Consider calling openAppSettings();
      throw Exception("Location permission is permanently denied. Please enable it in app settings.");
    }
    
    if (!status.isGranted) {
      // If permission is still not granted (e.g., user denied again)
      throw Exception("Location permission not granted.");
    }
    // --- END OF NEW PERMISSION CHECK ---
    
    // --- 2. Check Device Settings (Your existing logic) ---
    // This (like GPS being on) can now be checked
    LocationSettingsStates lState = await checkLocationSettings();

    try {
      if(lState.locationUsable == true){
        // --- 3. Get Location (Now you have permission) ---
        Location location = await _locationService.getLastLocation();
        return location;
      }else{
        throw Exception("Location not usable (e.g., GPS is off)");
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
    LocationRequest locationRequest = LocationRequest()..priority = LocationRequest.PRIORITY_HIGH_ACCURACY;
    LocationSettingsRequest locationSettingsRequest = LocationSettingsRequest(
    requests: <LocationRequest>[locationRequest],
    needBle: false,
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
  Future<double> getDistance(SellerData seller) async{
    Location customerLoc = await getLocation();

    if (customerLoc.latitude == null || customerLoc.longitude == null){
      throw Exception("Customer location is null!");
    }
    
    GeoPoint sellerCoordinate = seller.coordinates ?? GeoPoint(0,0);

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
        SellerData seller = SellerData.fromFirestore(doc);
        if (seller.coordinates != null && (seller.coordinates!.latitude != 0 || seller.coordinates!.longitude != 0)) { // Example check
          // Initialize Harversine with customer's location and seller's info
          Harversine calculator = Harversine(
            customerLat: customerLoc.latitude!,
            customerLon: customerLoc.longitude!,
            sellerLat: seller.coordinates!.latitude,
            sellerLon: seller.coordinates!.longitude,
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