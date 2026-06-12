import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../../core/utils/toast_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'security_page.dart';
import 'notifications_settings_page.dart';
import 'help_support_page.dart';
import '../../../../core/database/sqlite_helper.dart';
import '../../../../core/di/injection.dart';
import '../../../categories/presentation/pages/categories_page.dart';

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
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Edit Profil', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Nama',
                    filled: true,
                    fillColor: theme.cardColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    filled: true,
                    fillColor: theme.cardColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
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
                    child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
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
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadProfile();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                  child: Icon(Icons.person, size: 50, color: theme.colorScheme.primary),
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
                  _buildListTile(theme, icon: CupertinoIcons.tag, title: 'Kelola Kategori', onTap: () {
                    Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(builder: (_) => const CategoriesPage()));
                  }),
                  _buildListTile(theme, icon: CupertinoIcons.lock, title: 'Keamanan', onTap: () {
                    Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(builder: (_) => const SecurityPage()));
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
                    Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(builder: (_) => const NotificationsSettingsPage()));
                  }),
                ]
              ),
              const SizedBox(height: 24),
              _buildSection(
                theme,
                title: 'Lainnya',
                children: [
                  _buildListTile(theme, icon: CupertinoIcons.question_circle, title: 'Bantuan & Dukungan', onTap: () {
                    Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(builder: (_) => const HelpSupportPage()));
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
