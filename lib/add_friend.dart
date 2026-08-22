import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'settings_page.dart';
import 'world_map_page.dart';

class AddFriendPage extends StatefulWidget {
  const AddFriendPage({super.key});

  @override
  State<AddFriendPage> createState() => _AddFriendPageState();
}

class _AddFriendPageState extends State<AddFriendPage> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedIndex = 2; 

<<<<<<< HEAD
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _pendingRequests = []; // 承認待ちリスト
  bool _isLoading = false;
=======
  final String id;
  final String userId;
  final String username;
}

class FriendRequestsPage extends StatefulWidget {
  const FriendRequestsPage({super.key, this.initialRequests = const []});

  final List<FriendRequest> initialRequests;

  @override
  State<FriendRequestsPage> createState() => _FriendRequestsPageState();
}

class _FriendRequestsPageState extends State<FriendRequestsPage> {
  late final List<FriendRequest> _requests;
  bool _isLoading = true;
  String? _loadError;
>>>>>>> origin/feature/news-home

  @override
  void initState() {
    super.initState();
<<<<<<< HEAD
    _fetchPendingRequests(); // 画面を開いた時に承認待ちを取得する
  }

=======
    _requests = List.of(widget.initialRequests);
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    final client = Supabase.instance.client;
    final currentUser = client.auth.currentUser;

    if (currentUser == null) {
      setState(() {
        _isLoading = false;
        _loadError = 'ログインするとフレンド申請を確認できます';
      });
      return;
    }

