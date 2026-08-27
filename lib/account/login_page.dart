import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../news/news_home_page.dart';
import '../services/notification_service.dart';
import '../testlogin/test_login_page.dart';
import 'account_creation_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _userIdController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _userIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final userId = _userIdController.text.trim().toLowerCase();
    final password = _passwordController.text;

    if (!RegExp(r'^[a-z0-9_]{3,30}$').hasMatch(userId) || password.isEmpty) {
      _showError('ユーザーIDとパスワードを入力してください');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: authEmailFromUserId(userId),
        password: password,
      );
      TestSession.currentUserId = null;
      unawaited(NotificationService.saveTokenForCurrentUser());
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const NewsHomePage()),
        (_) => false,
      );
    } on AuthException catch (_) {
      _showError('ユーザーIDまたはパスワードが正しくありません');
    } catch (_) {
      _showError('ログインに失敗しました。時間をおいて再度お試しください');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6EDF6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.newspaper_outlined,
                  size: 48,
                  color: Color(0xFF334155),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Nows',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'ユーザーIDとパスワードでログイン',
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 26),
                _LoginInput(
                  label: 'ユーザーID',
                  controller: _userIdController,
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 14),
                _LoginInput(
                  label: 'パスワード',
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _login,
                    child: Text(_isLoading ? 'ログイン中...' : 'ログイン'),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AccountCreationPage(),
                      ),
                    );
                  },
                  child: const Text('アカウントを作成する'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginInput extends StatelessWidget {
  const _LoginInput({
    required this.label,
    required this.controller,
    this.icon,
    this.obscureText = false,
    this.suffixIcon,
  });

  final String label;
  final TextEditingController controller;
  final IconData? icon;
  final bool obscureText;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon == null ? null : Icon(icon),
        suffixIcon: suffixIcon,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
