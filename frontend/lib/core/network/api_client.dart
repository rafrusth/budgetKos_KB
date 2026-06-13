import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiClient {
  /* ==================== Input from Cloudflare (/api/v1) ==================== */
  static const String _tunnelUrl =
      'https://exciting-drops-instruction-municipal.trycloudflare.com/api/v1';

  static String get _baseUrl {
    if (kIsWeb) return 'http://localhost:8081/api/v1';
    return _tunnelUrl;
  }

  static Dio get instance {
    return Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Bypass-Tunnel-Reminder': 'true', // Required for localtunnel
        },
      ),
    );
  }
}
