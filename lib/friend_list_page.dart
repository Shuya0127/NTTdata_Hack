import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'testlogin/test_login_page.dart';

import 'profile_avatar.dart';

class FriendSummary {
  const FriendSummary({
    required this.relationshipId,
    required this.userId,
    required this.username,
    this.avatarUrl,
  });

  final String relationshipId;
  final String userId;
  final String username;
  final String? avatarUrl;
}

class FriendRepository {
  static Future<List<FriendSummary>> loadFriends() async {
    final client = Supabase.instance.client;

    // ニュース画面と同じように、まずは TestSession を確認する！
    final currentUserId =
        TestSession.currentUserId ?? client.auth.currentUser?.id;

    if (currentUserId == null) return [];

    // currentUser.id だった部分を currentUserId に書き換える
    final sentRelationships = await client
        .from('friendships')
        .select('id, receiver_id')
        .eq('sender_id', currentUserId)
        .eq('status', 'accepted');

    final receivedRelationships = await client
        .from('friendships')
        .select('id, sender_id')
        .eq('receiver_id', currentUserId)
        .eq('status', 'accepted');

    final friendsById = <String, String>{};
    for (final relationship in List<Map<String, dynamic>>.from(
      sentRelationships,
    )) {
      friendsById[relationship['receiver_id'].toString()] = relationship['id']
          .toString();
    }
    for (final relationship in List<Map<String, dynamic>>.from(
      receivedRelationships,
    )) {
      friendsById[relationship['sender_id'].toString()] = relationship['id']
          .toString();
    }

    if (friendsById.isEmpty) return [];

    final profiles = await client
        .from('profiles')
        .select('id, user_id, username, avatar_url')
        .inFilter('id', friendsById.keys.toList());
    final profilesById = {
      for (final profile in List<Map<String, dynamic>>.from(profiles))
        profile['id'].toString(): profile,
    };

    return friendsById.entries
        .map(
          (entry) => FriendSummary(
            relationshipId: entry.value,
            userId:
                profilesById[entry.key]?['user_id']?.toString() ?? entry.key,
            username:
                profilesById[entry.key]?['username']?.toString() ?? 'ユーザー名未設定',
            avatarUrl: profilesById[entry.key]?['avatar_url']?.toString(),
          ),
        )
        .toList();
  }

  static Future<void> removeFriend(String relationshipId) {
    return Supabase.instance.client
        .from('friendships')
        .delete()
        .eq('id', relationshipId);
  }
}

class FriendListPage extends StatefulWidget {
  const FriendListPage({super.key});

  @override
  State<FriendListPage> createState() => _FriendListPageState();
}

class _FriendListPageState extends State<FriendListPage> {
  late Future<List<FriendSummary>> _friendsFuture;

  @override
  void initState() {
    super.initState();
    _friendsFuture = FriendRepository.loadFriends();
  }

  Future<void> _removeFriend(FriendSummary friend) async {
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('フレンドを削除しますか？'),
        content: Text('@${friend.username}さんをフレンドから削除します。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('削除する'),
          ),
        ],
      ),
    );
    if (shouldRemove != true) return;

    try {
      await FriendRepository.removeFriend(friend.relationshipId);
      _showRemovalSuccess(friend);
    } catch (error) {
      debugPrint('フレンド削除エラー: $error');
      final wasRemoved = await _wasRelationshipRemoved(friend.relationshipId);
      if (wasRemoved) {
        _showRemovalSuccess(friend);
        return;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('フレンドの削除に失敗しました')));
    }
  }

  Future<bool> _wasRelationshipRemoved(String relationshipId) async {
    try {
      final relationship = await Supabase.instance.client
          .from('friendships')
          .select('id')
          .eq('id', relationshipId)
          .maybeSingle();
      return relationship == null;
    } catch (_) {
      return false;
    }
  }

  void _showRemovalSuccess(FriendSummary friend) {
    if (!mounted) return;
    setState(() => _friendsFuture = FriendRepository.loadFriends());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('@${friend.username}さんをフレンドから削除しました')),
    );
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFFE4EBF5);
    const textColor = Color(0xFF334155);
    const subTextColor = Color(0xFF94A3B8);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        surfaceTintColor: backgroundColor,
        centerTitle: true,
        title: const Text(
          'フレンド一覧',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
      body: FutureBuilder<List<FriendSummary>>(
        future: _friendsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('フレンド一覧の取得に失敗しました'));
          }
          final friends = snapshot.data ?? [];
          if (friends.isEmpty) {
            return const Center(child: Text('フレンドはまだいません'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: friends.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final friend = friends[index];
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    ProfileAvatar(radius: 24, imageUrl: friend.avatarUrl),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '@${friend.username}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            friend.userId,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: subTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.person_remove_outlined),
                      tooltip: 'フレンドを削除',
                      color: const Color(0xFFB91C1C),
                      onPressed: () => _removeFriend(friend),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
