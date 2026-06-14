import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileData {
  final String name;
  final String email;
  final String campus;
  final String password;

  ProfileData({this.name = 'Mahasiswa', this.email = 'anak_kos@university.edu', this.campus = '', this.password = 'password123'});
}

class ProfileNotifier extends ValueNotifier<ProfileData> {
  ProfileNotifier() : super(ProfileData()) {
    load();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_name') ?? 'Mahasiswa';
    final email = prefs.getString('user_email') ?? 'anak_kos@university.edu';
    final campus = prefs.getString('user_campus_location') ?? '';
    final password = prefs.getString('user_password') ?? 'password123';
    value = ProfileData(name: name, email: email, campus: campus, password: password);
  }

  Future<void> updateProfile(String name, String email, String campus, [String? password]) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    await prefs.setString('user_email', email);
    await prefs.setString('user_campus_location', campus);
    
    if (password != null && password.isNotEmpty) {
      await prefs.setString('user_password', password);
    }
    
    final currentPassword = prefs.getString('user_password') ?? 'password123';
    value = ProfileData(name: name, email: email, campus: campus, password: currentPassword);
  }
}

final profileNotifier = ProfileNotifier();