    try {
      final requests = await client
          .from('friendships')
          .select('id, sender_id')
          .eq('receiver_id', currentUser.id)
          .eq('status', 'pending');
      final requestRows = List<Map<String, dynamic>>.from(requests);

      if (requestRows.isEmpty) {
        if (!mounted) return;
        setState(() {
          _requests.clear();
          _isLoading = false;
          _loadError = null;
        });
        return;
      }

      final senderIds = requestRows
          .map((request) => request['sender_id'].toString())
          .toList();
      final profiles = await client
          .from('profiles')
          .select('id, username')
          .inFilter('id', senderIds);
      final profilesById = {
        for (final profile in List<Map<String, dynamic>>.from(profiles))
          profile['id'].toString(): profile,
      };

      if (!mounted) return;
      setState(() {
        _requests
          ..clear()
          ..addAll(
            requestRows.map((request) {
              final senderId = request['sender_id'].toString();
              final profile = profilesById[senderId];
              return FriendRequest(
                id: request['id'].toString(),
                userId: senderId,
                username: profile?['username']?.toString() ?? 'ユーザー名未設定',
              );
            }),
          );
        _isLoading = false;
        _loadError = null;
      });
    } catch (error) {
      debugPrint('フレンド申請取得エラー: $error');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = 'フレンド申請の取得に失敗しました';
      });
    }
  }

  Future<void> _respondToRequest(
    FriendRequest request, {
    required bool approved,
  }) async {
    final status = approved ? 'accepted' : 'rejected';

    try {
      await Supabase.instance.client
          .from('friendships')
          .update({'status': status})
          .eq('id', request.id);

      if (!mounted) return;
      setState(() {
        _requests.removeWhere((item) => item.id == request.id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            approved
                ? '@${request.username}さんの申請を承認しました'
                : '@${request.username}さんの申請を拒否しました',
          ),
        ),
      );
    } catch (error) {
      debugPrint('フレンド申請更新エラー: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('フレンド申請の更新に失敗しました')));
    }
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFFE4EBF5);
    const textColor = Color(0xFF1E293B);
    const subTextColor = Color(0xFF94A3B8);
    const primaryColor = Color(0xFF475569);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        surfaceTintColor: backgroundColor,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: textColor),
          tooltip: 'ホームに戻る',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'フレンド申請',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
          ? Center(
              child: Text(
                _loadError!,
                style: const TextStyle(fontSize: 14, color: subTextColor),
              ),
            )
          : _requests.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.mark_email_read_outlined,
                    size: 48,
                    color: subTextColor,
                  ),
                  SizedBox(height: 12),
                  Text(
                    '受信したフレンド申請はありません',
                    style: TextStyle(fontSize: 14, color: subTextColor),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: _requests.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final request = _requests[index];

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 25,
                            backgroundColor: Color(0xFFE2E8F0),
                            child: Icon(Icons.person, color: primaryColor),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '@${request.username}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  request.userId,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: subTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () =>
                                  _respondToRequest(request, approved: false),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: textColor,
                                side: const BorderSide(
                                  color: Color(0xFFCBD5E1),
                                ),
                              ),
                              child: const Text('拒否する'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () =>
                                  _respondToRequest(request, approved: true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                              ),
                              child: const Text('承認する'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _AddFriendPageState extends State<AddFriendPage> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedIndex = 2;
  Map<String, dynamic>? _searchResult;
  String? _searchError;
  bool _hasSearched = false;
  bool _isSearching = false;

>>>>>>> origin/feature/news-home
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

// --- 1. 承認待ちリストを取得する処理 ---
  Future<void> _fetchPendingRequests() async {
    // ★ここを受信者（wtatsuki2027さん）のIDに仮置きして「なりすまし」ます
    final currentUserId = supabase.auth.currentUser?.id ?? '57865d04-98f1-4648-907d-458063d8e9a2'; // ←コピーしたreceiver_idをフルで貼り付け！

    if (currentUserId.isEmpty || currentUserId == '57865d04-xxxx-xxxx-xxxx-xxxxxxxxxxxx') {
       // もしそのままコピペしてしまった場合のためのエラー回避
       // 自分の場合はここは消してもOKです
    }

    try {
      // friendshipsテーブルから、自分が受信者で status が pending のものを探す
      final requests = await supabase
          .from('friendships')
          .select('id, sender_id')
          .eq('receiver_id', currentUserId)
          .eq('status', 'pending');

      if (requests.isEmpty) {
        setState(() => _pendingRequests = []);
        return;
      }

      // 送信者のプロフィール情報（名前など）を取得する
      final senderIds = requests.map((r) => r['sender_id']).toList();
      final profiles = await supabase
          .from('profiles')
          .select('id, username')
          .inFilter('id', senderIds);

      // リクエスト情報とプロフィール情報を合体させる
      final combined = requests.map((req) {
        final profile = profiles.firstWhere(
          (p) => p['id'] == req['sender_id'],
          orElse: () => {'username': '不明なユーザー'},
        );
        return {
          'request_id': req['id'],
          'sender_id': req['sender_id'],
          'username': profile['username'],
        };
      }).toList();

      setState(() {
        _pendingRequests = combined;
      });
    } catch (e) {
      debugPrint('承認待ち取得エラー: $e');
    }
  }

  // --- 2. リクエストを承認する処理 ---
  Future<void> _acceptRequest(String requestId) async {
    try {
      // friendshipsテーブルのステータスを accepted に更新
      await supabase
          .from('friendships')
          .update({'status': 'accepted'})
          .eq('id', requestId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('フレンドリクエストを承認しました！')),
        );
      }
      
      // 承認が終わったら、リストを再取得して画面から消す
      _fetchPendingRequests();
      
    } catch (e) {
      debugPrint('承認エラー: $e');
    }
  }

