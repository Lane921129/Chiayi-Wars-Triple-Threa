import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';
import '../theme/simplified_theme.dart';
import '../services/auth_service.dart';
import 'map_screen.dart';
import 'missions_screen.dart';
import 'leaderboard_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  int _currentIndex = 0;
  bool _isAdmin = false;

  // 即時讀取使用者資料
  Map<String, dynamic> _userData = {
    'faction': 'red',
    'totalScore': 0,
  };

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _checkAdmin();
    _screens = [
      const MapScreen(),
      const MissionsScreen(),
      const LeaderboardScreen(),
      const ProfileScreen(),
    ];
  }

  Future<void> _checkAdmin() async {
    final isAdmin = await _authService.isAdmin();
    if (mounted) setState(() => _isAdmin = isAdmin);
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('未登入')));
    }

    final themeProvider = Provider.of<ThemeProvider>(context);
    final isSimplified = themeProvider.isSimplifiedMode;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users_public').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.exists) {
          _userData = snapshot.data!.data() as Map<String, dynamic>;
        }

        // 當切換到簡化模式且目前停留在「我的(3)」時，自動回到「地圖(0)」
        if (isSimplified && _currentIndex == 3) {
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
          drawer: isSimplified ? _buildSidebar() : null,
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
                      color: factionColor.withOpacity(0.4),
                      width: 1.5,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: factionGlow.withOpacity(0.12),
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

  // 簡化版側邊欄 (Sidebar)
  Widget _buildSidebar() {
    return Drawer(
      backgroundColor: SimplifiedTheme.surface,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: SimplifiedTheme.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 36, color: SimplifiedTheme.primary),
                ),
                const SizedBox(height: 12),
                Text(
                  _userData['displayName'] ?? '探索者',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.map, color: SimplifiedTheme.textPrimary),
            title: const Text('地圖主頁 (Home)', style: TextStyle(color: SimplifiedTheme.textPrimary)),
            onTap: () {
              Navigator.pop(context);
              setState(() => _currentIndex = 0);
            },
          ),
          ListTile(
            leading: const Icon(Icons.storefront, color: SimplifiedTheme.textPrimary),
            title: const Text('兌換商店 (Shop)', style: TextStyle(color: SimplifiedTheme.textPrimary)),
            onTap: () {
              // TODO: Navigate to Shop
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.flag, color: SimplifiedTheme.textPrimary),
            title: const Text('勢力任務 (Mission)', style: TextStyle(color: SimplifiedTheme.textPrimary)),
            onTap: () {
              Navigator.pop(context);
              setState(() => _currentIndex = 1);
            },
          ),
          ListTile(
            leading: const Icon(Icons.language, color: SimplifiedTheme.textPrimary),
            title: const Text('語言切換 (Language)', style: TextStyle(color: SimplifiedTheme.textPrimary)),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.settings, color: SimplifiedTheme.textPrimary),
            title: const Text('設定 (Settings)', style: TextStyle(color: SimplifiedTheme.textPrimary)),
            onTap: () {
              Navigator.pop(context);
              // 將 ProfileScreen 當作設定頁面
              setState(() => _currentIndex = 3);
            },
          ),
          ListTile(
            leading: const Icon(Icons.color_lens_outlined, color: SimplifiedTheme.textPrimary),
            title: const Text('切換至遊戲模式', style: TextStyle(color: SimplifiedTheme.textPrimary)),
            onTap: () {
              Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
              Navigator.pop(context); // close drawer
            },
          ),
        ],
      ),
    );
  }

  // 簡化版多功能欄 (FAB Menu) - 改為中央單一背包
  Widget _buildMultiFunctionFab() {
    return FloatingActionButton(
      onPressed: () {
        // TODO: Open Backpack
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('背包系統建置中...')),
        );
      },
      backgroundColor: SimplifiedTheme.primary,
      elevation: 4,
      child: const Icon(Icons.backpack, color: Colors.white, size: 28),
    );
  }
}
