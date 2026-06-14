import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

class NotificationsSettingsPage extends StatefulWidget {
  const NotificationsSettingsPage({super.key});

  @override
  State<NotificationsSettingsPage> createState() => _NotificationsSettingsPageState();
}

class _NotificationsSettingsPageState extends State<NotificationsSettingsPage> {
  bool _transaksi = true;
  bool _bulanan = true;
  bool _pengingat = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _transaksi = prefs.getBool('notif_transaksi') ?? true;
      _bulanan = prefs.getBool('notif_bulanan') ?? true;
      _pengingat = prefs.getBool('notif_pengingat') ?? false;
    });
  }

  Future<void> _savePref(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
              child: const Text('Profil', style: TextStyle(color: Colors.grey, fontSize: 16)),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
            const Text('Notifikasi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('Notifikasi Transaksi'),
            subtitle: const Text('Dapatkan pemberitahuan saat transaksi ditambahkan'),
            value: _transaksi,
            onChanged: (val) {
              setState(() => _transaksi = val);
              _savePref('notif_transaksi', val);
            },
          ),
          SwitchListTile(
            title: const Text('Notifikasi Laporan Bulanan'),
            subtitle: const Text('Rekap pengeluaran setiap akhir bulan'),
            value: _bulanan,
            onChanged: (val) {
              setState(() => _bulanan = val);
              _savePref('notif_bulanan', val);
            },
          ),
          SwitchListTile(
            title: const Text('Pengingat Catat Keuangan'),
            subtitle: const Text('Ingatkan saya jika belum mencatat hari ini'),
            value: _pengingat,
            onChanged: (val) {
              setState(() => _pengingat = val);
              _savePref('notif_pengingat', val);
            },
          ),
        ],
      ),
    );
  }
}
