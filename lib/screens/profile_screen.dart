import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';
import '../services/map_cache_service.dart';
import 'performance_screen.dart';
import 'api_key_screen.dart';
import '../services/seed_service.dart';
import '../services/auth_service.dart';
import 'admin_panel_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isSimplified = themeProvider.isSimplifiedMode;
    final isDarkMode = themeProvider.isDarkMode;
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
                  color: isDarkMode ? FactionColors.gold : Colors.black87,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  children: [
                    // 帳號資訊
                    ListTile(
                      leading: Icon(Icons.person, color: isDarkMode ? FactionColors.textPrimary : Colors.black87),
                      title: Text('帳號', style: TextStyle(color: isDarkMode ? FactionColors.textPrimary : Colors.black87)),
                      subtitle: Text(user?.email ?? '訪客', style: TextStyle(color: isDarkMode ? FactionColors.textSecondary : Colors.black54)),
                    ),
                    const Divider(color: Colors.grey),

                    // 語言設定
                    ListTile(
                      leading: Icon(Icons.language, color: isDarkMode ? FactionColors.textPrimary : Colors.black87),
                      title: Text('語言 (Language)', style: TextStyle(color: isDarkMode ? FactionColors.textPrimary : Colors.black87)),
                      trailing: DropdownButton<String>(
                        value: 'zh_TW',
                        dropdownColor: isDarkMode ? FactionColors.cardBg : Colors.white,
                        style: TextStyle(color: isDarkMode ? FactionColors.textPrimary : Colors.black87),
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(value: 'zh_TW', child: Text('繁體中文')),
                          DropdownMenuItem(value: 'en', child: Text('English')),
                        ],
                        onChanged: (val) {
                          // TODO: 實作語系切換
                        },
                      ),
                    ),
                    const Divider(color: Colors.grey),

                    // UI 切換 (遊戲/簡化)
                    ListTile(
                      leading: Icon(Icons.dashboard_customize, color: isDarkMode ? FactionColors.textPrimary : Colors.black87),
                      title: Text('簡潔模式', style: TextStyle(color: isDarkMode ? FactionColors.textPrimary : Colors.black87)),
                      trailing: Switch(
                        value: isSimplified,
                        activeThumbColor: FactionColors.gold,
                        onChanged: (val) {
                          themeProvider.setSimplifiedMode(val);
                        },
                      ),
                    ),
                    
                    // 夜間/明亮模式切換
                    ListTile(
                      leading: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode, color: isDarkMode ? FactionColors.textPrimary : Colors.black87),
                      title: Text('深色模式', style: TextStyle(color: isDarkMode ? FactionColors.textPrimary : Colors.black87)),
                      trailing: Switch(
                        value: isDarkMode,
                        activeThumbColor: FactionColors.gold,
                        onChanged: (val) {
                          themeProvider.setThemeMode(val ? ThemeMode.dark : ThemeMode.light);
                        },
                      ),
                    ),
                    const Divider(color: Colors.grey),

                    // 地圖下載與快取
                    Consumer<MapCacheService>(
                      builder: (context, mapCache, child) {
                        return ListTile(
                          leading: Icon(Icons.download_for_offline, color: isDarkMode ? Colors.white70 : Colors.black87),
                          title: Text('下載嘉義市地圖', style: TextStyle(color: isDarkMode ? FactionColors.textPrimary : Colors.black87)),
                          subtitle: mapCache.isDownloading
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    LinearProgressIndicator(
                                      value: mapCache.downloadProgress,
                                      backgroundColor: Colors.grey.withValues(alpha: 0.3),
                                      color: FactionColors.gold,
                                    ),
                                    const SizedBox(height: 4),
                                    Text('${mapCache.downloadedTiles} / ${mapCache.totalTilesToDownload} Tiles', 
                                        style: TextStyle(fontSize: 12, color: isDarkMode ? FactionColors.textSecondary : Colors.black54)),
                                  ],
                                )
                              : Text('目前已快取: ${mapCache.downloadedTiles > 0 ? mapCache.downloadedTiles : "未知"} 瓦片', 
                                  style: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black54, fontSize: 12)),
                          trailing: mapCache.isDownloading 
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                      onPressed: () => mapCache.clearCache(),
                                      tooltip: '清除快取',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.cloud_download, color: FactionColors.gold),
                                      onPressed: () => mapCache.startDownload(),
                                      tooltip: '開始下載',
                                    ),
                                  ],
                                ),
                        );
                      },
                    ),
                    // 管理員與開發專區 (需驗證權限)
                    FutureBuilder<bool>(
                      future: AuthService().isAdmin(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const SizedBox.shrink();
                        }
                        final isAdmin = snapshot.data ?? false;
                        if (!isAdmin) return const SizedBox.shrink();

                        return Column(
                          children: [
                            const Divider(color: Colors.grey),
                            ListTile(
                              leading: const Icon(Icons.admin_panel_settings, color: Colors.deepPurpleAccent),
                              title: const Text('管理員專區', style: TextStyle(color: Colors.deepPurpleAccent, fontWeight: FontWeight.bold)),
                              trailing: const Icon(Icons.chevron_right, color: Colors.deepPurpleAccent),
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPanelScreen()));
                              },
                            ),
                            ListTile(
                              leading: Icon(Icons.developer_mode, color: isDarkMode ? FactionColors.textPrimary : Colors.black87),
                              title: Text('開發人員模式', style: TextStyle(color: isDarkMode ? FactionColors.textPrimary : Colors.black87)),
                              trailing: Switch(
                                value: themeProvider.isDeveloperMode,
                                activeThumbColor: Colors.greenAccent,
                                onChanged: (val) {
                                  themeProvider.setDeveloperMode(val);
                                },
                              ),
                            ),
                            if (themeProvider.isDeveloperMode)
                              ListTile(
                                leading: const Icon(Icons.data_array, color: Colors.greenAccent),
                                title: const Text('上傳測試資料 (種子)', style: TextStyle(color: Colors.greenAccent)),
                                onTap: () async {
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (ctx) {
                                      String currentMsg = '準備中...';
                                      return StatefulBuilder(
                                        builder: (context, setState) {
                                          // Start the seed process only once
                                          if (currentMsg == '準備中...') {
                                            SeedService.seedLocationsAndMissions(
                                              onProgress: (msg) {
                                                if (!context.mounted) return;
                                                setState(() {
                                                  currentMsg = msg;
                                                });
                                              },
                                            ).then((_) {
                                              if (!context.mounted) return;
                                              Navigator.pop(context); // Close dialog
                                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ 測試資料上傳成功！請重啟APP或查看地圖')));
                                            }).catchError((e) {
                                              if (!context.mounted) return;
                                              Navigator.pop(context); // Close dialog
                                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ 錯誤: $e')));
                                            });
                                          }
                                          return AlertDialog(
                                            title: const Text('上傳測試資料'),
                                            content: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const CircularProgressIndicator(),
                                                const SizedBox(height: 16),
                                                Text(currentMsg, textAlign: TextAlign.center),
                                              ],
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  );
                                },
                              ),
                            const Divider(color: Colors.grey),
                          ],
                        );
                      },
                    ),

                    // 績效與跑圖紀錄
                    ListTile(
                      leading: const Icon(Icons.history, color: FactionColors.gold),
                      title: Text('績效與跑圖紀錄', style: TextStyle(color: isDarkMode ? FactionColors.textPrimary : Colors.black87)),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const PerformanceScreen()));
                      },
                    ),

                    // API Key 設定
                    ListTile(
                      leading: Icon(Icons.vpn_key, color: isDarkMode ? Colors.white70 : Colors.black87),
                      title: Text('API Key 設定', style: TextStyle(color: isDarkMode ? FactionColors.textPrimary : Colors.black87)),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ApiKeyScreen()));
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // 登出按鈕
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
