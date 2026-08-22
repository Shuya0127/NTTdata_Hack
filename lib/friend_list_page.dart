import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    final currentUser = client.auth.currentUser;
    if (currentUser == null) return [];

    final sentRelationships = await client
        .from('friendships')
        .select('id, receiver_id')
        .eq('sender_id', currentUser.id)
        .eq('status', 'accepted');
    final receivedRelationships = await client
        .from('friendships')
        .select('id, sender_id')
        .eq('receiver_id', currentUser.id)
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
<<<<<<< HEAD
  int _selectedIndex = 2; // マイページまたは関連タブ

  // フレンド一覧のダミーデータ
  final List<Map<String, String>> _friends = [
    {
      'name': '佐藤 花子',
      'id': '@sato_hanako',
      'imageUrl': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
    },
    {
      'name': '鈴木 一郎',
      'id': '@suzuki_ichiro',
      'imageUrl': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
    },
    {
      'name': '高橋 美咲',
      'id': '@takahashi_misaki',
      'imageUrl': 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150',
    },
    {
      'name': '伊藤 健太',
      'id': '@ito_kenta',
      'imageUrl': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
    },
    {
      'name': '渡辺 あおい',
      'id': '@watanabe_aoi',
      'imageUrl': 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150',
    },
    {
      'name': '山本 大輔',
      'id': '@yamamoto_daisuke',
      'imageUrl': 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150',
    },
  ];

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFFE4EBF5); // 背景色
    const textColor = Color(0xFF1E293B);       // テキスト色
    const subTextColor = Color(0xFF94A3B8);    // 補足テキスト色

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // ヘッダー（戻るボタン ＋ タイトル）
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: textColor),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'フレンド一覧',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // 左右中央揃え用の余白
                ],
              ),
            ),

            // フレンドカードリスト
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                itemCount: _friends.length,
                itemBuilder: (context, index) {
                  final friend = _friends[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: Image.network(
                          friend['imageUrl']!,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                      ),
                      title: Text(
                        friend['name']!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      subtitle: Text(
                        friend['id']!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: subTextColor,
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right, color: subTextColor),
                      onTap: () {
                        // フレンド詳細などの遷移処理
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // ボトムナビゲーションバー
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: backgroundColor,
        selectedItemColor: textColor,
        unselectedItemColor: subTextColor,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'ホーム'),
          BottomNavigationBarItem(icon: Icon(Icons.location_on_outlined), label: '地図'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'マイページ'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: '設定'),
        ],
      ),
    );
  }
}
=======
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
      if (!mounted) return;
      setState(() {
        _friendsFuture = FriendRepository.loadFriends();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('@${friend.username}さんをフレンドから削除しました')),
      );
    } catch (error) {
      debugPrint('フレンド削除エラー: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('フレンドの削除に失敗しました')));
    }
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
            return const Center(
              child: Text(
                'フレンド一覧の取得に失敗しました',
                style: TextStyle(fontSize: 14, color: subTextColor),
              ),
            );
          }

          final friends = snapshot.data ?? [];
          if (friends.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.people_outline, size: 48, color: subTextColor),
                  SizedBox(height: 12),
                  Text(
                    'フレンドはまだいません',
                    style: TextStyle(fontSize: 14, color: subTextColor),
                  ),
                ],
              ),
            );
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
>>>>>>> origin/feature/news-home
