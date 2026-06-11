import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:budget_kos/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:budget_kos/features/transactions/presentation/pages/transactions_page.dart';
import 'package:budget_kos/features/reports/presentation/pages/reports_page.dart';
import 'package:budget_kos/features/ai/presentation/pages/ai_chat_page.dart';
import 'package:budget_kos/features/profile/presentation/pages/profile_page.dart';
import 'package:budget_kos/core/presentation/pages/main_scaffold.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  navigatorKey: _rootNavigatorKey,
  routes: [
    StatefulShellRoute(
      navigatorContainerBuilder: (context, navigationShell, children) {
        return AnimatedBranchContainer(
          currentIndex: navigationShell.currentIndex,
          children: children,
        );
      },
      builder: (context, state, navigationShell) {
        return MainScaffold(navigationShell: navigationShell);
      },
      branches: [
        // Tab 0: Home / Dashboard
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const DashboardPage(),
            ),
          ],
        ),
        // Tab 1: Reports
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/reports',
              builder: (context, state) => const ReportsPage(),
            ),
          ],
        ),
        // Tab 3: AI Chat
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/ai',
              builder: (context, state) => const AIChatPage(),
            ),
          ],
        ),
        // Tab 4: Profile
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfilePage(),
            ),
          ],
        ),
      ],
    ),
  ],
);

class AnimatedBranchContainer extends StatelessWidget {
  const AnimatedBranchContainer({super.key, required this.currentIndex, required this.children});
  
  final int currentIndex;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: children.asMap().entries.map((entry) {
        final index = entry.key;
        final child = entry.value;
        return AnimatedSlide(
          offset: index == currentIndex 
              ? Offset.zero 
              : Offset(index < currentIndex ? -0.5 : 0.5, 0.0),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          child: IgnorePointer(
            ignoring: index != currentIndex,
            child: AnimatedOpacity(
              opacity: index == currentIndex ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: child,
            ),
          ),
        );
      }).toList(),
    );
  }
}
