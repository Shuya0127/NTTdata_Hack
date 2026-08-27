import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'account/login_page.dart';
import 'config/supabase_config.dart';
import 'news/news_home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );

  runApp(const NewsApp());
}

class NewsApp extends StatelessWidget {
  const NewsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Nows',
      theme: ThemeData(useMaterial3: true),
      home: const _SessionGate(),
    );
  }
}

/// Supabase が端末に保持しているログイン状態に応じて、起動先を切り替える。
class _SessionGate extends StatelessWidget {
  const _SessionGate();

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = Supabase.instance.client.auth.currentSession != null;
    return isLoggedIn ? const NewsHomePage() : const LoginPage();
  }
}
