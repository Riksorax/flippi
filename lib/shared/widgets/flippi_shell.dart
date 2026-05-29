import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'tab_content.dart';

enum FlippiTab { clipboard, emoji, gif }

class ActiveTabNotifier extends Notifier<FlippiTab> {
  @override
  FlippiTab build() => FlippiTab.clipboard;
  void set(FlippiTab tab) => state = tab;
}

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  void set(String query) => state = query;
}

final activeTabProvider = NotifierProvider<ActiveTabNotifier, FlippiTab>(ActiveTabNotifier.new);
final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

class FlippiShell extends ConsumerWidget {
  const FlippiShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTab = ref.watch(activeTabProvider);

    return Focus(
      autofocus: true,
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
          windowManager.hide();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      body: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: [
            _SearchBar(),
            _TabBar(activeTab: activeTab),
            Expanded(child: TabContent(activeTab: activeTab)),
            _Footer(activeTab: activeTab),
          ],
        ),
      ),
    ));
  }
}

class _SearchBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF18181F),
        border: Border(bottom: BorderSide(color: Color(0xFF2A2A38))),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Color(0xFF6B6B82), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              onChanged: (v) => ref.read(searchQueryProvider.notifier).set(v),
              style: const TextStyle(color: Color(0xFFE8E8F0), fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Suchen…',
                hintStyle: TextStyle(color: Color(0xFF6B6B82)),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF21212B),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: const Color(0xFF2A2A38)),
            ),
            child: const Text('Esc',
                style: TextStyle(
                    color: Color(0xFF6B6B82),
                    fontSize: 10,
                    fontFamily: 'monospace')),
          ),
        ],
      ),
    );
  }
}

class _TabBar extends ConsumerWidget {
  final FlippiTab activeTab;
  const _TabBar({required this.activeTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: const Color(0xFF18181F),
      child: Row(
        children: [
          _Tab(label: 'Clipboard', icon: Icons.content_paste, tab: FlippiTab.clipboard, active: activeTab == FlippiTab.clipboard),
          _Tab(label: 'Emoji', icon: Icons.emoji_emotions_outlined, tab: FlippiTab.emoji, active: activeTab == FlippiTab.emoji),
          _Tab(label: 'GIF', icon: Icons.gif_box_outlined, tab: FlippiTab.gif, active: activeTab == FlippiTab.gif),
        ],
      ),
    );
  }
}

class _Tab extends ConsumerWidget {
  final String label;
  final IconData icon;
  final FlippiTab tab;
  final bool active;

  const _Tab({required this.label, required this.icon, required this.tab, required this.active});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => ref.read(activeTabProvider.notifier).set(tab),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF0F0F13) : Colors.transparent,
          border: Border(
            top: BorderSide(color: active ? const Color(0xFF2A2A38) : Colors.transparent),
            left: BorderSide(color: active ? const Color(0xFF2A2A38) : Colors.transparent),
            right: BorderSide(color: active ? const Color(0xFF2A2A38) : Colors.transparent),
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15,
                color: active ? const Color(0xFFE8E8F0) : const Color(0xFF6B6B82)),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: active ? const Color(0xFFE8E8F0) : const Color(0xFF6B6B82))),
          ],
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  final FlippiTab activeTab;
  const _Footer({required this.activeTab});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF18181F),
        border: Border(top: BorderSide(color: Color(0xFF2A2A38))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            _kbd('↑↓'), const SizedBox(width: 8),
            _kbd('↵'), const SizedBox(width: 8),
            _kbd('Esc'),
          ]),
          const Text('flippi',
              style: TextStyle(
                  color: Color(0xFF7C6AF7),
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _kbd(String key) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: const Color(0xFF21212B),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF2A2A38)),
      ),
      child: Text(key,
          style: const TextStyle(
              color: Color(0xFF6B6B82), fontSize: 9.5, fontFamily: 'monospace')),
    );
  }
}
