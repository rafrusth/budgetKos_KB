import 'dart:io' show Platform;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiClient {
  static const String _tunnelUrl = 'https://5998ef30b503bd.lhr.life/api/v1';

  static String get _baseUrl {
    // 1. If testing on Chrome (Web), localhost works perfectly.
    if (kIsWeb) return 'http://localhost:8081/api/v1';

    // Force tunnel URL for Android to prevent Connection Refused on Physical Devices
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
