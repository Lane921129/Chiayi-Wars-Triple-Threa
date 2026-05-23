import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';
import '../services/map_cache_service.dart';
import 'performance_screen.dart';
import 'api_key_screen.dart';
import '../services/seed_service.dart';

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
                    // 開發人員模式
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

                    // 測試資料上傳 (僅開發人員模式可見)
                    if (themeProvider.isDeveloperMode)
                      ListTile(
                        leading: const Icon(Icons.data_array, color: Colors.greenAccent),
                        title: const Text('上傳測試資料 (種子)', style: TextStyle(color: Colors.greenAccent)),
                        onTap: () async {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('正在上傳測試資料...')));
                          await SeedService.seedMissions();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('測試資料上傳成功！請查看地圖圖層變化')));
                        },
                      ),

                    const Divider(color: Colors.grey),

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
