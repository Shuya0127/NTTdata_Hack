import 'package:countries_world_map/countries_world_map.dart';
import 'package:countries_world_map/data/maps/world_map.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'profile_avatar.dart';

class FriendProfilePage extends StatefulWidget {
  const FriendProfilePage({super.key, required this.friendId});

  final String friendId;

  @override
  State<FriendProfilePage> createState() => _FriendProfilePageState();
}

class _FriendProfilePageState extends State<FriendProfilePage> {
  late Future<_FriendProfileData> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfile();
  }

  Future<_FriendProfileData> _loadProfile() async {
    final client = Supabase.instance.client;
    final profile = await client
        .from('profiles')
        .select('user_id, username, avatar_url')
        .eq('id', widget.friendId)
        .maybeSingle();

    if (profile == null) {
      throw Exception('フレンドのプロフィールが見つかりません');
    }

    List<Map<String, dynamic>> pins = [];
    Set<String> visitedCountries = {};

    // 追加テーブルが未作成の環境でも、基本プロフィールは表示する。
    try {
      final rows = await client
          .from('pinned_news')
          .select('news_url, title, thumbnail_url, source, pinned_at')
          .eq('user_id', widget.friendId)
          .order('pinned_at', ascending: false);
      pins = List<Map<String, dynamic>>.from(rows);
    } catch (_) {}

    try {
      final rows = await client
          .from('visited_countries')
          .select('country_code')
          .eq('user_id', widget.friendId);
      visitedCountries = List<Map<String, dynamic>>.from(rows)
          .map((row) => row['country_code']?.toString().toLowerCase())
          .whereType<String>()
          .toSet();
    } catch (_) {}

    return _FriendProfileData(
      userId: profile['user_id']?.toString() ?? widget.friendId,
      username: profile['username']?.toString() ?? 'ユーザー名未設定',
      avatarUrl: profile['avatar_url']?.toString(),
      pins: pins,
      visitedCountries: visitedCountries,
    );
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFFE4EBF5);
    const textColor = Color(0xFF334155);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        surfaceTintColor: backgroundColor,
        centerTitle: true,
        title: const Text(
          'フレンドページ',
          style: TextStyle(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: FutureBuilder<_FriendProfileData>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('フレンド情報の取得に失敗しました'));
          }

          final friend = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              Center(
                child: ProfileAvatar(radius: 56, imageUrl: friend.avatarUrl),
              ),
              const SizedBox(height: 14),
              Center(
                child: Text(
                  '@${friend.username}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  friend.userId,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                '📌 Pins',
                style: TextStyle(
                  color: textColor,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              if (friend.pins.isEmpty)
                const _EmptyCard(message: 'ピン留めしているニュースはありません')
              else
                ...friend.pins.map(_buildPinCard),
              const SizedBox(height: 26),
              Text(
                '🗺️ 地図制覇状況（${friend.visitedCountries.length}カ国）',
                style: const TextStyle(
                  color: textColor,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 260,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: friend.visitedCountries.isEmpty
                    ? const Center(
                        child: Text(
                          'まだ制覇した国はありません',
                          style: TextStyle(color: Color(0xFF94A3B8)),
                        ),
                      )
                    : InteractiveViewer(
                        minScale: 1,
                        maxScale: 5,
                        child: SimpleMap(
                          instructions: SMapWorld.instructions,
                          defaultColor: const Color(0xFFF8FAFC),
                          colors: {
                            for (final country in friend.visitedCountries)
                              country: const Color(0xFFFF9800),
                          },
                          fit: BoxFit.contain,
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPinCard(Map<String, dynamic> pin) {
    final thumbnailUrl = pin['thumbnail_url']?.toString() ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: thumbnailUrl.isEmpty
                ? Container(
                    width: 64,
                    height: 64,
                    color: const Color(0xFFE2E8F0),
                    child: const Icon(Icons.article_outlined),
                  )
                : Image.network(
                    thumbnailUrl,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 64,
                      height: 64,
                      color: const Color(0xFFE2E8F0),
                      child: const Icon(Icons.article_outlined),
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pin['title']?.toString() ?? 'タイトルなし',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF334155),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  pin['source']?.toString() ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendProfileData {
  const _FriendProfileData({
    required this.userId,
    required this.username,
    required this.avatarUrl,
    required this.pins,
    required this.visitedCountries,
  });

  final String userId;
  final String username;
  final String? avatarUrl;
  final List<Map<String, dynamic>> pins;
  final Set<String> visitedCountries;
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Color(0xFF94A3B8)),
      ),
    );
  }
}
