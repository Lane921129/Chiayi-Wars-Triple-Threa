import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
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

  // 使用者假資料（正式版從 Firestore users_public 讀取）
  final String _faction = 'red'; // red / green / blue
  final int _totalScore = 3850;
  final int _redScore = 2100;
  final int _greenScore = 980;
  final int _blueScore = 770;

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
    final factionColor = FactionColors.forFaction(_faction);
    final factionGlow = FactionColors.glowForFaction(_faction);

    return Scaffold(
      backgroundColor: FactionColors.darkBg,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
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
  }
}
