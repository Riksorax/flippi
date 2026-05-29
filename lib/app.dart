import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'shared/theme/app_theme.dart';
import 'features/clipboard/clipboard_screen.dart';
import 'core/clipboard/clipboard_provider.dart';

class FlippiApp extends ConsumerStatefulWidget {
  const FlippiApp({super.key});

  @override
  ConsumerState<FlippiApp> createState() => _FlippiAppState();
}

class _FlippiAppState extends ConsumerState<FlippiApp> with WindowListener {
  Process? _clipboardProcess;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _startClipboardWatcher();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    _clipboardProcess?.kill();
    super.dispose();
  }

  // Kurzes Delay verhindert, dass Dialoge innerhalb der App ein hide() auslösen
  @override
  void onWindowBlur() async {
    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    final isFocused = await windowManager.isFocused();
    if (!isFocused) windowManager.hide();
  }

  Future<void> _startClipboardWatcher() async {
    try {
      _clipboardProcess = await Process.start('wl-paste', ['--watch', 'cat']);
      _clipboardProcess!.stdout
          .transform(const Utf8Decoder(allowMalformed: true))
          .listen((text) {
        final trimmed = text.trim();
        // Binärdaten (GIFs, Bilder etc.) überspringen
        if (trimmed.isEmpty) return;
        if (trimmed.contains('\x00') || trimmed.codeUnits.any((c) => c > 0xFFFD)) return;
        final entry = ClipEntry(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: trimmed,
          type: ClipEntry.detectType(trimmed),
          time: DateTime.now(),
        );
        ref.read(clipboardProvider.notifier).add(entry);
      });
    } catch (e) {
      debugPrint('wl-clipboard nicht verfügbar: $e');
    }
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