// --- 3. ユーザー検索処理 ---
  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) return;
    setState(() => _isLoading = true);

    try {
      final currentUserId = supabase.auth.currentUser?.id;
      
      // ① まず「検索条件（フィルター）」までを変数にセットする（limitはまだつけない）
      var dbFilter = supabase
          .from('profiles')
          .select('id, username')
          .ilike('username', '%$query%');

      // ② ログインしている時だけ、自分を除外する条件を追加
      if (currentUserId != null && currentUserId.isNotEmpty) {
        dbFilter = dbFilter.neq('id', currentUserId);
      }

      // ③ 最後に .limit(10) をくっつけて実行（await）する！
      final response = await dbFilter.limit(10);

      setState(() {
        _searchResults = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('検索エラー: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

// --- 4. フレンドリクエスト送信処理 ---
  Future<void> _sendFriendRequest(String receiverId) async {
    // ★ログインIDが取得できないテスト環境用に、ダミーの自分自身のIDを仮置きします。
    // Supabaseのprofilesテーブルから、あなた自身のテスト用UUIDをコピーしてここに入れてください。
    final currentUserId = supabase.auth.currentUser?.id ?? '82aa5989-3192-42cb-8140-b9cebe2db4b9'; 
    
    if (currentUserId.isEmpty || currentUserId == 'あなた自身のテスト用UUIDをコピーしてここに入れてください') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('テスト用のUUIDが設定されていません。コードを書き換えてください。')),
      );
      return;
    }

    try {
      await supabase.from('friendships').insert({
        'sender_id': currentUserId,
        'receiver_id': receiverId,
        'status': 'pending',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('リクエストを送信しました（承認待ち）')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          // 何のエラーか分かりやすいように詳細を表示
          SnackBar(content: Text('送信エラー: $e')), 
        );
      }
    }
  }

  Future<void> _sendFriendRequest() async {
    final profile = _searchResult;
    final currentUser = Supabase.instance.client.auth.currentUser;

    if (profile == null || currentUser == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ログインしてからフレンド申請を送信してください')));
      return;
    }

    final receiverId = profile['id'].toString();
    if (receiverId == currentUser.id) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('自分自身にはフレンド申請を送信できません')));
      return;
    }

    try {
      await Supabase.instance.client.from('friendships').insert({
        'sender_id': currentUser.id,
        'receiver_id': receiverId,
        'status': 'pending',
      });

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('フレンド申請を送信しました')));
    } catch (error) {
      debugPrint('フレンド申請送信エラー: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('フレンド申請の送信に失敗しました')));
    }
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFFE4EBF5);
    const textColor = Color(0xFF1E293B);
    const subTextColor = Color(0xFF94A3B8);
    const primaryColor = Color(0xFF475569);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: textColor),
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                      const Expanded(
                        child: Center(
                          child: Text(
                            'フレンド追加',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Container(
                      width: 120, height: 4,
                      decoration: BoxDecoration(color: const Color(0xFF8899A6), borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ==========================================
                  // 新規追加：あなた宛ての承認待ちリスト表示エリア
                  // ==========================================
                  if (_pendingRequests.isNotEmpty) ...[
                    const Text('あなたへのリクエスト', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _pendingRequests.length,
                      itemBuilder: (context, index) {
                        final req = _pendingRequests[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(25),
                                child: Image.network('https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150', width: 50, height: 50, fit: BoxFit.cover),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  req['username'] ?? '名称未設定', 
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                                ),
                              ),
                              // 承認ボタン
                              ElevatedButton(
                                onPressed: () => _acceptRequest(req['request_id']),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange, // 承認ボタンは目立つ色に
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  elevation: 0,
                                ),
                                child: const Text('承認する', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                  // ==========================================

                  const Text('ユーザー名で検索', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: TextField(
                      controller: _searchController,
                      onSubmitted: (value) => _searchUsers(value),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search, color: subTextColor),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.check_circle, color: primaryColor),
                          onPressed: () => _searchUsers(_searchController.text),
                        ),
                        hintText: 'ユーザー名を入力',
                        hintStyle: const TextStyle(color: subTextColor, fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text('検索結果', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: subTextColor)),
                  const SizedBox(height: 10),

                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
<<<<<<< HEAD
                  else if (_searchResults.isEmpty)
                    const Center(child: Text('ユーザーが見つかりません', style: TextStyle(color: subTextColor, fontSize: 13)))
=======
                  else if (_searchResult != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 25,
                            backgroundColor: Color(0xFFE2E8F0),
                            child: Icon(Icons.person, color: primaryColor),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '@${_searchResult!['username'] ?? 'ユーザー名未設定'}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _searchResult!['id'].toString(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: subTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _sendFriendRequest,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                            ),
                            child: const Text('追加する'),
                          ),
                        ],
                      ),
                    )
>>>>>>> origin/feature/news-home
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final user = _searchResults[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(25),
                                child: Image.network('https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150', width: 50, height: 50, fit: BoxFit.cover),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  user['username'] ?? '名称未設定', 
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () => _sendFriendRequest(user['id']),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor, foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  elevation: 0,
                                ),
                                child: const Text('追加', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: backgroundColor,
        selectedItemColor: textColor,
        unselectedItemColor: subTextColor,
        currentIndex: _selectedIndex,
<<<<<<< HEAD
        onTap: (index) => setState(() => _selectedIndex = index),
=======
        onTap: (index) {
          if (index == 1) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const WorldMapPage()),
            );
            return;
          }

          if (index == 3) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            );
            return;
          }

          setState(() {
            _selectedIndex = index;
          });
        },
>>>>>>> origin/feature/news-home
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