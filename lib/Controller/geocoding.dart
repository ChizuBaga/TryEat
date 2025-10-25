import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:huawei_site/huawei_site.dart';

Future<GeoPoint?> getCoordinatesFromAddress(String address) async {
  final apiKey = dotenv.env['HUAWEI_API_KEY'];
  const String rootUrl = 'https://siteapi.cloud.huawei.com/mapApi/v1/siteService/geocode';
  final String requestUrl = '$rootUrl?key=${Uri.encodeComponent(apiKey!)}';

  final Map<String, dynamic> requestBody = {
    'address': address,
    'countryCode': 'MY',
  };

  try {
    final response = await http.post(
      Uri.parse(requestUrl),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['sites'] != null && data['sites'].isNotEmpty) {
        final site = data['sites'][0];
        final lat = site['location']['lat'];
        final lng = site['location']['lng'];
        print('Address: $address');
        print('Latitude: $lat, Longitude: $lng');
        return GeoPoint(lat, lng);
      } else {
        print('No results found for "$address"');
      }
    } else {
      print('Request failed: ${response.statusCode}');
      print(response.body);
    }
  } catch (e) {
    print('Error: $e');
  }
}

// Future<GeoPoint?> getCoordinatesFromAddress(String address) async {
//   final apiKey = dotenv.env['HUAWEI_API_KEY'];
//   try {
//     SearchService searchService = await SearchService.create(
//       apiKey: apiKey,
//     );

//     final request = TextSearchRequest(
//       query: 'Jalan Bukit Bintang, Kuala Lumpur',
//       location: Coordinate(lat: 3.139, lng: 101.6869),
//       radius: 50000,
//     );

//     final response = await searchService.textSearch(request);
//     if (response.sites != null && response.sites!.isNotEmpty) {
//       final site = response.sites!.first;
//       final lat = site!.location?.lat;
//       final lng = site.location?.lng;
//       print("Lat: ${site.location?.lat}, Lng: ${site.location?.lng}");
//       return GeoPoint(lat!, lng!);
//     }

//     // Perform geocoding
//     // GeocodeResponse response = await searchService.geocode(request);

//     // if (response.sites != null && response.sites!.isNotEmpty) {
//     //   final location = response.sites!.first.location;
//     //   print('Latitude: ${location?.lat}, Longitude: ${location?.lng}');
//     // } else {
//     //   print('No results found for $address');
//     // }
//   } catch (e) {
//     print('Error: $e');
//   }
//   return null;
// }

//last time
//Call API from Photon
// Future<GeoPoint?> getCoordinateFromAddress(String query) async {
//   final encodedQuery = Uri.encodeComponent(query);
//   final url = Uri.parse(
//     'http://photon.komoot.io/api?q=$encodedQuery&lon=101.9758&lat=4.2105&zoom=12&location_bias_scale=0.1'
//   );

//   print(url);
//   final response = await http.get(url);

//   if (response.statusCode == 200) {
//     final data = jsonDecode(response.body);
//     final features = data['features'] as List;

//     final location = features
//         .where((f) => f['properties']['country'] == 'Malaysia')
//         .toList();

//     print(location);
//     if (location.isEmpty) return null;

//     final coords = location.first['geometry']['coordinates'];
//     return GeoPoint(coords[1], coords[0]);
//   } else {
//     throw Exception("Failed to load places");
//   }
// }

//Call API from Photon
// Future<GeoPoint> getCoordinateFromAddress(String query) async {
//   final url = Uri.parse(
//     'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&addressdetails=1&limit=10'
//   );

//   print(url);
//   final response = await http.get(url, headers: {
//     'User-Agent': 'JomNaikApp/1.0 (jqinnn2004@gmail.com)'
//   });

//   if (response.statusCode == 200) {
//     final data = jsonDecode(response.body);
//     data.forEach((d) => debugPrint("Country: '${d['address']['country']}'"));
//     final location = data
//       .where((d) => d['address']['country'] == 'Malaysia')
//       .toList();

//     final coords = location.first['geometry']['coordinates'];
//     return GeoPoint(coords[1], coords[0]);

//   } else {
//     debugPrint("Cant find places");
//     throw Exception("Failed to load places");
//   }
// }

//final openCageApiKey = dotenv.env['OPEN_CAGE_API']; 
// final openCageApiKey = "dee9c3e713274b78bbaa288cbc6ab086"; 
// Future<GeoPoint?> getCoordinateFromAddress(String address) async {
//   final query = "$address, Malaysia";
//   // 1. Construct the API URL
//   // We specify 'MY' (Malaysia) for better results.
//   final encodedAddress = Uri.encodeComponent(address);
//   final url = Uri.parse(
//   'https://api.opencagedata.com/geocode/v1/json?q=$encodedAddress'
//   '&key=$openCageApiKey'
//   '&countrycode=my'
//   '&limit=1'
//   '&no_annotations=1'
//   '&bounds=1.15,99.5|6.7,119.3' 
// );

//   try {
//     // 2. Send the HTTP Request
//     final response = await http.get(url);

//     if (response.statusCode == 200) {
//       // 3. Decode the JSON Response
//       final jsonBody = json.decode(response.body);
      
//       // 4. Check for results and extract coordinates
//       if (jsonBody['results'] != null && jsonBody['results'].isNotEmpty) {
//         final geometry = jsonBody['results'][0]['geometry'];
        
//         final double lat = geometry['lat'];
//         final double lng = geometry['lng'];
        
//         print('OpenCage Geocoding successful for: $address');
//         print('Latitude: $lat, Longitude: $lng');
        
//         return GeoPoint(lat, lng);
//       } else {
//         print('OpenCage Geocoding failed: No results found.');
//         return null;
//       }
//     } else {
//       print('OpenCage API Error. Status Code: ${response.statusCode}');
//       // Check response body for specific errors (like Invalid Key)
//       return null;
//     }
//   } catch (e) {
//     print('Network or Parsing Error during geocoding: $e');
//     return null;
//   }
// }

// const String googleApiKey = "AIzaSyB_wLfizkV5jye-I3RQyx9pck1WOu3YodM"; 

// Future<GeoPoint?> getCoordinateFromAddress(String address) async {
//   // 1. Construct the API URL
//   final encodedAddress = Uri.encodeComponent(address);
//   // Using the Google Maps Geocoding API endpoint
//   final url = Uri.parse(
//     'https://maps.googleapis.com/maps/api/geocode/json?address=$encodedAddress&key=$googleApiKey'
//   );

//   try {
//     // 2. Send the HTTP Request
//     final response = await http.get(url);

//     if (response.statusCode == 200) {
//       final jsonBody = json.decode(response.body);
      
//       // 3. Process the response status
//       if (jsonBody['status'] == 'OK' && jsonBody['results'].isNotEmpty) {
//         final geometry = jsonBody['results'][0]['geometry']['location'];
        
//         final double lat = geometry['lat'];
//         final double lng = geometry['lng'];
        
//         print('Google Geocoding successful for: $address');
//         print('Latitude: $lat, Longitude: $lng');
        
//         return GeoPoint(lat, lng);
//       } else {
//         // Handle API-specific errors (e.g., ZERO_RESULTS, OVER_QUERY_LIMIT)
//         print('Google Geocoding failed. Status: ${jsonBody['status']}');
//         return null;
//       }
//     } else {
//       print('Google API HTTP Error. Status Code: ${response.statusCode}');
//       return null;
//     }
//   } catch (e) {
//     print('Network or Parsing Error during geocoding: $e');
//     return null;
//   }
// }
