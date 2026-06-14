import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

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
