import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/hotkey/hotkey_service.dart';

const _socketPath = '/tmp/flippi.sock';

void main(List<String> args) async {
  // --toggle MUSS vor jeder Flutter/Hive-Initialisierung laufen
  if (args.contains('--toggle')) {
    await _sendToggle();
    return;
  }

  WidgetsFlutterBinding.ensureInitialized();

  // Hive initialisieren
  await Hive.initFlutter();
  await Hive.openBox<String>('clipboard');
  await Hive.openBox<String>('custom_emojis');

  // Window Manager initialisieren
  await windowManager.ensureInitialized();
  const windowOptions = WindowOptions(
    size: Size(420, 520),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: true,
    titleBarStyle: TitleBarStyle.hidden,
    alwaysOnTop: true,
  );
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  // Globaler Hotkey (Super + .)
  await HotkeyService.init();

  // Toggle-Server starten (empfängt --toggle Signale)
  _startToggleServer();

  runApp(const ProviderScope(child: FlippiApp()));
}

// Sendet "toggle" an die laufende Instanz via Unix Socket
Future<void> _sendToggle() async {
  try {
    final socket = await Socket.connect(
      InternetAddress(_socketPath, type: InternetAddressType.unix),
      0,
      timeout: const Duration(seconds: 1),
    );
    socket.write('toggle');
    await socket.flush();
    await socket.close();
  } catch (_) {
    // Keine laufende Instanz gefunden
  }
}

// Lauscht auf Toggle-Signale von anderen Instanzen
void _startToggleServer() async {
  final sockFile = File(_socketPath);
  if (sockFile.existsSync()) sockFile.deleteSync();

  try {
    final server = await ServerSocket.bind(
      InternetAddress(_socketPath, type: InternetAddressType.unix),
      0,
    );
    server.listen((socket) {
      socket.listen((data) async {
        final msg = String.fromCharCodes(data).trim();
        if (msg == 'toggle') {
          final isVisible = await windowManager.isVisible();
          if (isVisible) {
            await windowManager.hide();
          } else {
            await windowManager.show();
            await windowManager.focus();
          }
        }
        socket.destroy();
      });
    });
  } catch (e) {
    debugPrint('Toggle-Server Fehler: $e');
  }
}
