import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

enum ClipType { text, code, url }

class ClipEntry {
  final String id;
  final String text;
  final ClipType type;
  final DateTime time;

  ClipEntry({required this.id, required this.text, required this.type, required this.time});

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'type': type.name,
    'time': time.toIso8601String(),
  };

  factory ClipEntry.fromJson(Map<String, dynamic> json) => ClipEntry(
    id: json['id'] as String,
    text: json['text'] as String,
    type: ClipType.values.byName(json['type'] as String),
    time: DateTime.parse(json['time'] as String),
  );

  static ClipType detectType(String text) {
    if (text.startsWith('http://') || text.startsWith('https://')) return ClipType.url;
    if (text.contains('\n') || text.contains('{') || text.contains(';')) return ClipType.code;
    return ClipType.text;
  }
}

class ClipboardNotifier extends Notifier<List<ClipEntry>> {
  static const _maxEntries = 50;

  Box<String> get _box => Hive.box<String>('clipboard');

  @override
  List<ClipEntry> build() {
    if (_box.isEmpty) return [];
    final entries = _box.values
        .map((v) => ClipEntry.fromJson(jsonDecode(v) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.time.compareTo(a.time));
    return entries;
  }

  void add(ClipEntry entry) {
    _box.put(entry.id, jsonEncode(entry.toJson()));
    var updated = [entry, ...state.where((e) => e.id != entry.id)];
    if (updated.length > _maxEntries) {
      for (final e in updated.sublist(_maxEntries)) {
        _box.delete(e.id);
      }
      updated = updated.take(_maxEntries).toList();
    }
    state = updated;
  }

  void remove(String id) {
    _box.delete(id);
    state = state.where((e) => e.id != id).toList();
  }

  void clear() {
    _box.clear();
    state = [];
  }
}

final clipboardProvider = NotifierProvider<ClipboardNotifier, List<ClipEntry>>(ClipboardNotifier.new);
