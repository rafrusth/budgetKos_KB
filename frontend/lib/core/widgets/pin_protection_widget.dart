import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:budget_kos/core/utils/toast_helper.dart';

class PinProtectionWidget extends StatefulWidget {
  final Widget child;

  const PinProtectionWidget({super.key, required this.child});

  @override
  State<PinProtectionWidget> createState() => _PinProtectionWidgetState();
}

class _PinProtectionWidgetState extends State<PinProtectionWidget> {
  bool _isLoading = true;
  bool _isAuthenticated = false;
  String? _savedPin;
  final TextEditingController _pinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkPin();
  }

  Future<void> _checkPin() async {
    final prefs = await SharedPreferences.getInstance();
    final pin = prefs.getString('app_pin');
    setState(() {
      _savedPin = pin;
      _isAuthenticated = pin == null || pin.isEmpty;
      _isLoading = false;
    });
  }

  void _verifyPin() {
    if (_pinController.text == _savedPin) {
      setState(() {
        _isAuthenticated = true;
      });
    } else {
      ToastHelper.showError(context, 'PIN Salah!');
      _pinController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_isAuthenticated) {
      return widget.child;
    }

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 80, color: Colors.blueAccent),
              const SizedBox(height: 24),
              const Text('Aplikasi Terkunci', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Masukkan PIN Anda untuk melanjutkan', textAlign: TextAlign.center),
              const SizedBox(height: 32),
              TextField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, letterSpacing: 8),
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  filled: true,
                ),
                onChanged: (val) {
                  if (val.length == _savedPin?.length) {
                    _verifyPin();
                  }
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _verifyPin,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Buka Kunci'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
