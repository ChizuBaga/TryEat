import 'package:http/http.dart' as http;
import 'package:huawei_location/huawei_location.dart';

FusedLocationProviderClient locationService = FusedLocationProviderClient();

Future<Location> checkLocation() async {
  LocationSettingsStates lState = await checkLocationSettings();

  try {
    if(lState.locationUsable == true){
      Location location = await locationService.getLastLocation();
      return location;
    }else{
      throw Exception("Location not usable");
    }
  } catch (e) {
    print(e.toString());
    rethrow;
  }
}

Future<LocationSettingsStates> checkLocationSettings() async {
  LocationRequest locationRequest = LocationRequest();
  LocationSettingsRequest locationSettingsRequest = LocationSettingsRequest(
  requests: <LocationRequest>[locationRequest],
  needBle: true,
  alwaysShow: true,
  );

  try{
    LocationSettingsStates states = await locationService.checkLocationSettings(locationSettingsRequest);
    return states;
  } catch (e) {
    print(e.toString());
    rethrow;
  }
}