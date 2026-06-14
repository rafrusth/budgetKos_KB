import 'package:flutter/material.dart';
import '../di/injection.dart';
import '../sync/sync_engine.dart';

class AutoSyncWidget extends StatefulWidget {
  final Widget child;

  const AutoSyncWidget({super.key, required this.child});

  @override
  State<AutoSyncWidget> createState() => _AutoSyncWidgetState();
}

class _AutoSyncWidgetState extends State<AutoSyncWidget> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initial sync on app start
    _runSync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.hidden || 
        state == AppLifecycleState.paused || 
        state == AppLifecycleState.detached) {
      // Sync when the app goes to the background or is closing
      _runSync();
    }
  }

  void _runSync() {
    try {
      getIt<SyncEngine>().syncData();
    } catch (e) {
      debugPrint('AutoSync Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
