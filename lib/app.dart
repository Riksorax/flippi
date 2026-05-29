import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'shared/theme/app_theme.dart';
import 'features/clipboard/clipboard_screen.dart';

class FlippiApp extends ConsumerStatefulWidget {
  const FlippiApp({super.key});

  @override
  ConsumerState<FlippiApp> createState() => _FlippiAppState();
}

class _FlippiAppState extends ConsumerState<FlippiApp> with WindowListener {
  // Verhindert sofortiges Schließen beim Start (Wayland überträgt Fokus nicht immer)
  bool _startupGrace = true;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _startupGrace = false);
    });
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowBlur() async {
    if (_startupGrace) return;
    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    final isFocused = await windowManager.isFocused();
    if (!isFocused) windowManager.hide();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flippi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const ClipboardScreen(),
    );
  }
}
