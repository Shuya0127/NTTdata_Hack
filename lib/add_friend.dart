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

  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _pendingRequests = []; // 承認待ちリスト
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchPendingRequests(); // 画面を開いた時に承認待ちを取得する
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- 1. 承認待ちリストを取得する処理 ---
  Future<void> _fetchPendingRequests() async {
    final currentUserId = supabase.auth.currentUser?.id ?? '82aa5989-3192-42cb-8140-b9cebe2db4b9'; 

    try {
      final requests = await supabase
          .from('friendships')
          .select('id, sender_id')
          .eq('receiver_id', currentUserId)
          .eq('status', 'pending');

      if (requests.isEmpty) {
        setState(() => _pendingRequests = []);
        return;
      }

      final senderIds = requests.map((r) => r['sender_id']).toList();
      final profiles = await supabase
          .from('profiles')
          .select('id, username')
          .inFilter('id', senderIds);

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
      await supabase
          .from('friendships')
          .update({'status': 'accepted'})
          .eq('id', requestId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('フレンドリクエストを承認しました！')),
        );
      }
      
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
      
      var dbFilter = supabase
          .from('profiles')
          .select('id, username')
          .ilike('username', '%$query%');

      if (currentUserId != null && currentUserId.isNotEmpty) {
        dbFilter = dbFilter.neq('id', currentUserId);
      }

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
    final currentUserId = supabase.auth.currentUser?.id ?? '82aa5989-3192-42cb-8140-b9cebe2db4b9'; 
    
    if (currentUserId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('テスト用のUUIDが設定されていません。')),
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
          SnackBar(content: Text('送信エラー: $e')), 
        );
      }
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

                  // 承認待ちリスト表示エリア
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
                              ElevatedButton(
                                onPressed: () => _acceptRequest(req['request_id']),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
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
                  else if (_searchResults.isEmpty)
                    const Center(child: Text('ユーザーが見つかりません', style: TextStyle(color: subTextColor, fontSize: 13)))
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