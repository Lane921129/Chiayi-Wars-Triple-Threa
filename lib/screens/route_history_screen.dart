import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../services/friend_service.dart';

/// 跑圖記錄頁面
/// 對應 Firestore route_sessions/{sessionId} collection
class RouteHistoryScreen extends StatefulWidget {
  const RouteHistoryScreen({super.key});

  @override
  State<RouteHistoryScreen> createState() => _RouteHistoryScreenState();
}

class _RouteHistoryScreenState extends State<RouteHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FriendService _friendService = FriendService();
  final String _currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // 格式化時間長度
  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '$h小時 $m分鐘';
    return '$m 分鐘';
  }

  // 格式化距離
  String _formatDistance(int meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(2)} km';
    }
    return '$meters m';
  }

  // 格式化日期時間
  String _formatDateTime(dynamic createdAt) {
    if (createdAt == null) return '未知時間';
    if (createdAt is Timestamp) {
      final date = createdAt.toDate();
      String pad(int n) => n.toString().padLeft(2, '0');
      return '${date.year}-${pad(date.month)}-${pad(date.day)} ${pad(date.hour)}:${pad(date.minute)}';
    }
    return createdAt.toString();
  }

  // ── 我的跑圖紀錄 Stream ──────────────────────────────────────────
  Stream<List<Map<String, dynamic>>> _getMyRouteSessionsStream() {
    if (_currentUid.isEmpty) return Stream.value([]);
    return FirebaseFirestore.instance
        .collection('route_sessions')
        .where('userId', isEqualTo: _currentUid)
        .snapshots()
        .map((snapshot) {
          final sessions = snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'userId': _currentUid,
              'distanceMeters': data['distanceMeters'] ?? data['totalDistanceMeters'] ?? 0,
              'durationSeconds': data['durationSeconds'] ?? 0,
              'pointsEarned': data['pointsEarned'] ?? 0,
              'hasLocalFile': data['hasLocalFile'] ?? false,
              'createdAt': data['createdAt'],
              'missionsCompleted': List<String>.from(data['missionsCompleted'] ?? []),
            };
          }).toList();

          // 依時間排序
          sessions.sort((a, b) {
            final aTime = a['createdAt'] as Timestamp?;
            final bTime = b['createdAt'] as Timestamp?;
            if (aTime == null || bTime == null) return 0;
            return bTime.compareTo(aTime);
          });
          return sessions;
        });
  }

  // ── 好友的跑圖紀錄 Stream ──────────────────────────────────────────
  Stream<List<Map<String, dynamic>>> _getFriendsRouteSessionsStream(List<String> friendUids) {
    if (friendUids.isEmpty) return Stream.value([]);
    return FirebaseFirestore.instance
        .collection('route_sessions')
        .where('userId', whereIn: friendUids)
        .snapshots()
        .asyncMap((snapshot) async {
          List<Map<String, dynamic>> sessions = [];
          for (var doc in snapshot.docs) {
            final data = doc.data();
            final userId = data['userId'] ?? '';

            // 取得好友的公開個人資訊 (名稱、陣營)
            final publicDoc = await FirebaseFirestore.instance.collection('users_public').doc(userId).get();
            final displayName = publicDoc.exists ? (publicDoc.data()?['displayName'] ?? '未知好友') : '未知好友';
            final faction = publicDoc.exists ? (publicDoc.data()?['faction'] ?? '') : '';

            sessions.add({
              'id': doc.id,
              'userId': userId,
              'userName': displayName,
              'userFaction': faction,
              'distanceMeters': data['distanceMeters'] ?? data['totalDistanceMeters'] ?? 0,
              'durationSeconds': data['durationSeconds'] ?? 0,
              'pointsEarned': data['pointsEarned'] ?? 0,
              'hasLocalFile': false, // 好友的路線沒有本機 GPS 檔
              'createdAt': data['createdAt'],
              'missionsCompleted': List<String>.from(data['missionsCompleted'] ?? []),
            });
          }

          // 依時間排序
          sessions.sort((a, b) {
            final aTime = a['createdAt'] as Timestamp?;
            final bTime = b['createdAt'] as Timestamp?;
            if (aTime == null || bTime == null) return 0;
            return bTime.compareTo(aTime);
          });
          return sessions;
        });
  }

  @override
  Widget build(BuildContext context) {
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
          icon: const Icon(Icons.arrow_back_ios_new, color: FactionColors.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: FactionColors.gold,
          labelColor: FactionColors.gold,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: '我的跑圖紀錄'),
            Tab(text: '好友的跑圖紀錄'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyHistoryTab(),
          _buildFriendsHistoryTab(),
        ],
      ),
    );
  }

  // ── 我的跑圖紀錄頁面 ──────────────────────────────────────────────────
  Widget _buildMyHistoryTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _getMyRouteSessionsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final sessions = snapshot.data ?? [];
        final totalDist = sessions.fold(0, (s, r) => s + (r['distanceMeters'] as int));
        final totalPts = sessions.fold(0, (s, r) => s + (r['pointsEarned'] as int));

        return ListView(
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
                border: Border.all(color: FactionColors.blueLight.withValues(alpha: 0.3)),
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
                  Container(width: 1, height: 50, color: FactionColors.cardBorder),
                  _TotalStat(
                    icon: Icons.flag,
                    value: '${sessions.length}',
                    label: '跑圖次數',
                    color: FactionColors.greenLight,
                  ),
                  Container(width: 1, height: 50, color: FactionColors.cardBorder),
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
            const Text(
              '跑圖歷史',
              style: TextStyle(
                color: FactionColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            if (sessions.isEmpty)
              _buildEmptyState('目前尚未上傳任何跑圖紀錄', Icons.directions_run)
            else
              ...sessions.map((s) => _buildSessionCard(s, isFriend: false)),
            const SizedBox(height: 16),
            // 說明：GPS 本機儲存機制
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: FactionColors.gold.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: FactionColors.gold.withValues(alpha: 0.2)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: FactionColors.gold, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'GPS 詳細路線座標儲存在您的手機本機，不上傳雲端以節省頻寬與保護隱私。\n刪除 App 將同時清除詳細的路線地圖軌跡。',
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
        );
      },
    );
  }

  // ── 好友的跑圖紀錄頁面 ──────────────────────────────────────────────────
  Widget _buildFriendsHistoryTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _friendService.getMyFriendsStream(),
      builder: (context, friendsSnapshot) {
        if (friendsSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final friends = friendsSnapshot.data ?? [];
        if (friends.isEmpty) {
          return Center(
            child: _buildEmptyState('您目前沒有好友，快去新增好友吧！', Icons.group_add),
          );
        }

        final friendUids = friends.map((f) => f['uid'] as String).toList();

        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: _getFriendsRouteSessionsStream(friendUids),
          builder: (context, sessionsSnapshot) {
            if (sessionsSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final sessions = sessionsSnapshot.data ?? [];
            if (sessions.isEmpty) {
              return Center(
                child: _buildEmptyState('您的好友目前尚未發布過任何跑圖紀錄', Icons.hourglass_empty),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                return _buildSessionCard(sessions[index], isFriend: true);
              },
            );
          },
        );
      },
    );
  }

  // ── 畫空值畫面 ──────────────────────────────────────────────────────
  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Colors.white30),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: FactionColors.textSecondary, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── 單一跑圖紀錄卡片 ──────────────────────────────────────────────────
  Widget _buildSessionCard(Map<String, dynamic> s, {required bool isFriend}) {
    final hasLocal = s['hasLocalFile'] as bool;
    final missions = s['missionsCompleted'] as List<String>;
    final pts = s['pointsEarned'] as int;
    final dist = s['distanceMeters'] as int;
    final duration = s['durationSeconds'] as int;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FactionColors.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isFriend
              ? FactionColors.forFaction(s['userFaction'] ?? '').withValues(alpha: 0.25)
              : (hasLocal
                  ? FactionColors.blueLight.withValues(alpha: 0.25)
                  : FactionColors.cardBorder),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 好友跑圖紀錄時，在最上方標明好友資訊
          if (isFriend) ...[
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: FactionColors.forFaction(s['userFaction'] ?? '').withValues(alpha: 0.2),
                  child: Text(
                    FactionColors.emojiForFaction(s['userFaction'] ?? ''),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  s['userName'] ?? '好友',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: FactionColors.forFaction(s['userFaction'] ?? ''),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '的跑圖紀錄',
                  style: TextStyle(
                    color: FactionColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(color: FactionColors.divider, height: 1),
            const SizedBox(height: 10),
          ],

          // 頂部：時間 + 積分
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatDateTime(s['createdAt']),
                    style: const TextStyle(
                      color: FactionColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    '記錄 ID: ${s['id'].substring(0, 8)}...',
                    style: const TextStyle(
                      color: FactionColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: FactionColors.gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: FactionColors.gold, size: 16),
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
                value: _formatDistance(dist),
                color: FactionColors.blueLight,
              ),
              const SizedBox(width: 16),
              _SessionStat(
                icon: Icons.timer,
                value: _formatDuration(duration),
                color: FactionColors.greenLight,
              ),
              const SizedBox(width: 16),
              _SessionStat(
                icon: Icons.flag,
                value: '${missions.length} 任務',
                color: FactionColors.redLight,
              ),
              if (!isFriend) ...[
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
                        color: hasLocal ? FactionColors.greenGlow : FactionColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        hasLocal ? 'GPS存' : '已刪除',
                        style: TextStyle(
                          color: hasLocal ? FactionColors.greenGlow : FactionColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),

          if (missions.isNotEmpty) ...[
            const SizedBox(height: 10),
            // 完成任務標籤
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: missions
                  .map((m) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: FactionColors.cardBorder,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          m,
                          style: const TextStyle(
                            color: FactionColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
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
        Text(
          value,
          style: TextStyle(color: color, fontSize: 17, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: FactionColors.textSecondary, fontSize: 11),
        ),
      ],
    );
  }
}

class _SessionStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _SessionStat({
    required this.icon,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
