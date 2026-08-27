import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'testlogin/test_login_page.dart';

/// フレンドからの「いいね」「コメント」を一覧表示する画面。
class LikesCommentsPage extends StatefulWidget {
  const LikesCommentsPage({super.key});

  @override
  State<LikesCommentsPage> createState() => _LikesCommentsPageState();
}

class _LikesCommentsPageState extends State<LikesCommentsPage> {
  bool _isLoading = true;
  String? _loadError;
  List<Map<String, dynamic>> _reactions = [];

  @override
  void initState() {
    super.initState();
    _loadReactions();
  }

  Future<void> _loadReactions() async {
    final client = Supabase.instance.client;
    final currentUserId =
        TestSession.currentUserId ?? client.auth.currentUser?.id;

    if (currentUserId == null) {
      setState(() {
        _isLoading = false;
        _loadError = 'ログインするといいね・コメントを確認できます';
      });
      return;
    }

    try {
      // 1. 自分が読んだニュースの履歴を取得
      final myHistory = await client
          .from('user_read_news')
          .select('id, news_url')
          .eq('user_id', currentUserId);
      final historyRows = List<Map<String, dynamic>>.from(myHistory);

      if (historyRows.isEmpty) {
        if (!mounted) return;
        setState(() {
          _reactions = [];
          _isLoading = false;
        });
        return;
      }

      final historyIds = historyRows
          .map((history) => history['id'].toString())
          .toList();
      final newsUrlByHistoryId = {
        for (final history in historyRows)
          history['id'].toString(): history['news_url']?.toString(),
      };

      // 2. そのニュースについた、自分以外からのいいね・コメントを取得
      final likes = await client
          .from('news_likes')
          .select('user_read_news_id, user_id, created_at')
          .inFilter('user_read_news_id', historyIds)
          .neq('user_id', currentUserId);
      final comments = await client
          .from('news_comments')
          .select('user_read_news_id, user_id, comment, created_at')
          .inFilter('user_read_news_id', historyIds)
          .neq('user_id', currentUserId);

      final likeRows = List<Map<String, dynamic>>.from(likes);
      final commentRows = List<Map<String, dynamic>>.from(comments);

      // 3. 反応してきたユーザーのプロフィールを取得
      final actorIds = <String>{
        ...likeRows.map((row) => row['user_id'].toString()),
        ...commentRows.map((row) => row['user_id'].toString()),
      }.toList();

      var profilesById = <String, Map<String, dynamic>>{};
      if (actorIds.isNotEmpty) {
        final profiles = await client
            .from('profiles')
            .select('id, username, avatar_url')
            .inFilter('id', actorIds);
        profilesById = {
          for (final profile in List<Map<String, dynamic>>.from(profiles))
            profile['id'].toString(): profile,
        };
      }

      // 4. 該当ニュースのタイトルを取得
      final newsUrls = newsUrlByHistoryId.values
          .whereType<String>()
          .toSet()
          .toList();
      var newsTitleByUrl = <String, String>{};
      if (newsUrls.isNotEmpty) {
        final newsRows = await client
            .from('news')
            .select('url, title')
            .inFilter('url', newsUrls);
        newsTitleByUrl = {
          for (final news in List<Map<String, dynamic>>.from(newsRows))
            news['url'].toString(): news['title']?.toString() ?? 'タイトル不明',
        };
      }

      String titleFor(String historyId) {
        final url = newsUrlByHistoryId[historyId];
        if (url == null) return 'タイトル不明';
        return newsTitleByUrl[url] ?? 'タイトル不明';
      }

      // 5. いいね・コメントを時系列でまとめる
      final merged = <Map<String, dynamic>>[];
      for (final like in likeRows) {
        final profile = profilesById[like['user_id'].toString()];
        merged.add({
          'type': 'like',
          'username': profile?['username']?.toString() ?? 'ユーザー',
          'avatar_url': profile?['avatar_url']?.toString(),
          'news_title': titleFor(like['user_read_news_id'].toString()),
          'created_at': like['created_at'].toString(),
        });
      }
      for (final comment in commentRows) {
        final profile = profilesById[comment['user_id'].toString()];
        merged.add({
          'type': 'comment',
          'username': profile?['username']?.toString() ?? 'ユーザー',
          'avatar_url': profile?['avatar_url']?.toString(),
          'comment': comment['comment']?.toString() ?? '',
          'news_title': titleFor(comment['user_read_news_id'].toString()),
          'created_at': comment['created_at'].toString(),
        });
      }
      merged.sort(
        (a, b) =>
            (b['created_at'] as String).compareTo(a['created_at'] as String),
      );

      if (!mounted) return;
      setState(() {
        _reactions = merged;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = '読み込みに失敗しました';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFFF8FAFD);
    const text = Color(0xFF111827);
    const subtext = Color(0xFF64748B);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        surfaceTintColor: background,
        centerTitle: true,
        title: const Text(
          'いいね・コメント',
          style: TextStyle(fontWeight: FontWeight.bold, color: text),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
          ? Center(
              child: Text(_loadError!, style: const TextStyle(color: subtext)),
            )
          : _reactions.isEmpty
          ? const Center(
              child: Text('まだいいね・コメントはありません', style: TextStyle(color: subtext)),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: _reactions.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final reaction = _reactions[index];
                final isLike = reaction['type'] == 'like';
                final avatarUrl = reaction['avatar_url'] as String?;

                return Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundColor: const Color(0xFFEFF3F8),
                          backgroundImage:
                              (avatarUrl != null && avatarUrl.isNotEmpty)
                              ? NetworkImage(avatarUrl)
                              : null,
                          child: (avatarUrl == null || avatarUrl.isEmpty)
                              ? Icon(
                                  isLike
                                      ? Icons.thumb_up_alt
                                      : Icons.mode_comment_outlined,
                                  color: isLike
                                      ? Colors.blue
                                      : const Color(0xFF475569),
                                )
                              : null,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isLike
                                    ? '${reaction['username']}さんがいいねしました'
                                    : '${reaction['username']}さんがコメントしました',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                reaction['news_title'] as String,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: subtext,
                                ),
                              ),
                              if (!isLike) ...[
                                const SizedBox(height: 6),
                                Text(
                                  reaction['comment'] as String,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: text,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
