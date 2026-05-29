import 'package:flutter/material.dart';
import 'flippi_shell.dart';
import '../../features/clipboard/clipboard_tab.dart';
import '../../features/emoji/emoji_tab.dart';
import '../../features/gif/gif_tab.dart';

class TabContent extends StatelessWidget {
  final FlippiTab activeTab;
  const TabContent({super.key, required this.activeTab});

  @override
  Widget build(BuildContext context) {
    return switch (activeTab) {
      FlippiTab.clipboard => const ClipboardTab(),
      FlippiTab.emoji     => const EmojiTab(),
      FlippiTab.gif       => const GifTab(),
    };
  }
}
