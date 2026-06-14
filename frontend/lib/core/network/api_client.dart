import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiClient {
  static final _storage = const FlutterSecureStorage();

  static String get _baseUrl {
    return dotenv.env['BACKEND_URL'] ?? 'http://127.0.0.1:8080/api';
  }

  static Future<Map<String, String>> _getHeaders([Map<String, String>? extraHeaders]) async {
    final token = await _storage.read(key: 'jwt_token');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Bypass-Tunnel-Reminder': 'true',
      if (token != null) 'Authorization': 'Bearer $token',
      ...?extraHeaders,
    };
  }

  static Future<http.Response> get(String path, {Map<String, String>? headers}) async {
    final mergedHeaders = await _getHeaders(headers);
    return http.get(Uri.parse('$_baseUrl$path'), headers: mergedHeaders);
  }

  static Future<http.Response> post(String path, {Object? body, Map<String, String>? headers}) async {
    final mergedHeaders = await _getHeaders(headers);
    return http.post(
      Uri.parse('$_baseUrl$path'),
      headers: mergedHeaders,
      body: body != null ? jsonEncode(body) : null,
    );
  }

  static Future<http.Response> put(String path, {Object? body, Map<String, String>? headers}) async {
    final mergedHeaders = await _getHeaders(headers);
    return http.put(
      Uri.parse('$_baseUrl$path'),
      headers: mergedHeaders,
      body: body != null ? jsonEncode(body) : null,
    );
  }

  static Future<http.Response> delete(String path, {Map<String, String>? headers}) async {
    final mergedHeaders = await _getHeaders(headers);
    return http.delete(Uri.parse('$_baseUrl$path'), headers: mergedHeaders);
  }
}
