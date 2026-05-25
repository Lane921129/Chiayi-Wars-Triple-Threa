import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/map_cache_service.dart';
import '../theme/theme_provider.dart';
import '../services/auth_service.dart';
import 'map_screen.dart';
import 'missions_screen.dart';
import 'missions_bottom_sheet.dart';
import 'leaderboard_screen.dart';
import 'profile_screen.dart';
import '../widgets/multi_fab.dart';
import 'shop_screen.dart';
import 'performance_screen.dart';
import 'backpack_screen.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'api_key_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  int _currentIndex = 0;
  final GlobalKey<MapScreenState> _mapKey = GlobalKey<MapScreenState>();

  // 即時讀取使用者資料
  Map<String, dynamic> _userData = {
    'faction': 'red',
    'totalScore': 0,
  };

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      MapScreen(key: _mapKey),
      const MissionsScreen(),
      const ShopScreen(),
      const LeaderboardScreen(),
      const ProfileScreen(),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkWifiAndPromptDownload();
    });
  }

  Future<void> _checkWifiAndPromptDownload() async {
    final mapCache = Provider.of<MapCacheService>(context, listen: false);
    
    // 等待統計資訊載入完成
    final stats = await mapCache.getStoreStats();
    final downloadedTiles = stats['count'] as int;
    
    if (downloadedTiles > 0 || mapCache.isDownloading) return;

    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.wifi)) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: FactionColors.darkBg,
          title: const Text('偵測到 Wi-Fi 環境', style: TextStyle(color: Colors.white)),
          content: const Text('為了提供更流暢的地圖體驗，是否要在背景預先下載嘉義市離線地圖？', style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('稍後再說', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                mapCache.startDownload();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('已開始在背景下載離線地圖！')),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: FactionColors.gold),
              child: const Text('開始下載', style: TextStyle(color: Colors.black87)),
            ),
          ],
        ),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('未登入')));
    }

    final themeProvider = Provider.of<ThemeProvider>(context);
    final isSimplified = themeProvider.isSimplifiedMode;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users_public').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.exists) {
          _userData = snapshot.data!.data() as Map<String, dynamic>;
        }

        // 當切換到簡化模式且目前停留在超出索引的頁面時，自動回到「地圖(0)」
        if (isSimplified && _currentIndex > 2) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _currentIndex = 0);
          });
        }

        final faction = _userData['faction'] as String? ?? 'red';
        final factionColor = FactionColors.forFaction(faction);
        final factionGlow = FactionColors.glowForFaction(faction);

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: null,
          drawer: _buildSidebar(isDarkMode, themeProvider),
          body: IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
          floatingActionButton: isSimplified ? _buildMultiFunctionFab() : null,
          bottomNavigationBar: isSimplified 
            ? null 
            : Container(
                decoration: BoxDecoration(
                  color: FactionColors.cardBg,
                  border: Border(
                    top: BorderSide(
                      color: factionColor.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: factionGlow.withValues(alpha: 0.12),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: BottomNavigationBar(
                  currentIndex: _currentIndex,
                  onTap: (idx) => setState(() => _currentIndex = idx),
                  backgroundColor: Colors.transparent,
                  selectedItemColor: factionColor,
                  unselectedItemColor: FactionColors.textSecondary,
                  type: BottomNavigationBarType.fixed,
                  elevation: 0,
                  selectedFontSize: 12,
                  unselectedFontSize: 11,
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.map_outlined),
                      activeIcon: Icon(Icons.map),
                      label: '地圖',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.flag_outlined),
                      activeIcon: Icon(Icons.flag),
                      label: '任務',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.storefront_outlined),
                      activeIcon: Icon(Icons.storefront),
                      label: '商店',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.leaderboard_outlined),
                      activeIcon: Icon(Icons.leaderboard),
                      label: '排行榜',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.person_outline),
                      activeIcon: Icon(Icons.person),
                      label: '我的',
                    ),
                  ],
                ),
              ),
        );
      },
    );
  }

  Widget _buildSidebar(bool isDarkMode, ThemeProvider themeProvider) {
    final factionColor = FactionColors.forFaction(_userData['faction'] ?? 'red');
    
    return Drawer(
      backgroundColor: isDarkMode ? FactionColors.cardBg : Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.black87 : factionColor.withValues(alpha: 0.8),
            ),
            accountName: Text(
              _userData['username'] ?? 'User',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
            ),
            accountEmail: Text(
              '${FactionColors.emojiForFaction(_userData['faction'] ?? 'red')} ${FactionColors.nameForFaction(_userData['faction'] ?? 'red')}',
              style: const TextStyle(color: FactionColors.gold, fontWeight: FontWeight.bold),
            ),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 40, color: Colors.grey),
            ),
          ),
          ListTile(
            leading: Icon(Icons.language, color: isDarkMode ? Colors.white70 : Colors.black87),
            title: Text('語言 (Language)', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87)),
            trailing: DropdownButton<String>(
              value: 'zh_TW',
              dropdownColor: isDarkMode ? FactionColors.cardBg : Colors.white,
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
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
          const Divider(),
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
            child: Text('外觀 (Appearance)', style: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black54, fontSize: 12)),
          ),
          SwitchListTile(
            secondary: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode, color: isDarkMode ? Colors.white70 : Colors.black87),
            title: Text('深色模式', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87)),
            value: themeProvider.themeMode == ThemeMode.dark,
            onChanged: (val) => themeProvider.setThemeMode(val ? ThemeMode.dark : ThemeMode.light),
            activeThumbColor: FactionColors.gold,
          ),
          SwitchListTile(
            secondary: Icon(Icons.dashboard_customize, color: isDarkMode ? Colors.white70 : Colors.black87),
            title: Text('簡潔模式', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87)),
            value: themeProvider.isSimplifiedMode,
            onChanged: (val) => themeProvider.setSimplifiedMode(val),
            activeThumbColor: FactionColors.gold,
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
            child: Text('設定 (Setting)', style: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black54, fontSize: 12)),
          ),
          Consumer<MapCacheService>(
            builder: (context, mapCache, child) {
              return ListTile(
                leading: Icon(Icons.download_for_offline, color: isDarkMode ? Colors.white70 : Colors.black87),
                title: Text('下載嘉義市地圖', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87)),
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
                              style: const TextStyle(fontSize: 12)),
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
          ListTile(
            leading: const Icon(Icons.history, color: FactionColors.gold),
            title: Text('績效與跑圖紀錄', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87)),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PerformanceScreen()));
            },
          ),
          // API Key 設定
          ListTile(
            leading: Icon(Icons.vpn_key, color: isDarkMode ? Colors.white70 : Colors.black87),
            title: Text('API Key 設定', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87)),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ApiKeyScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('登出', style: TextStyle(color: Colors.redAccent)),
            onTap: () async {
              await _authService.signOut();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMultiFunctionFab() {
    final faction = _userData['faction'] as String? ?? 'red';
    final factionColor = FactionColors.forFaction(faction);

    return MultiFab(
      onShop: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => const ShopBottomSheet(),
        );
      },
      onMission: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => const MissionsBottomSheet(),
        );
      },
      onBackpack: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => const BackpackBottomSheet(),
        );
      },
      factionColor: factionColor,
      onToggle: (isOpen) {
        _mapKey.currentState?.setMenuOpen(isOpen);
      },
    );
  }
}
