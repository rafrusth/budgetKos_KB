import 'dart:ui';
import 'dart:io' as import_io;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../../../features/transaction/presentation/widgets/transaction_bottom_sheet.dart';

class MainScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainScaffold({
    super.key,
    required this.navigationShell,
  });

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = import_io.Platform.isWindows || MediaQuery.of(context).size.width > 800;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBody: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (isDesktop || constraints.maxWidth > 800) {
            return Row(
              children: [
                _buildSidebar(context),
                Expanded(child: navigationShell),
              ],
            );
          } else {
            return Stack(
              children: [
                navigationShell,
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _buildGlassBottomNav(context),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        border: Border(
          right: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 24, top: 32, bottom: 32),
            child: Row(
              children: [
                Icon(Icons.account_balance_wallet, color: theme.colorScheme.primary, size: 32),
                const SizedBox(width: 12),
                Text(
                  "BudgetKos",
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
          _sidebarItem(context, CupertinoIcons.home, 0, 'Beranda'),
          _sidebarItem(context, CupertinoIcons.chart_pie, 1, 'Laporan'),
          _sidebarItem(context, CupertinoIcons.sparkles, 2, 'Chat AI'),
          _sidebarItem(context, CupertinoIcons.person, 3, 'Profil'),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => TransactionBottomSheet.show(context),
                icon: const Icon(Icons.add),
                label: const Text('Transaksi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebarItem(BuildContext context, IconData icon, int index, String label) {
    final isSelected = navigationShell.currentIndex == index;
    final theme = Theme.of(context);
    final color = isSelected ? theme.colorScheme.primary : (theme.brightness == Brightness.dark ? Colors.white70 : Colors.black54);
    
    return InkWell(
      onTap: () => _goBranch(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.1) : Colors.transparent,
          border: Border(
            right: BorderSide(
              color: isSelected ? theme.colorScheme.primary : Colors.transparent,
              width: 4,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassBottomNav(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.only(left: 15, right: 15, bottom: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 7.5),
            decoration: BoxDecoration(
              color: isDark ? Colors.black.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _navItem(context, CupertinoIcons.home, 0, 'Beranda'),
                _navItem(context, CupertinoIcons.chart_pie, 1, 'Laporan'),
                _buildAddButton(context),
                _navItem(context, CupertinoIcons.sparkles, 2, 'Chat AI'),
                _navItem(context, CupertinoIcons.person, 3, 'Profil'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(BuildContext context, IconData icon, int index, String label) {
    final isSelected = navigationShell.currentIndex == index;
    final theme = Theme.of(context);
    final color = isSelected ? theme.colorScheme.primary : Colors.grey;
    
    return GestureDetector(
      onTap: () => _goBranch(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 23.75),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: color, fontSize: 11.25, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => TransactionBottomSheet.show(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 28.5),
          ),
          const SizedBox(height: 2),
          const Text("Transaksi", style: TextStyle(color: Colors.grey, fontSize: 11.25, fontWeight: FontWeight.normal)),
        ],
      ),
    );
  }
}
