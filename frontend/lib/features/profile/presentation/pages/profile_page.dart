import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:io' as import_io;
import 'package:window_manager/window_manager.dart';
import '../../../../core/widgets/custom_title_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/toast_helper.dart';
import '../../../../core/utils/profile_notifier.dart';
import '../../../../core/utils/popup_helper.dart';
import '../../../../core/database/sqlite_helper.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/sync/sync_engine.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import 'security_page.dart';
import 'notifications_settings_page.dart';
import 'help_support_page.dart';
import '../../../categories/presentation/pages/categories_page.dart';


class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _userName = 'Mahasiswa';
  String _userEmail = 'anak_kos@university.edu';
  String _campusLocation = '';

  static const List<String> _presetLocations = [
    'Tembalang, Semarang',
    'Pleburan, Semarang',
    'Depok, Jakarta',
    'Jatinangor, Bandung',
    'Sukolilo, Surabaya',
    'Bulaksumur, Yogyakarta',
    'Sekaran, Semarang',
    'Pedurungan, Semarang',
  ];

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
      _campusLocation = prefs.getString('user_campus_location') ?? '';
    });
  }

  void _editProfileDialog() {
    final nameController = TextEditingController(text: profileNotifier.value.name);
    final emailController = TextEditingController(text: profileNotifier.value.email);
    final locationController = TextEditingController(text: profileNotifier.value.campus);
    final passwordController = TextEditingController(text: profileNotifier.value.password);
    final theme = Theme.of(context);
    PopupHelper.showAdaptivePopup(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24, right: 24, top: 24,
          ),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SingleChildScrollView(
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
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
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      filled: true,
                      fillColor: theme.cardColor,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Autocomplete<String>(
                    initialValue: TextEditingValue(text: _campusLocation),
                    optionsBuilder: (textEditingValue) {
                      if (textEditingValue.text.isEmpty) return _presetLocations;
                      return _presetLocations.where((loc) =>
                        loc.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                    },
                    onSelected: (selection) {
                      locationController.text = selection;
                    },
                    fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                      // Sync the autocomplete controller with our location controller
                      controller.addListener(() => locationController.text = controller.text);
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          labelText: 'Lokasi Kampus/Kos',
                          hintText: 'Contoh: Tembalang, Semarang',
                          prefixIcon: const Icon(Icons.location_on_outlined),
                          filled: true,
                          fillColor: theme.cardColor,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Text(
                      'AI akan otomatis menggunakan lokasi ini untuk rekomendasi harga lokal',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey, fontSize: 11),
                    ),
                  ),
                  const SizedBox(height: 24),
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
                        await profileNotifier.updateProfile(
                          nameController.text,
                          emailController.text,
                          locationController.text,
                          passwordController.text,
                        );
                        setState(() {
                          _userName = nameController.text;
                          _userEmail = emailController.text;
                          _campusLocation = locationController.text;
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

  Widget _buildProfileHeader(BuildContext context, ThemeData theme, bool isDark) {
    final isDesktop = MediaQuery.of(context).size.width > 800;
    
    if (!isDesktop) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green.withValues(alpha: 0.15),
            ),
            child: CircleAvatar(
              radius: 40,
              backgroundColor: Colors.transparent,
              child: Icon(Icons.person, size: 48, color: theme.colorScheme.primary),
            ),
          ),
          const SizedBox(height: 16),
          Text(_userName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(_userEmail, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          if (_campusLocation.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on, size: 12, color: theme.colorScheme.primary),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    _campusLocation,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _editProfileDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? Colors.white24 : Colors.black12,
              foregroundColor: isDark ? Colors.white : Colors.black,
              shape: const StadiumBorder(),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            ),
            child: const Text('Edit profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.green.withValues(alpha: 0.15),
          ),
          child: CircleAvatar(
            radius: 40,
            backgroundColor: Colors.transparent,
            child: Icon(Icons.person, size: 48, color: theme.colorScheme.primary),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_userName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(_userEmail, style: const TextStyle(fontSize: 14, color: Colors.grey)),
              if (_campusLocation.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 12, color: theme.colorScheme.primary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _campusLocation,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: _editProfileDialog,
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? Colors.white : Colors.black,
            foregroundColor: isDark ? Colors.black : Colors.white,
            shape: const StadiumBorder(),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          child: const Text('Edit profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Profil', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          WindowButtonsRow(),
        ],
        flexibleSpace: import_io.Platform.isWindows || import_io.Platform.isLinux || import_io.Platform.isMacOS
            ? DragToMoveArea(child: Container(color: Colors.transparent))
            : null,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadProfile();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 32.0, left: 24.0, right: 24.0, bottom: 32.0),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Header (Avatar, Name, Email, Edit Button)
                _buildProfileHeader(context, theme, isDark),
                const SizedBox(height: 48),
                
                // Account / Inventories Section
                _buildSection(
                  theme,
                  title: 'Account',
                  isDark: isDark,
                  children: [
                    _buildListTile(theme, icon: CupertinoIcons.tag, title: 'Kelola Kategori', isDark: isDark, onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CategoriesPage()));
                    }),
                    _buildListTile(theme, icon: CupertinoIcons.lock, title: 'Keamanan', isDark: isDark, onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SecurityPage()));
                    }),
                    _buildListTile(theme, icon: CupertinoIcons.question_circle, title: 'Support', isDark: isDark, onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HelpSupportPage()));
                    }),
                  ]
                ),
                const SizedBox(height: 24),
                
                // Preferences Section
                _buildSection(
                  theme,
                  title: 'Preferences',
                  isDark: isDark,
                  children: [
                    _buildListTile(theme, icon: CupertinoIcons.cloud_upload, title: 'Push (Save) Data', isDark: isDark, onTap: () async {
                      try {
                        ToastHelper.showSuccess(context, 'Memulai Push data...');
                        await getIt<SyncEngine>().pushData();
                        if (context.mounted) ToastHelper.showSuccess(context, 'Push data berhasil!');
                      } catch (e) {
                        if (context.mounted) ToastHelper.showError(context, 'Gagal Push data: $e');
                      }
                    }),
                    _buildListTile(theme, icon: CupertinoIcons.cloud_download, title: 'Pull (Load) Data', isDark: isDark, onTap: () async {
                      try {
                        ToastHelper.showSuccess(context, 'Memulai Pull data...');
                        await getIt<SyncEngine>().pullData();
                        if (context.mounted) ToastHelper.showSuccess(context, 'Pull data berhasil!');
                      } catch (e) {
                        if (context.mounted) ToastHelper.showError(context, 'Gagal Pull data: $e');
                      }
                    }),
                    BlocBuilder<ThemeCubit, ThemeMode>(
                      builder: (context, themeMode) {
                        String themeText = 'System';
                        if (themeMode == ThemeMode.light) themeText = 'Light';
                        if (themeMode == ThemeMode.dark) themeText = 'Dark';
                        
                        return _buildListTile(
                          theme, 
                          icon: isDark ? CupertinoIcons.moon : CupertinoIcons.sun_max, 
                          title: 'Tema Tampilan', 
                          isDark: isDark,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(themeText, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                              const SizedBox(width: 4),
                              const Icon(CupertinoIcons.chevron_right, size: 16, color: Colors.grey),
                            ],
                          ),
                          onTap: () => _showThemeSelectionDialog(context, themeMode),
                        );
                      }
                    ),
                    _buildListTile(theme, icon: CupertinoIcons.bell, title: 'Notifikasi', isDark: isDark, onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsSettingsPage()));
                    }),
                    _buildListTile(theme, icon: CupertinoIcons.square_arrow_right, title: 'Logout', textColor: Colors.red, iconColor: Colors.red, isDark: isDark, trailing: const SizedBox.shrink(), onTap: () {
                      context.read<AuthBloc>().add(LogoutRequested());
                      context.go('/login');
                    }),
                  ]
                ),
                const SizedBox(height: 24),
                
                // Danger Zone Section
                _buildSection(
                  theme,
                  title: 'Danger Zone',
                  isDark: isDark,
                  children: [
                    _buildListTile(theme, icon: CupertinoIcons.trash, title: 'Hapus Semua Data', color: Colors.red, textColor: Colors.red, iconColor: Colors.red, isDark: isDark, trailing: const SizedBox.shrink(), onTap: () {
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
                                if (context.mounted) {
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
                const SizedBox(height: 120), // Extra padding for scrolling past navbar
              ],
            ),
          ),
        ),
    );
  }

  void _showThemeSelectionDialog(BuildContext context, ThemeMode currentMode) {
    PopupHelper.showAdaptivePopup(
      context: context,
      isScrollControlled: false,
      builder: (ctx) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        
        Widget content = Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.black.withValues(alpha: 0.4) : Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 16),
                const Text('Pilih Tema', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Sistem (Default)'),
                  trailing: currentMode == ThemeMode.system ? const Icon(Icons.check, color: Colors.green) : null,
                  onTap: () {
                    context.read<ThemeCubit>().setTheme(ThemeMode.system);
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  title: const Text('Terang (Light)'),
                  trailing: currentMode == ThemeMode.light ? const Icon(Icons.check, color: Colors.green) : null,
                  onTap: () {
                    context.read<ThemeCubit>().setTheme(ThemeMode.light);
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  title: const Text('Gelap (Dark)'),
                  trailing: currentMode == ThemeMode.dark ? const Icon(Icons.check, color: Colors.green) : null,
                  onTap: () {
                    context.read<ThemeCubit>().setTheme(ThemeMode.dark);
                    Navigator.pop(ctx);
                  },
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.035),
              ],
            ),
          ),
        );

        if (isDark) {
          content = BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
            child: content,
          );
        }

        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.1, left: 16, right: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: content,
          ),
        );
      },
    );
  }

  Widget _buildSection(ThemeData theme, {required String title, required List<Widget> children, bool isDark = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5) : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: children.asMap().entries.map((entry) {
              final isLast = entry.key == children.length - 1;
              return Column(
                children: [
                  entry.value,
                  if (!isLast) Divider(height: 1, indent: 56, endIndent: 16, color: isDark ? Colors.white12 : Colors.black12),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildListTile(ThemeData theme, {
    required IconData icon, 
    required String title, 
    Widget? trailing, 
    Color? color, 
    Color? textColor, 
    Color? iconColor, 
    required VoidCallback onTap, 
    bool isDark = false
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade800 : Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ]
        ),
        child: Icon(icon, color: iconColor ?? (isDark ? Colors.white : Colors.black87), size: 20),
      ),
      title: Text(title, style: TextStyle(color: textColor ?? (isDark ? Colors.white : Colors.black87), fontWeight: FontWeight.w500, fontSize: 15)),
      trailing: trailing ?? const Icon(CupertinoIcons.chevron_right, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }
}
