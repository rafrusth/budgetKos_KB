import 'dart:ui';
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
      // Support navigating to the initial location when tapping the item that is already active
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBody: true,
      body: Stack(
        children: [
          navigationShell,
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildGlassBottomNav(context),
          ),
        ],
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
              color: isDark ? Colors.black.withOpacity(0.4) : Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
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
                  color: theme.colorScheme.primary.withOpacity(0.4),
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
