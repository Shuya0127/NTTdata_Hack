import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../testlogin/test_login_page.dart';

class VisitedCountriesStore {
  // 国名表示・表記ゆれから map パッケージ用の2文字コード（ISO小文字）への変換マップ
  static final Map<String, String> _countryNameToCode = {
    'UK': 'gb',
    'GB': 'gb',
    'GREAT BRITAIN': 'gb',
    'UNITED KINGDOM': 'gb',
    'イギリス': 'gb',
    'US': 'us',
    'USA': 'us',
    'UNITED STATES': 'us',
    'アメリカ': 'us',
    'JP': 'jp',
    'JAPAN': 'jp',
    '日本': 'jp',
    'FR': 'fr',
    'FRANCE': 'fr',
    'フランス': 'fr',
    'DE': 'de',
    'GERMANY': 'de',
    'ドイツ': 'de',
    'IT': 'it',
    'ITALY': 'it',
    'イタリア': 'it',
    'CA': 'ca',
    'CANADA': 'ca',
    'カナダ': 'ca',
    'AU': 'au',
    'AUSTRALIA': 'au',
    'オーストラリア': 'au',
  };

  // アプリ起動中の制覇済み国コードセット
  static final Set<String> _visitedCountryCodes = <String>{};
  static const _storageKey = 'visited_country_codes';

  // 地図描画用（コード -> カラー）
  static Map<String, Color> get visitedCountriesMap {
    return {
      for (var code in _visitedCountryCodes) code: const Color(0xFFFF9800),
    };
  }

  static int get visitedCount => _visitedCountryCodes.length;

  static Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    _visitedCountryCodes.addAll(preferences.getStringList(_storageKey) ?? []);

    try {
      final userId =
          TestSession.currentUserId ??
          Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      final rows = await Supabase.instance.client
          .from('visited_countries')
          .select('country_code')
          .eq('user_id', userId);
      _visitedCountryCodes.addAll(
        List<Map<String, dynamic>>.from(
          rows,
        ).map((row) => row['country_code'].toString().toLowerCase()),
      );
      await _saveLocal();
    } catch (_) {
      // SupabaseのテーブルやRLS設定が未準備でもローカル保存を使い続ける。
    }
  }

  /// 国名または国コードを受け取って制覇リストに追加する
  static Future<void> markAsVisited(String? countryNameOrCode) async {
    if (countryNameOrCode == null || countryNameOrCode.trim().isEmpty) return;

    final key = countryNameOrCode.trim().toUpperCase();
    final code =
        _countryNameToCode[key] ?? countryNameOrCode.trim().toLowerCase();

    // すでに追加済みなら処理不要
    if (_visitedCountryCodes.contains(code)) return;

    _visitedCountryCodes.add(code);
    await _saveLocal();

    // Supabase に安全に保存（テーブル未作成や未ログイン時でもエラーで落ちないように try-catch）
    try {
      final userId =
          TestSession.currentUserId ??
          Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        await Supabase.instance.client.from('visited_countries').upsert({
          'user_id': userId,
          'country_code': code,
          'visited_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (_) {
      // Supabase連携が準備中の場合はローカル保持のみ継続
    }
  }

  static Future<void> _saveLocal() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(_storageKey, _visitedCountryCodes.toList());
  }
}
