import 'package:flutter/material.dart';
import 'account/account_creation_page.dart';

void main() {
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