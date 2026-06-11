import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/utils/toast_helper.dart';

class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key});

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  bool _isPinEnabled = false;
  String? _currentPin;

  @override
  void initState() {
    super.initState();
    _loadPin();
  }

  Future<void> _loadPin() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentPin = prefs.getString('app_pin');
      _isPinEnabled = _currentPin != null && _currentPin!.isNotEmpty;
    });
  }

  void _showPinDialog(bool isSettingNew) {
    final pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isSettingNew ? 'Set PIN Baru' : 'Nonaktifkan PIN'),
        content: TextField(
          controller: pinController,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 6,
          decoration: const InputDecoration(
            labelText: 'Masukkan 6 digit PIN',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              if (pinController.text.length < 4) {
                ToastHelper.showError(ctx, 'PIN minimal 4 digit');
                return;
              }
              final prefs = await SharedPreferences.getInstance();
              if (isSettingNew) {
                await prefs.setString('app_pin', pinController.text);
                ToastHelper.showSuccess(ctx, 'PIN berhasil diaktifkan');
              } else {
                if (pinController.text == _currentPin) {
                  await prefs.remove('app_pin');
                  ToastHelper.showSuccess(ctx, 'PIN dinonaktifkan');
                } else {
                  ToastHelper.showError(ctx, 'PIN salah!');
                  return;
                }
              }
              Navigator.pop(ctx);
              _loadPin();
            },
            child: const Text('Simpan'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Keamanan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('Gunakan PIN Aplikasi'),
            subtitle: const Text('Minta PIN setiap membuka aplikasi'),
            value: _isPinEnabled,
            onChanged: (val) {
              if (val) {
                _showPinDialog(true);
              } else {
                _showPinDialog(false);
              }
            },
          ),
          if (_isPinEnabled)
            ListTile(
              leading: const Icon(Icons.password),
              title: const Text('Ubah PIN'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showPinDialog(true),
            ),
        ],
      ),
    );
  }
}
