import 'dart:async';
import 'dart:io';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:open_download_manager/services/config.dart';

/// Responsible for communication with the back end
class Gateway {
  static HttpClient? httpClient;

  static Future<void> init() async {
    if (!await isServerRunnning) startServer();
    httpClient = HttpClient();
  }

  /// Send an HTTP request to the server
  ///
  /// [requestType] - HTTP method: 'GET', 'POST', 'PUT', 'DELETE', etc.
  /// [endpoint] - API endpoint (e.g., '/api/classify', '/status')
  /// [data] - Optional data to send in the request body (for POST, PUT, etc.)
  /// [queryParams] - Optional query parameters to append to the URL (e.g., {'limit': '10', 'offset': '0'})
  /// [timeout] - Request timeout duration (defaults to 10 seconds)
  ///
  /// Returns the parsed JSON response or null if the response is empty
  /// Throws an error if the request fails or returns a non-2xx status code
  static Future<Map<String, dynamic>?> sendRequest(
    String requestType,
    String endpoint, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParams,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      // Construct the full URL with query parameters
      final baseUrl = 'http://${Config.serverUrl}';
      Uri url;

      if (queryParams != null && queryParams.isNotEmpty) {
        // Convert all query parameter values to strings
        final queryParamsString = queryParams.map(
          (key, value) => MapEntry(key, value.toString()),
        );
        url = Uri.parse(
          '$baseUrl$endpoint',
        ).replace(queryParameters: queryParamsString);
      } else {
        url = Uri.parse('$baseUrl$endpoint');
      }

      print("Sending $requestType request to: $url");

      // Create HTTP client
      // final client = HttpClient();

      // Set a timeout for the request
      httpClient!.connectionTimeout = timeout;

      HttpClientRequest request;

      // Open the request based on the request type
      switch (requestType.toUpperCase()) {
        case 'GET':
          request = await httpClient!.getUrl(url);
          break;
        case 'POST':
          request = await httpClient!.postUrl(url);
          break;
        case 'PUT':
          request = await httpClient!.putUrl(url);
          break;
        case 'DELETE':
          request = await httpClient!.deleteUrl(url);
          break;
        case 'PATCH':
          request = await httpClient!.patchUrl(url);
          break;
        default:
          httpClient!.close();
          error("Unsupported HTTP method: $requestType");
          return null;
      }

      // Set headers
      request.headers.contentType = ContentType.json;

      // Add request body if data is provided
      if (data != null) {
        final jsonData = jsonEncode(data);
        request.write(jsonData);
        print("Request body: $jsonData");
      }

      // Send the request and get the response
      final response = await request.close();

      print("Response status: ${response.statusCode}");

      // Read the response body
      final responseBody = await response.transform(utf8.decoder).join();

      // Close the client
      httpClient?.close();

      // Check if the status code is successful (2xx)
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // If response is empty, return null
        if (responseBody.isEmpty) {
          print("Response successful but empty");
          return null;
        }

        // Try to parse JSON response
        try {
          final jsonResponse = jsonDecode(responseBody) as Map<String, dynamic>;
          print("Response JSON: $jsonResponse");
          return jsonResponse;
        } catch (e) {
          error(
            "Failed to parse JSON response: $e\n"
            "Response body: $responseBody",
          );
          return null;
        }
      } else {
        // Non-2xx status code
        error(
          "HTTP request failed with status ${response.statusCode}\n"
          "Endpoint: $endpoint\n"
          "Response: $responseBody",
        );
        return null;
      }
    } on SocketException catch (e) {
      error(
        "Network error: Cannot connect to server at ${Config.serverUrl}\n"
        "Error: $e\n"
        "Make sure the server is running.",
      );
      return null;
    } on TimeoutException catch (e) {
      error(
        "Request timeout: Server did not respond in time\n"
        "Endpoint: $endpoint\n"
        "Error: $e",
      );
      return null;
    } catch (e) {
      error("Unexpected error while sending request to $endpoint: $e");
      return null;
    }
  }

  /// Send message to server and return true if expected message is received
  static Future<bool> get isServerRunnning async {
    String serverUrl = Config.serverUrl;

    try {
      // Send a health check request to the server
      final response = await http
          .get(
            Uri.parse('$serverUrl/health'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(
            const Duration(seconds: 2),
            onTimeout: () {
              // Return a fake response on timeout
              return http.Response('Timeout', 408);
            },
          );

      // Check if the response status is 200 OK
      if (response.statusCode == 200) {
        try {
          print("Response received from server");
          // Parse the JSON response
          final data = jsonDecode(response.body);

          // Check if the response contains the expected fields
          // Expected response: {"status": "ok", "service": "open_download_manager"}
          return data['status'] == 'ok' &&
              data['service'] == 'open_download_manager';
        } catch (e) {
          // JSON parsing failed
          return false;
        }
      }

      return false;
    } on SocketException catch (_) {
      // Server is not reachable
      print("Server is not reachable");
      return false;
    } on http.ClientException catch (e) {
      // HTTP client error
      print("HTTP client exception: $e");
      return false;
    } catch (e) {
      // Any other error
      print("Unexpected error: $e");
      return false;
    }
  }

  static Future<void> startServer() {
    throw Exception("Start server logic not yet implemented!");
  }

  static void print(String message) {
    debugPrint("[GATEWAY] $message");
  }

  // Raise an error
  static void error(String description, {bool throwError = true}) {
    debugPrint("[GATEWAY] ⚠️ $description");

    // Call the log callback if set, using red color for error messages
    // _logCallback?.call("[$source] ⚠️ $description");

    if (throwError) throw Exception(description);
  }
}
