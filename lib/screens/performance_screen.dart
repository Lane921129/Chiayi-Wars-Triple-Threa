import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

class PerformanceScreen extends StatelessWidget {
  const PerformanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: isDarkMode ? FactionColors.cardBg : Colors.white,
          title: Text('績效與跑圖紀錄', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
          iconTheme: IconThemeData(color: textColor),
          bottom: TabBar(
            labelColor: FactionColors.gold,
            unselectedLabelColor: isDarkMode ? Colors.white54 : Colors.black54,
            indicatorColor: FactionColors.gold,
            tabs: const [
              Tab(text: '積分與打卡', icon: Icon(Icons.history)),
              Tab(text: '跑圖軌跡', icon: Icon(Icons.map)),
            ],
          ),
        ),
        body: user == null
            ? const Center(child: Text('請先登入'))
            : TabBarView(
                children: [
                  _buildHistoryTab(user.uid, isDarkMode),
                  _buildRoutesTab(user.uid, isDarkMode),
                ],
              ),
      ),
    );
  }

  Widget _buildHistoryTab(String uid, bool isDarkMode) {
    return StreamBuilder<QuerySnapshot>(
      // 假設我們將打卡/積分記錄存在 users/{uid}/history
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('history')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text('尚無紀錄'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final title = data['title'] ?? '任務完成';
            final points = data['points'] ?? 0;
            final timestamp = data['timestamp'] as Timestamp?;
            final timeStr = timestamp != null
                ? DateFormat('yyyy-MM-dd HH:mm').format(timestamp.toDate())
                : '';

            return Card(
              color: isDarkMode ? FactionColors.cardBg : Colors.white,
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: points > 0 ? Colors.green.withOpacity(0.2) : Colors.blue.withOpacity(0.2),
                  child: Icon(
                    points > 0 ? Icons.add_circle_outline : Icons.location_on,
                    color: points > 0 ? Colors.green : Colors.blue,
                  ),
                ),
                title: Text(title, style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
                subtitle: Text(timeStr, style: const TextStyle(fontSize: 12)),
                trailing: points > 0
                    ? Text('+$points', style: const TextStyle(color: FactionColors.gold, fontWeight: FontWeight.bold, fontSize: 16))
                    : null,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRoutesTab(String uid, bool isDarkMode) {
    return StreamBuilder<QuerySnapshot>(
      // 將跑圖軌跡存在 users/{uid}/routes
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('routes')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text('尚無跑圖軌跡'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final timestamp = data['timestamp'] as Timestamp?;
            final timeStr = timestamp != null
                ? DateFormat('yyyy-MM-dd HH:mm').format(timestamp.toDate())
                : '';
            final durationSeconds = data['durationSeconds'] ?? 0;
            final distanceMeters = data['distanceMeters'] ?? 0;

            final durationStr = '${durationSeconds ~/ 60}分 ${durationSeconds % 60}秒';
            final distanceStr = distanceMeters > 1000 
                ? '${(distanceMeters / 1000).toStringAsFixed(2)} km' 
                : '${distanceMeters.toStringAsFixed(0)} m';

            return Card(
              color: isDarkMode ? FactionColors.cardBg : Colors.white,
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.orangeAccent,
                  child: Icon(Icons.directions_run, color: Colors.white),
                ),
                title: Text('跑圖紀錄 ($timeStr)', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
                subtitle: Text('時間: $durationStr • 距離: $distanceStr'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: 點擊後開啟地圖檢視該軌跡
                },
              ),
            );
          },
        );
      },
    );
  }
}
