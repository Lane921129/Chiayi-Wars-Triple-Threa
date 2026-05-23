import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'vouchers_screen.dart';
import 'route_history_screen.dart';
import 'faction_select_screen.dart';

/// 個人頁面
/// 對應 Firestore users_public / users_private / vouchers / route_sessions
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  bool _isAdmin = false;

  // 假資料：users_public + users_private 合併顯示
  final Map<String, dynamic> _userProfile = {
    'displayName': '諸羅探索者',
    'faction': 'red',
    'factionJoinedAt': '2026-05-01',
    'totalScore': 3850,
    'redScore': 2100,
    'greenScore': 980,
    'blueScore': 770,
    'totalRouteDistance': 12450, // 公尺
    'email': 'user@example.com',
    'notificationEnabled': true,
  };

  @override
  void initState() {
    super.initState();
    _checkAdmin();
  }

  Future<void> _checkAdmin() async {
    final isAdmin = await _authService.isAdmin();
    if (mounted) setState(() => _isAdmin = isAdmin);
  }

  String get _faction => _userProfile['faction'] as String;
  Color get _factionColor => FactionColors.forFaction(_faction);
  Color get _factionGlow => FactionColors.glowForFaction(_faction);

  String _formatDistance(int meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '$meters m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FactionColors.darkBg,
      body: CustomScrollView(
        slivers: [
          // ── 個人資料 Header ──
          SliverToBoxAdapter(child: _buildProfileHeader()),

          // ── 積分詳情卡片 ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _buildScoreCard(),
            ),
          ),

          // ── 功能選單 ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildMenuSection(),
            ),
          ),

          // ── 跑圖統計 ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildRouteStats(),
            ),
          ),

          // ── 管理員區域 ──
          if (_isAdmin)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: _buildAdminSection(),
              ),
            ),

          // ── 登出按鈕 ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              child: _buildLogoutButton(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _factionColor.withOpacity(0.3),
            FactionColors.darkBg,
          ],
        ),
      ),
      child: Column(
        children: [
          // 頭像
          Stack(
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _factionColor.withOpacity(0.4),
                      _factionColor.withOpacity(0.1),
                    ],
                  ),
                  border: Border.all(color: _factionColor, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: _factionGlow.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    FactionColors.emojiForFaction(_faction),
                    style: const TextStyle(fontSize: 42),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: FactionColors.cardBg,
                    border: Border.all(color: _factionColor),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.edit,
                        size: 12, color: FactionColors.gold),
                    padding: EdgeInsets.zero,
                    onPressed: () {},
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _userProfile['displayName'] as String,
            style: const TextStyle(
              color: FactionColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          // 陣營徽章
          GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const FactionSelectScreen())),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: _factionColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _factionColor.withOpacity(0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(FactionColors.emojiForFaction(_faction),
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(
                    FactionColors.nameForFaction(_faction),
                    style: TextStyle(
                      color: _factionColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down,
                      color: FactionColors.textSecondary, size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '加入日期：${_userProfile['factionJoinedAt']}',
            style: const TextStyle(
              color: FactionColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: FactionColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _factionColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: _factionGlow.withOpacity(0.08),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('✨ 積分總覽',
                  style: TextStyle(
                    color: FactionColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  )),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: FactionColors.gold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: FactionColors.gold, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      _userProfile['totalScore'].toString(),
                      style: const TextStyle(
                        color: FactionColors.gold,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _FactionScoreBar(
            emoji: '🍜',
            label: '美食紅軍',
            score: _userProfile['redScore'] as int,
            total: _userProfile['totalScore'] as int,
            color: FactionColors.redPrimary,
          ),
          const SizedBox(height: 10),
          _FactionScoreBar(
            emoji: '🏯',
            label: '古蹟綠軍',
            score: _userProfile['greenScore'] as int,
            total: _userProfile['totalScore'] as int,
            color: FactionColors.greenPrimary,
          ),
          const SizedBox(height: 10),
          _FactionScoreBar(
            emoji: '☕',
            label: '咖啡藍軍',
            score: _userProfile['blueScore'] as int,
            total: _userProfile['totalScore'] as int,
            color: FactionColors.bluePrimary,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('🎟️ 我的資源',
            style: TextStyle(
              color: FactionColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            )),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _MenuCard(
                icon: Icons.local_activity_outlined,
                label: '我的優惠券',
                subtitle: '2 張可用',
                color: FactionColors.gold,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const VouchersScreen())),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MenuCard(
                icon: Icons.route_outlined,
                label: '跑圖記錄',
                subtitle: '12.4 km',
                color: FactionColors.blueLight,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const RouteHistoryScreen())),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _MenuCard(
                icon: Icons.history_outlined,
                label: '積分歷史',
                subtitle: '查看流水帳',
                color: FactionColors.greenLight,
                onTap: () {},
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MenuCard(
                icon: Icons.settings_outlined,
                label: '帳號設定',
                subtitle: '通知・隱私',
                color: FactionColors.textSecondary,
                onTap: () {},
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRouteStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: FactionColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: FactionColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🏃 跑圖統計',
              style: TextStyle(
                color: FactionColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              )),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                value: _formatDistance(_userProfile['totalRouteDistance'] as int),
                label: '總距離',
                icon: Icons.route,
                color: FactionColors.blueLight,
              ),
              _StatItem(
                value: '8',
                label: '跑圖次數',
                icon: Icons.flag,
                color: FactionColors.greenLight,
              ),
              _StatItem(
                value: '2',
                label: '今日任務',
                icon: Icons.today,
                color: FactionColors.gold,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdminSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FactionColors.redDark.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FactionColors.redPrimary.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.admin_panel_settings,
                  color: FactionColors.redGlow, size: 20),
              SizedBox(width: 8),
              Text('管理員專區',
                  style: TextStyle(
                    color: FactionColors.redGlow,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  )),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.manage_search, size: 18),
              label: const Text('管理任務與商家'),
              style: ElevatedButton.styleFrom(
                backgroundColor: FactionColors.redPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('管理員後台尚在開發中...'),
                    backgroundColor: FactionColors.redPrimary,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return OutlinedButton.icon(
      icon: const Icon(Icons.logout, color: FactionColors.textSecondary),
      label: const Text('登出陣營',
          style: TextStyle(color: FactionColors.textSecondary, fontSize: 16)),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: FactionColors.cardBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        minimumSize: const Size(double.infinity, 0),
      ),
      onPressed: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: FactionColors.cardBg,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('確認登出',
                style: TextStyle(
                    color: FactionColors.textPrimary,
                    fontWeight: FontWeight.bold)),
            content: const Text('確定要離開諸羅嗎？',
                style: TextStyle(color: FactionColors.textSecondary)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('取消',
                      style: TextStyle(color: FactionColors.textSecondary))),
              TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('登出',
                      style: TextStyle(color: FactionColors.redGlow))),
            ],
          ),
        );
        if (confirm == true) await _authService.signOut();
      },
    );
  }
}

// ── 子元件 ──────────────────────────────────────────────────────

class _FactionScoreBar extends StatelessWidget {
  final String emoji;
  final String label;
  final int score;
  final int total;
  final Color color;

  const _FactionScoreBar({
    required this.emoji,
    required this.label,
    required this.score,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? score / total : 0.0;
    return Row(
      children: [
        Text('$emoji ', style: const TextStyle(fontSize: 14)),
        SizedBox(
          width: 70,
          child: Text(label,
              style: const TextStyle(
                  color: FactionColors.textSecondary, fontSize: 12)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: FactionColors.cardBorder,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          score.toString(),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: FactionColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(
                  color: FactionColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                )),
            Text(subtitle,
                style: TextStyle(color: color, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 26),
        const SizedBox(height: 6),
        Text(value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            )),
        Text(label,
            style: const TextStyle(
              color: FactionColors.textSecondary,
              fontSize: 11,
            )),
      ],
    );
  }
}
