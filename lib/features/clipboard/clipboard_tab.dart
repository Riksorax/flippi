import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/clipboard/clipboard_provider.dart';
import '../../shared/widgets/flippi_shell.dart';

class ClipboardTab extends ConsumerWidget {
  const ClipboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(clipboardProvider);
    final query = ref.watch(searchQueryProvider);

    final filtered = query.isEmpty
        ? entries
        : entries.where((e) => e.text.toLowerCase().contains(query.toLowerCase())).toList();

    if (filtered.isEmpty) {
      return const Center(
        child: Text('Nichts gefunden', style: TextStyle(color: Color(0xFF6B6B82))),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: filtered.length,
      itemBuilder: (context, i) => _ClipItem(entry: filtered[i], index: i + 1),
    );
  }
}

class _ClipItem extends ConsumerStatefulWidget {
  final ClipEntry entry;
  final int index;
  const _ClipItem({required this.entry, required this.index});

  @override
  ConsumerState<_ClipItem> createState() => _ClipItemState();
}

class _ClipItemState extends ConsumerState<_ClipItem> {
  bool _hovered = false;

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'gerade eben';
    if (diff.inMinutes < 60) return 'vor ${diff.inMinutes} Min';
    if (diff.inHours < 24) return 'vor ${diff.inHours} Std';
    return 'vor ${diff.inDays} Tagen';
  }

  Color _typeColor(ClipType type) => switch (type) {
    ClipType.code => const Color(0xFFF76A8C),
    ClipType.url  => const Color(0xFF7C6AF7),
    ClipType.text => const Color(0xFF6AF7C8),
  };

  String _typeLabel(ClipType type) => switch (type) {
    ClipType.code => 'Code',
    ClipType.url  => 'URL',
    ClipType.text => 'Text',
  };

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
        decoration: BoxDecoration(
          color: _hovered ? const Color(0xFF21212B) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _hovered ? const Color(0xFF2A2A38) : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              child: Text('${widget.index}',
                  style: const TextStyle(
                      color: Color(0xFF6B6B82),
                      fontSize: 10,
                      fontFamily: 'monospace')),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.entry.text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: Color(0xFFE8E8F0)),
                  ),
                  const SizedBox(height: 3),
                  Row(children: [
                    Text(_timeAgo(widget.entry.time),
                        style: const TextStyle(
                            fontSize: 10.5,
                            color: Color(0xFF6B6B82),
                            fontFamily: 'monospace')),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: _typeColor(widget.entry.type).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(_typeLabel(widget.entry.type),
                          style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w500,
                              color: _typeColor(widget.entry.type))),
                    ),
                  ]),
                ],
              ),
            ),
            if (_hovered) ...[
              _ActionBtn(
                icon: Icons.copy,
                onTap: () {
                  Clipboard.setData(ClipboardData(text: widget.entry.text));
                },
              ),
              const SizedBox(width: 4),
              _ActionBtn(
                icon: Icons.close,
                onTap: () => ref.read(clipboardProvider.notifier).remove(widget.entry.id),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: const Color(0xFF18181F),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF2A2A38)),
        ),
        child: Icon(icon, size: 13, color: const Color(0xFF6B6B82)),
      ),
    );
  }
}
