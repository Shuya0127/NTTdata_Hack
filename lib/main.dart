import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'account/account_creation_page.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase の初期化
  await Supabase.initialize(
    url: 'https://wpifjbdmfzzbuqhcwitn.supabase.co',
    anonKey: 'sb_publishable_a95qobQRyKDpMDK0vKWQzw_QdLyvk6z',
  );

  // Firebase / 通知の初期化
  await Firebase.initializeApp();
  await NotificationService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'アカウント作成',
      theme: ThemeData(
        useMaterial3: true,
      ),
      // 起動時にアカウント作成画面を表示
      home: const AccountCreationPage(),
    );
  }
}