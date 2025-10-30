import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:huawei_push/huawei_push.dart';

class HmsPushKitService {

    
    Future<String?> getToken() async {
    final HW_CLIENT_ID = dotenv.env['HW_CLIENT_ID'];
    final HW_CLIENT_SECRET = dotenv.env['HW_CLIENT_SECRET'];
    final tokenUrl = Uri.parse('https://oauth-login.cloud.huawei.com/oauth2/v3/token');
    
    try {
      final response = await http.post(
        tokenUrl,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'client_credentials',
          'client_id': HW_CLIENT_ID,
          'client_secret': HW_CLIENT_SECRET,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print(data['access_token']);
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
            "clickAction": {"type": 3}, 
            "badge": {"addNum": 1},
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