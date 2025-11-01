import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class HmsPushKitService {

    
  Future<String?> getToken() async {
  final clientId = dotenv.env['HW_CLIENT_ID'];
  final clientSecret = dotenv.env['HW_CLIENT_SECRET'];

  if (clientId == null || clientSecret == null) {
    print('Missing Huawei credentials');
    return null;
  }

  final tokenUrl = Uri.parse('https://oauth-login.cloud.huawei.com/oauth2/v2/token');

  try {
    final response = await http.post(
      tokenUrl,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'client_credentials',
        'client_id': clientId.trim(),
        'client_secret': clientSecret.trim(),
      },
    );

    print('Response: ${response.body}');
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('Access Token: ${data['access_token']}');
      return data['access_token'];
    } else {
      print('Error getting token: ${response.body}');
      return null;
    }
  } catch (e) {
    print('Network error during token fetch: $e');
    return null;
  }
}

  Future<bool> sendRejectionNotification({
    required String targetToken, 
    required String orderId,
  }) async {
    final accessToken = await getToken();
    if (accessToken == null) return false;

    // Use the App ID in the push URL
    final pushUrl = Uri.parse('https://push-api.cloud.huawei.com/v1/115618973/messages:send'); 

    final notificationPayload = {
      "validate_only": false,
      "message": {
        "token": [targetToken],
        "android": {
          "notification": {
            "title": "Order Rejected: #$orderId",
            "body": "Your order has been rejected by the seller.",
            "click_action": {"type": 3}, 
            "badge": {"addNum": 1},
            "priority": "HIGH",
          }
        }
      }
    };

    try {
      final response = await http.post(
        pushUrl,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(notificationPayload),
      );

      if (response.statusCode == 200) {
        print('Push notification sent successfully.');
        print('Response: $response');
        return true;
      } else {
        print('Push API Error (${response.statusCode}): ${response.body}');
        return false;
      }
    } catch (e) {
      print('Network error during push send: $e');
      return false;
    }
  }
}