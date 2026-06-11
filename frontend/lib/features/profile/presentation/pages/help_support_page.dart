import 'package:flutter/material.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bantuan & Dukungan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const ListTile(
            leading: Icon(Icons.info),
            title: Text('Tentang BudgetKos AI'),
            subtitle: Text('Versi 1.0.0'),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('FAQ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          ExpansionTile(
            title: const Text('Bagaimana cara menggunakan AI Chat?'),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text('Anda dapat bertanya kepada AI tentang saran pengeluaran, rekap mingguan, atau tips menghemat uang ala anak kos. AI membaca data transaksi lokal Anda untuk memberikan saran.'),
              ),
            ],
          ),
          ExpansionTile(
            title: const Text('Apakah data saya aman?'),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text('Ya, semua data transaksi disimpan murni di perangkat Anda (offline) menggunakan database SQLite. Kami tidak mengirimkan data transaksi mentah ke server eksternal.'),
              ),
            ],
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.email),
            label: const Text('Hubungi Kami via Email'),
          ),
        ],
      ),
    );
  }
}
