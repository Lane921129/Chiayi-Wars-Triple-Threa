import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';
import 'route_detail_screen.dart';

class FriendProfileScreen extends StatefulWidget {
  final Map<String, dynamic> friendData;

  const FriendProfileScreen({super.key, required this.friendData});

  @override
  State<FriendProfileScreen> createState() => _FriendProfileScreenState();
}

class _FriendProfileScreenState extends State<FriendProfileScreen> {
  Future<List<Map<String, dynamic>>> _fetchFriendRoutes() async {
    final uid = widget.friendData['uid'];
    if (uid == null || uid.isEmpty) return [];

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('routes')
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      List<Map<String, dynamic>> routes = [];
      for (var doc in snapshot.docs) {
        var data = doc.data();
        data['uid'] = uid;
        data['isMe'] = false;
        data['displayName'] = widget.friendData['displayName'] ?? '好友';
        data['faction'] = widget.friendData['faction'] ?? 'red';
        routes.add(data);
      }
      return routes;
    } catch (e) {
      debugPrint('Error fetching friend routes: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final faction = widget.friendData['faction'] ?? '';
    final factionColor = FactionColors.forFaction(faction);
    final displayName = widget.friendData['displayName'] ?? '好友';
    final score = widget.friendData['totalScore'] ?? 0;
    final avatarUrl = widget.friendData['avatarUrl'] ?? '';

    return Scaffold(
      backgroundColor: isDarkMode ? FactionColors.darkBg : Colors.grey[100],
      appBar: AppBar(
        title: Text('$displayName 的主頁', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: isDarkMode ? FactionColors.darkBg : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: isDarkMode ? Colors.white : Colors.black87),
      ),
      body: Column(
        children: [
          // Profile Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 30),
            color: isDarkMode ? FactionColors.cardBg : Colors.white,
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: factionColor.withValues(alpha: 0.2),
                  backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl.isEmpty
                      ? Text(
                          FactionColors.emojiForFaction(faction),
                          style: const TextStyle(fontSize: 40),
                        )
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  displayName,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? FactionColors.textPrimary : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: factionColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: factionColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    FactionColors.nameForFaction(faction),
                    style: TextStyle(color: factionColor, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star, color: FactionColors.gold, size: 28),
                    const SizedBox(width: 8),
                    Text(
                      '$score 分',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // 各勢力貢獻度
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildFactionScore('red', widget.friendData['redScore'] ?? 0),
                    const SizedBox(width: 16),
                    _buildFactionScore('green', widget.friendData['greenScore'] ?? 0),
                    const SizedBox(width: 16),
                    _buildFactionScore('blue', widget.friendData['blueScore'] ?? 0),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Friend's routes
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchFriendRoutes(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final feed = snapshot.data ?? [];
                if (feed.isEmpty) {
                  return Center(
                    child: Text(
                      '這名好友目前還沒有跑圖紀錄',
                      style: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black54),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: feed.length,
                  itemBuilder: (context, index) {
                    final record = feed[index];
                    final distance = record['distanceMeters'] ?? 0;
                    final duration = record['durationSeconds'] ?? 0;
                    final timestamp = record['timestamp'] as Timestamp?;
                    final dateStr = timestamp != null
                        ? '${timestamp.toDate().month}/${timestamp.toDate().day} ${timestamp.toDate().hour.toString().padLeft(2, '0')}:${timestamp.toDate().minute.toString().padLeft(2, '0')}'
                        : '未知時間';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: isDarkMode ? FactionColors.cardBg : Colors.white,
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => RouteDetailScreen(record: record)));
                        },
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: factionColor.withValues(alpha: 0.2),
                            child: const Icon(Icons.route, color: Colors.grey),
                          ),
                          title: Text(
                            '完成了一趟跑圖',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? FactionColors.textPrimary : Colors.black87,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('距離: ${(distance/1000).toStringAsFixed(2)}km   耗時: ${duration ~/ 60}分${duration % 60}秒', style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87)),
                                Text(dateStr, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                              ],
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFactionScore(String faction, int score) {
    final color = FactionColors.forFaction(faction);
    return Column(
      children: [
        Text(
          FactionColors.emojiForFaction(faction),
          style: const TextStyle(fontSize: 24),
        ),
        const SizedBox(height: 4),
        Text(
          '$score',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
