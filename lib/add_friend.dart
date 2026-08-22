import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'settings_page.dart';
import 'world_map_page.dart';

class AddFriendPage extends StatefulWidget {
  const AddFriendPage({super.key});

  @override
  State<AddFriendPage> createState() => _AddFriendPageState();
}

class FriendRequest {
  const FriendRequest({
    required this.id,
    required this.userId,
    required this.username,
  });

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

  @override
  void initState() {
    super.initState();
    _requests = List.of(widget.initialRequests);
  }

  void _respondToRequest(FriendRequest request, {required bool approved}) {
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
      body: _requests.isEmpty
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUser() async {
    final userId = _searchController.text.trim();

    if (userId.isEmpty) {
      setState(() {
        _hasSearched = false;
        _searchResult = null;
        _searchError = null;
      });
      return;
    }

    setState(() {
      _hasSearched = true;
      _isSearching = true;
      _searchResult = null;
      _searchError = null;
    });

    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('id, username')
          .eq('id', userId)
          .maybeSingle();

      if (!mounted) return;

      setState(() {
        _searchResult = profile;
        _isSearching = false;
      });
    } catch (error) {
      debugPrint('ユーザー検索エラー: $error');

      if (!mounted) return;

      setState(() {
        _searchError = 'ユーザーの検索に失敗しました';
        _isSearching = false;
      });
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          size: 20,
                          color: textColor,
                        ),
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                      const Expanded(
                        child: Center(
                          child: Text(
                            'フレンド追加',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.mark_email_unread_outlined,
                          color: textColor,
                        ),
                        tooltip: 'フレンド申請',
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const FriendRequestsPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Container(
                      width: 120,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFF8899A6),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'ユーザーIDで検索',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _searchUser(),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search, color: subTextColor),
                        hintText: 'ユーザーIDを入力',
                        hintStyle: TextStyle(color: subTextColor, fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '検索結果',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: subTextColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_isSearching)
                    const Center(child: CircularProgressIndicator())
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
                        ],
                      ),
                    )
                  else
                    Center(
                      child: Text(
                        _searchError ??
                            (_hasSearched
                                ? '該当するユーザーが見つかりません'
                                : 'IDを入力してキーボードの検索を押してください'),
                        style: const TextStyle(
                          fontSize: 13,
                          color: subTextColor,
                        ),
                      ),
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
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'ホーム',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on_outlined),
            label: '地図',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'マイページ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: '設定',
          ),
        ],
      ),
    );
  }
}
