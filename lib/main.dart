import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'core/hotkey/hotkey_service.dart';

const _socketPath = '/tmp/flippi.sock';

void main(List<String> args) async {
  // Läuft eine Instanz? → togglen und beenden. Sonst als Hauptinstanz starten.
  if (await _sendToggle()) return;

  WidgetsFlutterBinding.ensureInitialized();

  final dataDir = await getApplicationSupportDirectory();
  Hive.init(dataDir.path);
  await Hive.openBox<String>('clipboard');
  await Hive.openBox<String>('custom_emojis');
  await Hive.openBox<String>('recent_emojis');

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

  await HotkeyService.init();
  _startToggleServer();

  runApp(const ProviderScope(child: FlippiApp()));
}

// Gibt true zurück wenn eine laufende Instanz erfolgreich getoggled wurde
Future<bool> _sendToggle() async {
  try {
    final socket = await Socket.connect(
      InternetAddress(_socketPath, type: InternetAddressType.unix),
      0,
      timeout: const Duration(milliseconds: 500),
    );
    socket.write('toggle');
    await socket.flush();
    await socket.close();
    return true;
  } catch (_) {
    return false;
  }
}

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
