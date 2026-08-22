import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'news/news_home_page.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );

  // 通知機能はAndroid/iOS向け。Web(Chrome)にはFirebase設定が無いためスキップする。
  if (!kIsWeb) {
    await Firebase.initializeApp();
    await NotificationService.initialize();
  }

  runApp(const NewsApp());
}

class NewsApp extends StatelessWidget {
  const NewsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ニュースBeReal',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const NewsHomePage(),
    );
  }
}