import 'package:firebase_auth/firebase_auth.dart';
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
import 'mission_center_screen.dart';
import 'profile_screen.dart';
import '../widgets/multi_fab.dart';
import 'shop_screen.dart';
import 'performance_screen.dart';
import 'backpack_screen.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'api_key_screen.dart';
import 'friends_screen.dart';

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
  
  Stream<DocumentSnapshot>? _userStream;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    final user = _authService.currentUser;
    if (user != null) {
      _userStream = FirebaseFirestore.instance.collection('users_public').doc(user.uid).snapshots();
      // 確保舊用戶的信箱也能被搜尋到 (自動修補資料)
      FirebaseFirestore.instance.collection('users_public').doc(user.uid).set(
        {'searchableEmail': user.email ?? ''},
        SetOptions(merge: true)
      );
    }
    _screens = [
      MapScreen(key: _mapKey),
      const FriendsScreen(),
      const ShopScreen(),
      const MissionCenterScreen(),
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
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await mapCache.startDownload();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('已開始在背景下載離線地圖！')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('下載失敗：$e')));
                  }
                }
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
    if (user == null || _userStream == null) {
      return const Scaffold(body: Center(child: Text('未登入')));
    }

    final themeProvider = Provider.of<ThemeProvider>(context);
    final isSimplified = themeProvider.isSimplifiedMode;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<DocumentSnapshot>(
      stream: _userStream,
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
                      icon: Icon(Icons.people_outline),
                      activeIcon: Icon(Icons.people),
                      label: '社群好友',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.storefront_outlined),
                      activeIcon: Icon(Icons.storefront),
                      label: '商店',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.flag_outlined),
                      activeIcon: Icon(Icons.flag),
                      label: '任務中心',
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
          GestureDetector(
            onTap: () => _showEditProfileDialog(context, _authService.currentUser, isDarkMode),
            child: UserAccountsDrawerHeader(
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.black87 : factionColor.withValues(alpha: 0.8),
              ),
              accountName: Text(
                '${_userData['displayName'] ?? _userData['username'] ?? 'User'} (點擊編輯)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
              ),
              accountEmail: Text(
                '${FactionColors.emojiForFaction(_userData['faction'] ?? 'red')} ${FactionColors.nameForFaction(_userData['faction'] ?? 'red')}',
                style: const TextStyle(color: FactionColors.gold, fontWeight: FontWeight.bold),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage: _userData['avatarUrl'] != null && _userData['avatarUrl'].toString().isNotEmpty
                    ? NetworkImage(_userData['avatarUrl'])
                    : null,
                child: _userData['avatarUrl'] == null || _userData['avatarUrl'].toString().isEmpty
                    ? const Icon(Icons.person, size: 40, color: Colors.grey)
                    : null,
              ),
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
          ListTile(
            leading: Icon(Icons.people, color: isDarkMode ? Colors.white70 : Colors.black87),
            title: Text('社群好友', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87)),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const FriendsScreen()));
            },
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

  void _showEditProfileDialog(BuildContext context, User? user, bool isDarkMode) {
    if (user == null) return;
    
    showDialog(
      context: context,
      builder: (ctx) {
        final nameController = TextEditingController();
        final avatarController = TextEditingController();

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users_public').doc(user.uid).get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AlertDialog(
                backgroundColor: Colors.transparent,
                elevation: 0,
                content: Center(child: CircularProgressIndicator()),
              );
            }
            final data = snapshot.data?.data() as Map<String, dynamic>?;
            if (nameController.text.isEmpty && avatarController.text.isEmpty) {
              nameController.text = data?['displayName'] ?? '';
              avatarController.text = data?['avatarUrl'] ?? '';
            }

            return AlertDialog(
              backgroundColor: isDarkMode ? FactionColors.cardBg : Colors.white,
              title: Text('編輯個人檔案', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
                      decoration: InputDecoration(
                        labelText: '顯示名稱',
                        labelStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: avatarController,
                      style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
                      decoration: InputDecoration(
                        labelText: '照片 URL',
                        labelStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('UID', style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87)),
                      subtitle: Text(user.uid, style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.white54 : Colors.grey)),
                      trailing: IconButton(
                        icon: const Icon(Icons.copy, color: Colors.blueAccent),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: user.uid));
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已複製 UID')));
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('取消', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await FirebaseFirestore.instance.collection('users_public').doc(user.uid).update({
                      'displayName': nameController.text.trim(),
                      'avatarUrl': avatarController.text.trim(),
                    });
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已儲存變更')));
                      Navigator.pop(ctx);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: FactionColors.gold),
                  child: const Text('儲存', style: TextStyle(color: Colors.black87)),
                ),
              ],
            );
          }
        );
      }
    );
  }
}
