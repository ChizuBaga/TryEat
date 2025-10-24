import 'package:huawei_site/huawei_site.dart';

Future<void> getCoordinatesFromAddress(String address) async {
  try {
    SearchService searchService = await SearchService.create(
      apiKey: "YOUR_API_KEY", 
    );

    // Create a GeocodeRequest
    GeocodeRequest request = GeocodeRequest(
      query: address,
      countryCode: "MY",
      language: "en",
    );

    // Send the request
    GeocodeResponse response = await searchService.geocode(request);

    if (response.sites != null && response.sites!.isNotEmpty) {
      double lat = response.sites!.first.location!.lat!;
      double lng = response.sites!.first.location!.lng!;
      
      print('Address: $address');
      print('Latitude: $lat, Longitude: $lng');
    } else {
      print("No results found for address: $address");
    }
  } catch (e) {
    print("Error during geocoding: $e");
  }
}