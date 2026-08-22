import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../news/news_home_page.dart';
import 'login_page.dart';

class AccountCreationPage extends StatefulWidget {
  const AccountCreationPage({super.key});

  @override
  State<AccountCreationPage> createState() =>
      _AccountCreationPageState();
}

class _AccountCreationPageState extends State<AccountCreationPage> {
  final TextEditingController _userIdController =
      TextEditingController();

  final TextEditingController _usernameController =
      TextEditingController();

  final TextEditingController _passwordController =
      TextEditingController();

  final TextEditingController _birthdayController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _agreeTerms = false;

  @override
  void dispose() {
    _userIdController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _birthdayController.dispose();
    super.dispose();
  }

  Future<void> _selectBirthday() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _birthdayController.text =
            '${picked.year} / '
            '${picked.month.toString().padLeft(2, '0')} / '
            '${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _createAccount() async {
    if (!_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('利用規約とプライバシーポリシーに同意してください'),
        ),
      );
      return;
    }

    final supabase = Supabase.instance.client;
    final userId = _userIdController.text.trim().toLowerCase();
    final password = _passwordController.text.trim();
    final username = _usernameController.text.trim();
    final birthday = _birthdayController.text.trim();

    if (!RegExp(r'^[a-z0-9_]{3,30}$').hasMatch(userId)) {
      _showError('ユーザーIDは英小文字・数字・_ を使って3〜30文字で入力してください');
      return;
    }
    if (username.isEmpty || birthday.isEmpty || password.length < 8) {
      _showError('ユーザー名・生年月日・8文字以上のパスワードを入力してください');
      return;
    }

    try {
      // Supabase Auth はメールまたは電話番号を必要とするため、画面には
      // 表示しない内部用のメール形式IDをユーザーIDから生成して利用します。
      final AuthResponse res = await supabase.auth.signUp(
        email: authEmailFromUserId(userId),
        password: password,
      );

      final User? user = res.user;

      if (user != null) {
        // 2. profiles テーブルにプロフィール情報を保存
        await supabase.from('profiles').insert({
          'id': user.id,
          'user_id': userId,
          'username': username,
          'birth_date': birthday.replaceAll(' / ', '-'),
        });

        // 【変更点1】成功したら通知ではなく、ニュースのホーム画面へ遷移する
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const NewsHomePage(),
            ),
          );
        }
      }
    } catch (error) {
      // 【変更点2】エラー時は長く表示し、手動で消せる「閉じる」ボタンを追加
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラー: $error'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 10), // 10秒間表示し続ける
            action: SnackBarAction(
              label: '閉じる',
              textColor: Colors.white,
              onPressed: () {
                // ここを押すとSnackBarが即座に消えます
              },
            ),
          ),
        );
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6EDF6),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 30),
          child: Column(
            children: [
              // ============================
              // ヘッダー
              // ============================

              SizedBox(
                height: 50,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Text(
                      'アカウント作成',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () {
                          Navigator.maybePop(context);
                        },
                        icon: const Icon(
                          Icons.chevron_left,
                          size: 28,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ============================
              // プロフィール画像
              // ============================

              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('画像選択機能はあとで実装します'),
                    ),
                  );
                },
                child: Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFCBD5E1),
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                      child: const Icon(
                        Icons.photo_camera_outlined,
                        size: 21,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'プロフィール写真を追加',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                ),
              ),

              const SizedBox(height: 30),

              // ============================
              // 入力フォーム
              // ============================

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    _InputField(
                      label: 'ユーザーID',
                      hint: 'news_user',
                      controller: _userIdController,
                      prefixIcon: Icons.person_outline,
                    ),

                    const SizedBox(height: 14),

                    _InputField(
                      label: 'ユーザー名',
                      hint: '@ username',
                      controller: _usernameController,
                      prefixIcon: Icons.badge_outlined,
                    ),

                    const SizedBox(height: 14),

                    _InputField(
                      label: 'パスワード',
                      hint: '8文字以上の半角英数字',
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscurePassword =
                                !_obscurePassword;
                          });
                        },
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 20,
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    GestureDetector(
                      onTap: _selectBirthday,
                      child: AbsorbPointer(
                        child: _InputField(
                          label: '生年月日',
                          hint: '2000 / 01 / 01',
                          controller: _birthdayController,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ============================
              // 利用規約
              // ============================

              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _agreeTerms,
                      onChanged: (value) {
                        setState(() {
                          _agreeTerms = value ?? false;
                        });
                      },
                    ),
                  ),

                  const SizedBox(width: 8),

                  const Expanded(
                    child: Text(
                      '利用規約とプライバシーポリシーに同意する',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // ============================
              // アカウント作成ボタン
              // ============================

              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed:
                      _agreeTerms ? _createAccount : null,
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF111827),
                    disabledBackgroundColor:
                        const Color(0xFF94A3B8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'アカウントを作成',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // ============================
              // ログインリンク
              // ============================

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'すでにアカウントをお持ちの方はこちら ',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),

                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(),
                        ),
                      );
                    },
                    child: const Text(
                      'ログイン',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// 入力欄共通Widget
// ============================================================

class _InputField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool obscureText;
  final Widget? suffixIcon;
  final IconData? prefixIcon;
  final TextInputType? keyboardType;

  const _InputField({
    required this.label,
    required this.hint,
    required this.controller,
    this.obscureText = false,
    this.suffixIcon,
    this.prefixIcon,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
          ),
        ),

        const SizedBox(height: 6),

        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontSize: 14,
              color: Color(0xFF94A3B8),
            ),
            prefixIcon: prefixIcon != null
                ? Icon(
                    prefixIcon,
                    size: 19,
                    color: const Color(0xFF94A3B8),
                  )
                : null,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFFD6DEE8),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFFD6DEE8),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFF64748B),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Supabase Auth 用の内部識別子です。実在するメールアドレスではありません。
String authEmailFromUserId(String userId) => '$userId@auth.newsapp.local';
