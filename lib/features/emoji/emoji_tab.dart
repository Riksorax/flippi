import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import '../../shared/widgets/flippi_shell.dart';

// ── Daten ──────────────────────────────────────────────────────────────────


const _categoryNames = {
  Category.SMILEYS:    'Smileys & Menschen',
  Category.ANIMALS:    'Tiere & Natur',
  Category.FOODS:      'Essen & Trinken',
  Category.TRAVEL:     'Reisen & Orte',
  Category.ACTIVITIES: 'Aktivitäten',
  Category.OBJECTS:    'Objekte',
  Category.SYMBOLS:    'Symbole',
  Category.FLAGS:      'Flaggen',
};

Map<String, List<String>> get _emojiCategories {
  final result = <String, List<String>>{};
  for (final cat in defaultEmojiSet) {
    final name = _categoryNames[cat.category];
    if (name != null) {
      result[name] = cat.emoji.map((e) => e.emoji).toList();
    }
  }
  return result;
}


const _materialIcons = [
  Icons.favorite, Icons.thumb_up, Icons.star, Icons.rocket_launch,
  Icons.celebration, Icons.bolt, Icons.check_circle, Icons.lightbulb,
  Icons.local_fire_department, Icons.terminal, Icons.code, Icons.bug_report,
  Icons.cloud_upload, Icons.folder, Icons.widgets, Icons.sentiment_very_satisfied,
  Icons.coffee, Icons.build, Icons.school, Icons.home,
];

const _materialIconNames = [
  'favorite', 'thumb_up', 'star', 'rocket_launch',
  'celebration', 'bolt', 'check_circle', 'lightbulb',
  'fire', 'terminal', 'code', 'bug_report',
  'cloud_upload', 'folder', 'widgets', 'sentiment',
  'coffee', 'build', 'school', 'home',
];

// ── Provider ───────────────────────────────────────────────────────────────

class CustomEmojiNotifier extends Notifier<List<String>> {
  Box<String> get _box => Hive.box<String>('custom_emojis');

  @override
  List<String> build() {
    if (_box.isEmpty) return ['🦄', '🧃', '🪄'];
    return _box.values.toList();
  }

  void add(String emoji) {
    _box.put(emoji, emoji);
    state = [...state, emoji];
  }

  void remove(String emoji) {
    _box.delete(emoji);
    state = state.where((e) => e != emoji).toList();
  }
}

final customEmojiProvider = NotifierProvider<CustomEmojiNotifier, List<String>>(CustomEmojiNotifier.new);

class RecentEmojiNotifier extends Notifier<List<String>> {
  static const _maxRecent = 18;
  Box<String> get _box => Hive.box<String>('recent_emojis');

  @override
  List<String> build() => _box.values.toList();

  void use(String emoji) {
    final updated = [emoji, ...state.where((e) => e != emoji)];
    final trimmed = updated.take(_maxRecent).toList();
    _box.clear();
    for (final e in trimmed) {
      _box.add(e);
    }
    state = trimmed;
  }
}

final recentEmojiProvider = NotifierProvider<RecentEmojiNotifier, List<String>>(RecentEmojiNotifier.new);

// ── Tab ────────────────────────────────────────────────────────────────────

class EmojiTab extends ConsumerWidget {
  const EmojiTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(searchQueryProvider).toLowerCase();

    return ListView(
      padding: const EdgeInsets.all(10),
      children: [
        if (query.isEmpty) ...[
          if (ref.watch(recentEmojiProvider).isNotEmpty) ...[
            _SectionTitle('Zuletzt verwendet'),
            _EmojiGrid(emojis: ref.watch(recentEmojiProvider)),
          ],
          ..._emojiCategories.entries.map((e) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [_SectionTitle(e.key), _EmojiGrid(emojis: e.value)],
          )),
          _Divider(),
          _MaterialIconsSection(),
          _Divider(),
          _CustomEmojiSection(),
        ] else ...[
          _SectionTitle('Ergebnisse'),
          _EmojiGrid(
            emojis: [
              ...ref.watch(recentEmojiProvider),
              ..._emojiCategories.values.expand((e) => e),
              ...ref.watch(customEmojiProvider),
            ].where((e) => e.toLowerCase().contains(query)).toList(),
          ),
        ],
      ],
    );
  }
}

// ── Emoji Grid ─────────────────────────────────────────────────────────────

class _EmojiGrid extends StatelessWidget {
  final List<String> emojis;
  const _EmojiGrid({required this.emojis});

  @override
  Widget build(BuildContext context) {
    if (emojis.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Text('Keine Emojis gefunden', style: TextStyle(color: Color(0xFF6B6B82), fontSize: 12)),
      );
    }
    return GridView.count(
      crossAxisCount: 9,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 2,
      crossAxisSpacing: 2,
      children: emojis.map((e) => _EmojiBtn(emoji: e)).toList(),
    );
  }
}

