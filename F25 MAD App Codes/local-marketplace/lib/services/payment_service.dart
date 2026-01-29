import 'dart:convert';
import 'package:http/http.dart' as http;

class PolarPaymentService {
  // Use your token from sandbox.polar.sh
  static const String _accessToken = 'polar_oat_0T0gMpyTMnsjBzOrB74GgOoFYEJQlwTyOIK9Z1j4zFi';
  static const String _baseUrl = 'https://sandbox-api.polar.sh/v1';

  Future<Map<String, dynamic>> processPayment({
    required double amount,
    required String currency,
    required String description,
    required Map<String, dynamic> metadata,
    required String paymentMethod,
  }) async {
    try {
      print('🚀 Starting Polar Transaction: $description');

      // FIXED:
      // 1. Changed success_url to https (you can handle redirect back to app via web)
      // 2. Changed structure to use 'product_price_id' instead of generic product_name
      final response = await http.post(
        Uri.parse('$_baseUrl/checkouts/custom/'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          // IMPORTANT: Replace this with a real Price ID from your Sandbox Dashboard
          // Go to Sandbox -> Products -> Price -> Copy ID (starts with 'pr_...')
          'product_id': '4405406b-e3ba-42df-9714-7967e3186808',

          'success_url': 'https://example.com/success', // Must be https
          'metadata': {
            ...metadata,
            'test_mode': 'true',
          },
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        print('✅ Checkout Session Created: ${data['id']}');

        // Return success and the URL for testing
        return {
          'success': true,
          'transactionId': data['id'],
          'url': data['url'],
          'status': data['status'],
        };
      } else {
        print('❌ Polar API Error: ${response.body}');
        return {
          'success': false,
          'error': 'Validation Error: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ Polar Service Exception: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
}