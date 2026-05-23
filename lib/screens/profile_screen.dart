import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isSimplified = themeProvider.isSimplifiedMode;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '我的主頁',
                style: TextStyle(
                  color: themeProvider.isDarkMode ? FactionColors.gold : Colors.black87,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              
              // 帳號資訊
              ListTile(
                leading: Icon(Icons.person, color: themeProvider.isDarkMode ? FactionColors.textPrimary : Colors.black87),
                title: Text('帳號', style: TextStyle(color: themeProvider.isDarkMode ? FactionColors.textPrimary : Colors.black87)),
                subtitle: Text(user?.email ?? '訪客', style: TextStyle(color: themeProvider.isDarkMode ? FactionColors.textSecondary : Colors.black54)),
              ),
              const Divider(color: Colors.grey),

              // UI 切換 (遊戲/簡化)
              ListTile(
                leading: Icon(Icons.dashboard_customize, color: themeProvider.isDarkMode ? FactionColors.textPrimary : Colors.black87),
                title: Text('切換介面模式 (目前: ${isSimplified ? "簡化版" : "遊戲版"})', style: TextStyle(color: themeProvider.isDarkMode ? FactionColors.textPrimary : Colors.black87)),
                trailing: Switch(
                  value: isSimplified,
                  activeColor: FactionColors.gold,
                  onChanged: (val) {
                    themeProvider.toggleTheme();
                  },
                ),
              ),
              const Divider(color: Colors.grey),

              // 夜間/明亮模式切換
              ListTile(
                leading: Icon(themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode, color: themeProvider.isDarkMode ? FactionColors.textPrimary : Colors.black87),
                title: Text('外觀模式 (目前: ${themeProvider.isDarkMode ? "夜間" : "明亮"})', style: TextStyle(color: themeProvider.isDarkMode ? FactionColors.textPrimary : Colors.black87)),
                trailing: Switch(
                  value: themeProvider.isDarkMode,
                  activeColor: FactionColors.gold,
                  onChanged: (val) {
                    themeProvider.toggleDarkMode();
                  },
                ),
              ),
              const Divider(color: Colors.grey),

              // 登出按鈕
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.logout, color: Colors.redAccent),
                  label: const Text('登出', style: TextStyle(color: Colors.redAccent, fontSize: 16)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.redAccent),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
