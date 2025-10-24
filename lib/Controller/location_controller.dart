import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:huawei_location/huawei_location.dart';
import 'package:chikankan/locator.dart';


class LocationController {

  late FusedLocationProviderClient _locationService;
  
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


}