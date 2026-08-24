import 'package:flutter/material.dart';

import 'news_history_store.dart';
import 'pinned_news_store.dart';

class NewsHistoryPage extends StatefulWidget {
  const NewsHistoryPage({super.key});

  @override
  State<NewsHistoryPage> createState() => _NewsHistoryPageState();
}

class _NewsHistoryPageState extends State<NewsHistoryPage> {
  late Future<List<NewsHistoryItem>> _historyFuture;
  Set<String> _pinnedIds = {};

  @override
  void initState() {
    super.initState();
    _historyFuture = NewsHistoryStore.load();
    _loadPins();
  }

  Future<void> _loadPins() async {
    final pins = await PinnedNewsStore.load();
    if (mounted) setState(() => _pinnedIds = pins.map((pin) => pin.id).toSet());
  }

  Future<void> _togglePin(NewsHistoryItem item) async {
    final isPinned = await PinnedNewsStore.toggle(
      PinnedNews(
        title: item.title,
        url: item.url,
        thumbnailUrl: item.thumbnailUrl,
        source: item.source,
        pinnedAt: DateTime.now(),
      ),
    );
    if (!mounted) return;
    setState(() {
      if (isPinned)
        _pinnedIds.add(item.id);
      else
        _pinnedIds.remove(item.id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(isPinned ? 'ニュースをピン留めしました' : 'ピン留めを解除しました')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE4EBF5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE4EBF5),
        surfaceTintColor: const Color(0xFFE4EBF5),
        centerTitle: true,
        title: const Text(
          '過去のニュース',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<List<NewsHistoryItem>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          final items = snapshot.data ?? [];
          if (items.isEmpty)
            return const Center(child: Text('取得したニュースはまだありません'));
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              final date =
                  '${item.viewedAt.year}/${item.viewedAt.month.toString().padLeft(2, '0')}/${item.viewedAt.day.toString().padLeft(2, '0')}';
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        item.thumbnailUrl,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const SizedBox(
                          width: 64,
                          height: 64,
                          child: Icon(Icons.image_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '$date  ${item.source}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: _pinnedIds.contains(item.id)
                          ? 'ピン留めを解除'
                          : 'ピン留めする',
                      onPressed: () => _togglePin(item),
                      icon: Icon(
                        _pinnedIds.contains(item.id)
                            ? Icons.push_pin
                            : Icons.push_pin_outlined,
                      ),
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
