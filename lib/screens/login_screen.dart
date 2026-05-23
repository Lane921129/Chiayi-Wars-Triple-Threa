import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isLoginMode = true;
  bool _obscurePassword = true;

  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _submitAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnack('請輸入帳號與密碼', isError: true);
      return;
    }
    if (password.length < 6) {
      _showSnack('密碼長度至少需要 6 個字元', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isLoginMode) {
        await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: password);
        if (mounted) _showSnack('⚔️ 歡迎回到諸羅城！');
      } else {
        await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);
        if (mounted) {
          _showSnack('🎉 新血加入陣營！');
          setState(() {
            _isLoginMode = true;
            _passwordController.clear();
          });
        }
      }
    } on FirebaseAuthException catch (e) {
      String msg = '發生錯誤，請稍後再試';
      if (e.code == 'user-not-found') {
        msg = '找不到此帳號，請先註冊';
      } else if (e.code == 'wrong-password') {
        msg = '密碼錯誤，再試一次';
      } else if (e.code == 'email-already-in-use') {
        msg = '這個信箱已被使用';
      } else if (e.code == 'invalid-email') {
        msg = '信箱格式不正確';
      }
      if (mounted) _showSnack(msg, isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    final success = await AuthService().signInWithGoogle();
    if (success) {
      if (mounted) _showSnack('🚀 Google 登入成功！歡迎主公回來！');
    } else {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: FactionColors.cardBg,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(children: [
              Icon(Icons.warning_amber_rounded,
                  color: FactionColors.redGlow, size: 28),
              SizedBox(width: 10),
              Text('登入錯誤',
                  style: TextStyle(
                      color: FactionColors.textPrimary,
                      fontWeight: FontWeight.bold)),
            ]),
            content: const Text('Google 登入失敗或被取消，請再試一次。',
                style: TextStyle(
                    color: FactionColors.textSecondary, fontSize: 13)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('確定',
                      style: TextStyle(color: FactionColors.gold)))
            ],
          ),
        );
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _signInAnonymously() async {
    setState(() => _isLoading = true);
    final success = await AuthService().signInAnonymously();
    if (success) {
      if (mounted) _showSnack('🕵️ 以訪客身分悄悄入城！');
    } else {
      if (mounted) _showSnack('訪客登入失敗，請稍後再試', isError: true);
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? FactionColors.redPrimary : FactionColors.greenDark,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: FactionColors.darkBg,
      body: Stack(
        children: [
          // ── 背景漸層 ──────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.5),
                radius: 1.2,
                colors: [Color(0xFF1A1A3E), FactionColors.darkBg],
              ),
            ),
          ),

          // ── 裝飾圓圈 ──────────────────────────────────────────
          Positioned(
            top: -80,
            left: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  FactionColors.redGlow.withValues(alpha: 0.15),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          Positioned(
            top: 100,
            right: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  FactionColors.blueGlow.withValues(alpha: 0.12),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          Positioned(
            bottom: 50,
            left: size.width / 2 - 100,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  FactionColors.greenGlow.withValues(alpha: 0.10),
                  Colors.transparent,
                ]),
              ),
            ),
          ),

          // ── 主內容 ────────────────────────────────────────────
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const SizedBox(height: 60),

                    // 標誌區域
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: Column(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const RadialGradient(colors: [
                                FactionColors.goldLight,
                                FactionColors.gold,
                              ]),
                              boxShadow: [
                                BoxShadow(
                                  color: FactionColors.gold.withValues(alpha: 0.4),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text('諸', style: TextStyle(
                                fontSize: 52,
                                fontWeight: FontWeight.bold,
                                color: FactionColors.darkBg,
                              )),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '探索諸羅',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: FactionColors.gold,
                              letterSpacing: 8,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '三國爭霸',
                            style: TextStyle(
                              fontSize: 18,
                              color: FactionColors.textSecondary,
                              letterSpacing: 5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // 三陣營 dots
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _FactionDot(color: FactionColors.redGlow, label: '紅'),
                              const SizedBox(width: 16),
                              _FactionDot(color: FactionColors.greenGlow, label: '綠'),
                              const SizedBox(width: 16),
                              _FactionDot(color: FactionColors.blueGlow, label: '藍'),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 48),

                    // ── 登入卡片 ──
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: FactionColors.cardBg,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: FactionColors.gold.withValues(alpha: 0.3),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: FactionColors.gold.withValues(alpha: 0.08),
                            blurRadius: 30,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            _isLoginMode ? '⚔️  登入你的陣營' : '🎖️  加入奇幻旅程',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: FactionColors.textPrimary,
                              letterSpacing: 1,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),

                          // Email
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(color: FactionColors.textPrimary),
                            decoration: const InputDecoration(
                              labelText: '帳號 (Email)',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 密碼
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: const TextStyle(color: FactionColors.textPrimary),
                            decoration: InputDecoration(
                              labelText: '密碼',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: FactionColors.textSecondary,
                                ),
                                onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // 主按鈕
                          SizedBox(
                            height: 54,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _submitAuth,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: FactionColors.gold,
                                foregroundColor: FactionColors.darkBg,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                                elevation: 4,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: FactionColors.darkBg))
                                  : Text(
                                      _isLoginMode ? '登入' : '確認註冊',
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 12),
                          Center(
                            child: TextButton(
                              onPressed: _isLoading
                                  ? null
                                  : () => setState(() {
                                        _isLoginMode = !_isLoginMode;
                                        _passwordController.clear();
                                      }),
                              child: Text(
                                _isLoginMode
                                    ? '還沒加入陣營？點此入伍'
                                    : '已有帳號？返回登入',
                                style: const TextStyle(
                                    color: FactionColors.blueLight,
                                    fontSize: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 分隔線
                    Row(children: [
                      const Expanded(
                          child: Divider(color: FactionColors.divider)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('或', style: TextStyle(
                            color: FactionColors.textSecondary.withValues(alpha: 0.8))),
                      ),
                      const Expanded(
                          child: Divider(color: FactionColors.divider)),
                    ]),

                    const SizedBox(height: 20),

                    // Google 登入
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _signInWithGoogle,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                              color: FactionColors.cardBorder.withValues(alpha: 0.5)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          foregroundColor: FactionColors.textPrimary,
                        ),
                        icon: const Text('G', style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4285F4),
                        )),
                        label: const Text('使用 Google 帳號登入',
                            style: TextStyle(fontSize: 16)),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // 訪客登入
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: TextButton.icon(
                        onPressed: _isLoading ? null : _signInAnonymously,
                        icon: const Icon(Icons.directions_walk,
                            color: FactionColors.textSecondary),
                        label: const Text('以訪客身分體驗',
                            style: TextStyle(
                                color: FactionColors.textSecondary,
                                fontSize: 15)),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 版權
                    const Text(
                      '嘉義大學 · 探索諸羅計畫',
                      style: TextStyle(
                          color: FactionColors.textSecondary,
                          fontSize: 12,
                          letterSpacing: 1),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FactionDot extends StatelessWidget {
  final Color color;
  final String label;
  const _FactionDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 8, spreadRadius: 2)
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }
}