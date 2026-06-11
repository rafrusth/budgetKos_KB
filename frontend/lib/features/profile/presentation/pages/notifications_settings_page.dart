import 'package:flutter/material.dart';

class NotificationsSettingsPage extends StatelessWidget {
  const NotificationsSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifikasi')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('Notifikasi Transaksi'),
            subtitle: const Text('Dapatkan pemberitahuan saat transaksi ditambahkan'),
            value: true,
            onChanged: (val) {},
          ),
          SwitchListTile(
            title: const Text('Notifikasi Laporan Bulanan'),
            subtitle: const Text('Rekap pengeluaran setiap akhir bulan'),
            value: true,
            onChanged: (val) {},
          ),
          SwitchListTile(
            title: const Text('Pengingat Catat Keuangan'),
            subtitle: const Text('Ingatkan saya jika belum mencatat hari ini'),
            value: false,
            onChanged: (val) {},
          ),
        ],
      ),
    );
  }
}
