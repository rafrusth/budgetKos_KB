import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../../core/utils/toast_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'security_page.dart';
import 'notifications_settings_page.dart';
import 'help_support_page.dart';
import '../../../../core/database/sqlite_helper.dart';
import '../../../../core/di/injection.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _userName = 'Mahasiswa';
  String _userEmail = 'anak_kos@university.edu';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? 'Mahasiswa';
      _userEmail = prefs.getString('user_email') ?? 'anak_kos@university.edu';
    });
  }

  void _editProfileDialog() {
    final nameController = TextEditingController(text: _userName);
    final emailController = TextEditingController(text: _userEmail);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Profil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nama')),
            const SizedBox(height: 12),
            TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('user_name', nameController.text);
              await prefs.setString('user_email', emailController.text);
              setState(() {
                _userName = nameController.text;
                _userEmail = emailController.text;
              });
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                    child: Icon(Icons.person, size: 50, color: theme.colorScheme.primary),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _editProfileDialog,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit, color: Colors.white, size: 20),
                      ),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(_userName, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(_userEmail, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
            const SizedBox(height: 40),
            
            // Pengaturan
            _buildSection(
              theme,
              title: 'Pengaturan Akun',
              children: [
                _buildListTile(theme, icon: CupertinoIcons.person, title: 'Data Pribadi', onTap: _editProfileDialog),
                _buildListTile(theme, icon: CupertinoIcons.lock, title: 'Keamanan', onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SecurityPage()));
                }),
              ]
            ),
            const SizedBox(height: 24),
            _buildSection(
              theme,
              title: 'Aplikasi',
              children: [
                _buildListTile(
                  theme, 
                  icon: isDark ? CupertinoIcons.moon : CupertinoIcons.sun_max, 
                  title: 'Tema Tampilan', 
                  trailing: const Text('Sistem', style: TextStyle(color: Colors.grey)),
                  onTap: () {
                    ToastHelper.showInfo(context, 'Ubah tema lewat sistem device Anda.');
                  }
                ),
                _buildListTile(theme, icon: CupertinoIcons.bell, title: 'Notifikasi', onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsSettingsPage()));
                }),
              ]
            ),
            const SizedBox(height: 24),
            _buildSection(
              theme,
              title: 'Lainnya',
              children: [
                _buildListTile(theme, icon: CupertinoIcons.question_circle, title: 'Bantuan & Dukungan', onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportPage()));
                }),
                _buildListTile(theme, icon: CupertinoIcons.trash, title: 'Hapus Semua Data', color: Colors.red, onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Hapus Semua Data?'),
                      content: const Text('Tindakan ini akan menghapus seluruh data transaksi dan kategori Anda secara permanen. Anda yakin?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
                        TextButton(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await getIt<SqliteHelper>().clearAllData();
                            if (mounted) {
                              ToastHelper.showSuccess(context, 'Semua data berhasil dihapus!');
                            }
                          },
                          child: const Text('Hapus Permanen', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                }),
              ]
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(ThemeData theme, {required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(title, style: theme.textTheme.titleSmall?.copyWith(color: Colors.grey, fontWeight: FontWeight.bold)),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(theme.brightness == Brightness.dark ? 0.2 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: children.asMap().entries.map((entry) {
              final isLast = entry.key == children.length - 1;
              return Column(
                children: [
                  entry.value,
                  if (!isLast) const Divider(height: 1, indent: 50),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildListTile(ThemeData theme, {required IconData icon, required String title, Widget? trailing, Color? color, required VoidCallback onTap}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (color ?? theme.colorScheme.primary).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color ?? theme.colorScheme.primary, size: 20),
      ),
      title: Text(title, style: TextStyle(color: color ?? theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.w500)),
      trailing: trailing ?? const Icon(CupertinoIcons.chevron_right, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }
}
