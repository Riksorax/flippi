import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'gif_config.dart';

class GifEntry {
  final String id;
  final String title;
  final String previewUrl;
  final String url;

  const GifEntry({
    required this.id,
    required this.title,
    required this.previewUrl,
    required this.url,
  });

  factory GifEntry.fromJson(Map<String, dynamic> json) {
    final images = json['images'] as Map<String, dynamic>;
    final fixedWidth = images['fixed_width'] as Map<String, dynamic>;
    final original = images['original'] as Map<String, dynamic>;
    return GifEntry(
      id: json['id'] as String,
      title: (json['title'] as String? ?? '').trim(),
      previewUrl: fixedWidth['webp'] as String? ?? fixedWidth['url'] as String,
      url: original['url'] as String,
    );
  }
}

class GifNotifier extends AsyncNotifier<List<GifEntry>> {
  static const _baseUrl = 'https://api.giphy.com/v1/gifs';

  @override
  Future<List<GifEntry>> build() => _fetchTrending();

  Future<List<GifEntry>> _fetchTrending() async {
    final uri = Uri.parse('$_baseUrl/trending').replace(queryParameters: {
      'api_key': giphyApiKey,
      'limit': '20',
      'rating': 'g',
    });
    final response = await http.get(uri);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data['data'] as List).map((e) => GifEntry.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> search(String query) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final uri = Uri.parse('$_baseUrl/search').replace(queryParameters: {
        'api_key': giphyApiKey,
        'q': query,
        'limit': '20',
        'rating': 'g',
      });
      final response = await http.get(uri);
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return (data['data'] as List).map((e) => GifEntry.fromJson(e as Map<String, dynamic>)).toList();
    });
  }

  Future<void> loadTrending() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchTrending);
  }
}

final gifProvider = AsyncNotifierProvider<GifNotifier, List<GifEntry>>(GifNotifier.new);

class RecentGifNotifier extends Notifier<List<GifEntry>> {
  @override
  List<GifEntry> build() => [];

  void use(GifEntry gif) {
    state = [gif, ...state.where((g) => g.id != gif.id).take(5).toList()];
  }
}

final recentGifProvider = NotifierProvider<RecentGifNotifier, List<GifEntry>>(RecentGifNotifier.new);
