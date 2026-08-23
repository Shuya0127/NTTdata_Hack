import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'account/account_creation_page.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // URLとキーを直接書き込みます
  await Supabase.initialize(
    url: 'https://wpifjbdmfzzbuqhcwitn.supabase.co', // あなたのURL
    anonKey: 'sb_publishable_a95qobQRyKDpMDK0vKWQzw_QdLyvk6z', // あなたのキー
  );

  await Firebase.initializeApp();
  await NotificationService.initialize();

  runApp(const AccountApp());
}

class AccountApp extends StatelessWidget {
  const AccountApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'アカウント作成',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const AccountCreationPage(),
    );
  }
}