class _EmojiBtn extends ConsumerStatefulWidget {
  final String emoji;
  const _EmojiBtn({required this.emoji});

  @override
  ConsumerState<_EmojiBtn> createState() => _EmojiBtnState();
}

class _EmojiBtnState extends ConsumerState<_EmojiBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () {
          Clipboard.setData(ClipboardData(text: widget.emoji));
          ref.read(recentEmojiProvider.notifier).use(widget.emoji);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          decoration: BoxDecoration(
            color: _hovered ? const Color(0xFF21212B) : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          transform: _hovered
              ? (Matrix4.identity()..scale(1.2))
              : Matrix4.identity(),
          transformAlignment: Alignment.center,
          child: Center(
            child: Text(widget.emoji, style: const TextStyle(fontSize: 20)),
          ),
        ),
      ),
    );
  }
}

// ── Material Icons ─────────────────────────────────────────────────────────

class _MaterialIconsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Material Icons',
                style: TextStyle(fontSize: 10, color: Color(0xFF6B6B82),
                    fontFamily: 'monospace', letterSpacing: 0.12)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFF7C6AF7).withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFF7C6AF7).withOpacity(0.25)),
              ),
              child: const Text('Google',
                  style: TextStyle(fontSize: 9, color: Color(0xFF7C6AF7))),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 9,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
          children: List.generate(_materialIcons.length, (i) =>
            _MaterialIconBtn(icon: _materialIcons[i], name: _materialIconNames[i]),
          ),
        ),
      ],
    );
  }
}

class _MaterialIconBtn extends StatefulWidget {
  final IconData icon;
  final String name;
  const _MaterialIconBtn({required this.icon, required this.name});

  @override
  State<_MaterialIconBtn> createState() => _MaterialIconBtnState();
}

class _MaterialIconBtnState extends State<_MaterialIconBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => Clipboard.setData(ClipboardData(text: widget.name)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          decoration: BoxDecoration(
            color: _hovered ? const Color(0xFF21212B) : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Center(
            child: Icon(widget.icon, size: 20,
                color: _hovered ? const Color(0xFF7C6AF7) : const Color(0xFFE8E8F0)),
          ),
        ),
      ),
    );
  }
}

// ── Custom Emojis ──────────────────────────────────────────────────────────

class _CustomEmojiSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final custom = ref.watch(customEmojiProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Eigene Emojis',
                style: TextStyle(fontSize: 10, color: Color(0xFF6B6B82),
                    fontFamily: 'monospace', letterSpacing: 0.12)),
            GestureDetector(
              onTap: () => _showAddEmojiDialog(context, ref),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C6AF7).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF7C6AF7).withOpacity(0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 12, color: Color(0xFF7C6AF7)),
                    SizedBox(width: 4),
                    Text('Hinzufügen',
                        style: TextStyle(fontSize: 11, color: Color(0xFF7C6AF7))),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 9,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
          children: [
            ...custom.map((e) => _EmojiBtn(emoji: e)),
            _AddPlaceholder(onTap: () => _showAddEmojiDialog(context, ref)),
          ],
        ),
      ],
    );
  }

  void _showAddEmojiDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF18181F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Custom Emoji hinzufügen',
            style: TextStyle(color: Color(0xFFE8E8F0), fontSize: 14)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Color(0xFFE8E8F0), fontSize: 24),
          decoration: InputDecoration(
            hintText: 'Emoji eingeben z.B. 🦄',
            hintStyle: const TextStyle(color: Color(0xFF6B6B82), fontSize: 14),
            filled: true,
            fillColor: const Color(0xFF0F0F13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF2A2A38)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF2A2A38)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF7C6AF7)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Abbrechen', style: TextStyle(color: Color(0xFF6B6B82))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C6AF7),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              final emoji = controller.text.trim();
              if (emoji.isNotEmpty) {
                ref.read(customEmojiProvider.notifier).add(emoji);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Speichern', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _AddPlaceholder extends StatefulWidget {
  final VoidCallback onTap;
  const _AddPlaceholder({required this.onTap});

  @override
  State<_AddPlaceholder> createState() => _AddPlaceholderState();
}

class _AddPlaceholderState extends State<_AddPlaceholder> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          decoration: BoxDecoration(
            border: Border.all(
              color: _hovered ? const Color(0xFF7C6AF7) : const Color(0xFF2A2A38),
              style: BorderStyle.solid,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Icon(Icons.add, size: 18, color: Color(0xFF6B6B82)),
          ),
        ),
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Text(title.toUpperCase(),
          style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF6B6B82),
              fontFamily: 'monospace',
              letterSpacing: 0.12)),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Divider(color: Color(0xFF2A2A38), height: 1),
    );
  }
}
