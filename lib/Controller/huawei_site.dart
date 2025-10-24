import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

Future<GeoPoint?> findingforwardGeocoding(String address) async {
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
