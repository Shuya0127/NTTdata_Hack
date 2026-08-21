import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'account/account_creation_page.dart';

void main() {
=======
import 'package:supabase_flutter/supabase_flutter.dart';
import 'account/account_creation_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // URLとキーを直接書き込みます
  await Supabase.initialize(
    url: 'https://wpifjbdmfzzbuqhcwitn.supabase.co', // あなたのURL
    anonKey: 'sb_publishable_a95qobQRyKDpMDK0vKWQzw_QdLyvk6z', // あなたのキー
  );

>>>>>>> 045f6b4fd4a9a3c1123210e205627bac04dbda73
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