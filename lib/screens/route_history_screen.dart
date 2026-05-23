import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 跑圖記錄頁面
/// 對應 Firestore route_sessions/{sessionId} collection
class RouteHistoryScreen extends StatelessWidget {
  const RouteHistoryScreen({super.key});

  // 假資料：route_sessions collection
  static final List<Map<String, dynamic>> _sessions = [
    {
      'id': 'r1',
      'startTime': '2026-05-18 14:30',
      'endTime': '2026-05-18 16:45',
      'durationSeconds': 8100,
      'totalDistanceMeters': 4230,
      'missionsCompleted': ['嘉義舊監獄', '城隍廟'],
      'pointsEarned': 280,
      'hasLocalFile': true,
    },
    {
      'id': 'r2',
      'startTime': '2026-05-17 09:00',
      'endTime': '2026-05-17 10:30',
      'durationSeconds': 5400,
      'totalDistanceMeters': 2870,
      'missionsCompleted': ['文化路夜市雞肉飯', '噴水圓環'],
      'pointsEarned': 190,
      'hasLocalFile': true,
    },
    {
      'id': 'r3',
      'startTime': '2026-05-15 16:00',
      'endTime': '2026-05-15 18:20',
      'durationSeconds': 8400,
      'totalDistanceMeters': 5350,
      'missionsCompleted': ['阿里山咖啡小棧', '蘭潭咖啡廳', '文創園區'],
      'pointsEarned': 410,
      'hasLocalFile': false, // 本機已刪除
    },
  ];

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}min';
    return '$m 分鐘';
  }

  String _formatDistance(int meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(2)} km';
    }
    return '$meters m';
  }

  @override
  Widget build(BuildContext context) {
    final totalDist = _sessions.fold(
        0, (s, r) => s + (r['totalDistanceMeters'] as int));
    final totalPts =
        _sessions.fold(0, (s, r) => s + (r['pointsEarned'] as int));

    return Scaffold(
      backgroundColor: FactionColors.darkBg,
      appBar: AppBar(
        title: const Text('🏃 跑圖記錄'),
        backgroundColor: FactionColors.cardBg,
        foregroundColor: FactionColors.textPrimary,
        titleTextStyle: const TextStyle(
          color: FactionColors.gold,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: FactionColors.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 總覽卡片
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  FactionColors.blueDark.withValues(alpha: 0.6),
                  FactionColors.cardBg,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: FactionColors.blueLight.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _TotalStat(
                  icon: Icons.route,
                  value: _formatDistance(totalDist),
                  label: '總跑圖距離',
                  color: FactionColors.blueLight,
                ),
                Container(
                    width: 1,
                    height: 50,
                    color: FactionColors.cardBorder),
                _TotalStat(
                  icon: Icons.flag,
                  value: '${_sessions.length}',
                  label: '跑圖次數',
                  color: FactionColors.greenLight,
                ),
                Container(
                    width: 1,
                    height: 50,
                    color: FactionColors.cardBorder),
                _TotalStat(
                  icon: Icons.star,
                  value: '$totalPts',
                  label: '獲得積分',
                  color: FactionColors.gold,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          const Text('跑圖記錄',
              style: TextStyle(
                color: FactionColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              )),
          const SizedBox(height: 10),

          ..._sessions.map((s) => _buildSessionCard(context, s)),

          const SizedBox(height: 8),

          // 說明：GPS 本機儲存機制
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: FactionColors.gold.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: FactionColors.gold.withValues(alpha: 0.2)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline,
                    color: FactionColors.gold, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'GPS 路線座標儲存在您的手機本機，不上傳雲端。\n刪除 App 將同時清除路線記錄。',
                    style: TextStyle(
                      color: FactionColors.textSecondary,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(BuildContext context, Map<String, dynamic> s) {
    final hasLocal = s['hasLocalFile'] as bool;
    final missions = s['missionsCompleted'] as List<String>;
    final pts = s['pointsEarned'] as int;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FactionColors.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: hasLocal
                ? FactionColors.blueLight.withValues(alpha: 0.25)
                : FactionColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 頂部：時間 + 積分
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s['startTime'] as String,
                    style: const TextStyle(
                      color: FactionColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '結束：${s['endTime'] as String}',
                    style: const TextStyle(
                      color: FactionColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: FactionColors.gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star,
                        color: FactionColors.gold, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '+$pts',
                      style: const TextStyle(
                        color: FactionColors.gold,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(color: FactionColors.divider, height: 1),
          const SizedBox(height: 12),

          // 統計
          Row(
            children: [
              _SessionStat(
                icon: Icons.route,
                value: _formatDistance(s['totalDistanceMeters'] as int),
                color: FactionColors.blueLight,
              ),
              const SizedBox(width: 16),
              _SessionStat(
                icon: Icons.timer,
                value: _formatDuration(s['durationSeconds'] as int),
                color: FactionColors.greenLight,
              ),
              const SizedBox(width: 16),
              _SessionStat(
                icon: Icons.flag,
                value: '${missions.length} 任務',
                color: FactionColors.redLight,
              ),
              const Spacer(),
              // 本機檔案狀態
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: hasLocal
                      ? FactionColors.greenDark.withValues(alpha: 0.3)
                      : FactionColors.cardBorder,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      hasLocal ? Icons.phone_android : Icons.no_cell,
                      size: 12,
                      color: hasLocal
                          ? FactionColors.greenGlow
                          : FactionColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      hasLocal ? 'GPS存' : '已刪除',
                      style: TextStyle(
                        color: hasLocal
                            ? FactionColors.greenGlow
                            : FactionColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          // 完成任務標籤
          Wrap(
            spacing: 6,
            children: missions
                .map((m) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: FactionColors.cardBorder,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(m,
                          style: const TextStyle(
                            color: FactionColors.textSecondary,
                            fontSize: 11,
                          )),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _TotalStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _TotalStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 6),
        Text(value,
            style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                color: FactionColors.textSecondary, fontSize: 11)),
      ],
    );
  }
}

class _SessionStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _SessionStat(
      {required this.icon, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Text(value,
            style: TextStyle(
                color: color, fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
