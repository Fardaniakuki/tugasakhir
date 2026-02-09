// api_service.dart - PERBAIKAN
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://api.gedanggoreng.com/api';
  
  // Helper untuk mendapatkan token
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }
  
  // Helper untuk membuat headers dengan token
  static Future<Map<String, String>> _getHeaders({
    Map<String, String>? additionalHeaders,
  }) async {
    final token = await _getToken();
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...?additionalHeaders,
    };
    
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }
  
  // PUT method yang sudah include token
  static Future<http.Response> put(
    String endpoint,
    Map<String, dynamic> data, {
    Map<String, String>? headers,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final finalHeaders = await _getHeaders(additionalHeaders: headers);
    
    return await http.put(
      url,
      headers: finalHeaders,
      body: jsonEncode(data),
    );
  }
  
  // GET method (juga perlu diperbaiki)
  static Future<http.Response> get(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final finalHeaders = await _getHeaders(additionalHeaders: headers);
    
    return await http.get(url, headers: finalHeaders);
  }
  
  // POST method
  static Future<http.Response> post(
    String endpoint,
    Map<String, dynamic> data, {
    Map<String, String>? headers,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final finalHeaders = await _getHeaders(additionalHeaders: headers);
    
    return await http.post(
      url,
      headers: finalHeaders,
      body: jsonEncode(data),
    );
  }
  
  // DELETE method
  static Future<http.Response> delete(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final finalHeaders = await _getHeaders(additionalHeaders: headers);
    
    return await http.delete(url, headers: finalHeaders);
  }
}