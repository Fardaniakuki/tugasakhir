// lib/services/api_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  // Base URL dari environment
  static String get baseUrl {
    final url = dotenv.get('API_BASE_URL', fallback: 'https://api.gedanggoreng.com');
    return url.endsWith('/api') ? url : '$url/api';
  }

  // GET request tanpa auth (untuk data sekolah yang public)
  static Future<http.Response> get(String endpoint) async {
    try {
      debugPrint('API GET: $baseUrl$endpoint');
      
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');
      
      return response;
    } catch (e) {
      debugPrint('Error in GET request: $e');
      rethrow;
    }
  }

  // PUT request tanpa auth
  static Future<http.Response> put(String endpoint, Map<String, dynamic> data) async {
    try {
      debugPrint('API PUT: $baseUrl$endpoint');
      debugPrint('Data: $data');
      
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(data),
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');
      
      return response;
    } catch (e) {
      debugPrint('Error in PUT request: $e');
      rethrow;
    }
  }

  // GET request dengan auth token (jika diperlukan)
  static Future<http.Response> getWithAuth(String endpoint, String token) async {
    try {
      debugPrint('API GET with Auth: $baseUrl$endpoint');
      
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('Response status: ${response.statusCode}');
      
      return response;
    } catch (e) {
      debugPrint('Error in GET with Auth request: $e');
      rethrow;
    }
  }
}