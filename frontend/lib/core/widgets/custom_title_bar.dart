import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../di/injection.dart';
import '../sync/data/datasources/sync_local_data_source.dart';

class WindowButtonsRow extends StatefulWidget {
  const WindowButtonsRow({super.key});

  @override
  State<WindowButtonsRow> createState() => _WindowButtonsRowState();
}

class _WindowButtonsRowState extends State<WindowButtonsRow> with WindowListener {
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _init();
  }

  void _init() async {
    bool isMaximized = await windowManager.isMaximized();
    if (mounted) {
      setState(() {
        _isMaximized = isMaximized;
      });
    }
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowMaximize() {
    setState(() {
      _isMaximized = true;
    });
  }

  @override
  void onWindowUnmaximize() {
    setState(() {
      _isMaximized = false;
    });
  }

  Future<bool> _hasPendingSync() async {
    try {
      final localDataSource = getIt<ISyncLocalDataSource>();
      final pendingData = await localDataSource.getPendingData();
      final hasTxs = (pendingData['transactions'] as List).isNotEmpty;
      final hasCats = (pendingData['categories'] as List).isNotEmpty;
      final hasDelTxs = (pendingData['deleted_transaction_ids'] as List).isNotEmpty;
      final hasDelCats = (pendingData['deleted_category_ids'] as List).isNotEmpty;
      return hasTxs || hasCats || hasDelTxs || hasDelCats;
    } catch (_) {
      return false;
    }
  }

  @override
  void onWindowClose() async {
    final hasUnsynced = await _hasPendingSync();
    if (hasUnsynced) {
      if (!mounted) return;
      final shouldClose = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Peringatan Sinkronisasi"),
          content: const Text("Terdapat perubahan data yang belum tersimpan ke server. Jika Anda keluar sekarang, data belum tersinkronisasi. Yakin ingin keluar?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Batal"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("Tetap Keluar", style: const TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
      if (shouldClose == true) {
        windowManager.destroy();
      }
    } else {
      windowManager.destroy();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _WindowButton(
          icon: Icons.minimize,
          onPressed: () async => await windowManager.minimize(),
        ),
        _WindowButton(
          icon: _isMaximized ? Icons.filter_none : Icons.crop_square,
          iconSize: 14,
          onPressed: () async {
            if (await windowManager.isMaximized()) {
              await windowManager.unmaximize();
            } else {
              await windowManager.maximize();
            }
          },
        ),
        _WindowButton(
          icon: Icons.close,
          isCloseButton: true,
          onPressed: () async => await windowManager.close(),
        ),
      ],
    );
  }
}

class _WindowButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool isCloseButton;
  final double iconSize;

  const _WindowButton({
    required this.icon,
    required this.onPressed,
    this.isCloseButton = false,
    this.iconSize = 16,
  });

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hoverColor = widget.isCloseButton
        ? Colors.red
        : theme.colorScheme.onSurface.withValues(alpha: 0.1);
    final iconColor = _isHovered && widget.isCloseButton
        ? Colors.white
        : theme.colorScheme.onSurface;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Container(
          width: 46,
          height: 46,
          color: _isHovered ? hoverColor : Colors.transparent,
          child: Icon(
            widget.icon,
            size: widget.iconSize,
            color: iconColor,
          ),
        ),
      ),
    );
  }
}
