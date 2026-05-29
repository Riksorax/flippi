import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:window_manager/window_manager.dart';
import '../../core/gif/gif_provider.dart';
import '../../shared/widgets/flippi_shell.dart';

class GifTab extends ConsumerStatefulWidget {
  const GifTab({super.key});

  @override
  ConsumerState<GifTab> createState() => _GifTabState();
}

// GIF herunterladen, als Datei in Clipboard legen (wl-copy) und Fenster schließen
Future<void> useGif(GifEntry gif, WidgetRef ref) async {
  ref.read(recentGifProvider.notifier).use(gif);
  try {
    final response = await http.get(Uri.parse(gif.url));
    final tmpFile = File('/tmp/flippi_gif_${gif.id}.gif');
    await tmpFile.writeAsBytes(response.bodyBytes);
    final process = await Process.start('wl-copy', ['--type', 'image/gif']);
    await process.stdin.addStream(tmpFile.openRead());
    await process.stdin.close();
    await process.exitCode;
  } catch (_) {
    // Fallback: URL als Text kopieren
    await Clipboard.setData(ClipboardData(text: gif.url));
  }
  await windowManager.hide();
}

class _GifTabState extends ConsumerState<GifTab> {
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      if (query.isEmpty) {
        ref.read(gifProvider.notifier).loadTrending();
      } else {
        ref.read(gifProvider.notifier).search(query);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Suchfeld-Änderungen mithören
    final query = ref.read(searchQueryProvider);
    _onSearchChanged(query);
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final gifsAsync = ref.watch(gifProvider);
    final recent = ref.watch(recentGifProvider);

    // Suchquery weiterleiten
    ref.listen(searchQueryProvider, (_, next) => _onSearchChanged(next));

    return Column(
      children: [
        // Zuletzt verwendet
        if (recent.isNotEmpty && query.isEmpty)
          _RecentChips(recent: recent),

        // Grid
        Expanded(
          child: gifsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF7C6AF7),
                strokeWidth: 2,
              ),
            ),
            error: (e, _) => Center(
              child: Text('Fehler: $e',
                  style: const TextStyle(color: Color(0xFF6B6B82), fontSize: 12)),
            ),
            data: (gifs) {
              if (gifs.isEmpty) {
                return const Center(
                  child: Text('Keine GIFs gefunden',
                      style: TextStyle(color: Color(0xFF6B6B82), fontSize: 12)),
                );
              }
              return GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                  childAspectRatio: 16 / 9,
                ),
                itemCount: gifs.length,
                itemBuilder: (context, i) => _GifCard(gif: gifs[i]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RecentChips extends ConsumerWidget {
  final List<GifEntry> recent;
  const _RecentChips({required this.recent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        itemCount: recent.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final gif = recent[i];
          return GestureDetector(
            onTap: () => useGif(gif, ref),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF21212B),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF2A2A38)),
              ),
              child: Text(
                gif.title.isEmpty ? 'GIF' : gif.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF6B6B82),
                    fontFamily: 'monospace'),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GifCard extends ConsumerStatefulWidget {
  final GifEntry gif;
  const _GifCard({required this.gif});

  @override
  ConsumerState<_GifCard> createState() => _GifCardState();
}

class _GifCardState extends ConsumerState<_GifCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => useGif(widget.gif, ref),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: const Color(0xFF18181F),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _hovered ? const Color(0xFF7C6AF7) : const Color(0xFF2A2A38),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  widget.gif.previewUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(Icons.gif_box, color: Color(0xFF6B6B82), size: 28),
                  ),
                ),
                if (widget.gif.title.isNotEmpty)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      color: Colors.black54,
                      child: Text(
                        widget.gif.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 9,
                            color: Colors.white70,
                            fontFamily: 'monospace'),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
