import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import 'add_store_screen.dart';
import 'add_location_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final user = FirebaseAuth.instance.currentUser;
  int _currentScore = 0;

  @override
  void initState() {
    super.initState();
    _fetchScore();
  }

  void _fetchScore() {
    if (user == null) return;
    FirebaseFirestore.instance
        .collection('users_public')
        .doc(user!.uid)
        .snapshots()
        .listen((doc) {
      if (doc.exists && mounted) {
        setState(() {
          _currentScore = (doc.data() as Map<String, dynamic>)['totalScore'] ?? 0;
        });
      }
    });
  }

  void _showScoreAdjustDialog() {
    final TextEditingController scoreController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('管理員：調整個人積分'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('目前積分：$_currentScore'),
            const SizedBox(height: 10),
            TextField(
              controller: scoreController,
              keyboardType: const TextInputType.numberWithOptions(signed: true),
              decoration: const InputDecoration(
                labelText: '輸入增減數量 (例: 500)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () async {
              final val = int.tryParse(scoreController.text.trim());
              if (val != null && user != null) {
                final newScore = _currentScore + val;
                await FirebaseFirestore.instance
                    .collection('users_public')
                    .doc(user!.uid)
                    .update({'totalScore': newScore < 0 ? 0 : newScore});
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('已更新積分為：${newScore < 0 ? 0 : newScore}')),
                  );
                  Navigator.pop(ctx);
                }
              }
            },
            child: const Text('確認'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    return Scaffold(
      appBar: AppBar(
        title: const Text('管理員快捷看板', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isDarkMode ? FactionColors.darkBg : Colors.white,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 快捷積分調整
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: const CircleAvatar(
                backgroundColor: FactionColors.gold,
                child: Icon(Icons.stars, color: Colors.white),
              ),
              title: const Text('當前帳號積分', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('$_currentScore 積分', style: const TextStyle(color: FactionColors.gold, fontSize: 18, fontWeight: FontWeight.bold)),
              trailing: ElevatedButton(
                onPressed: _showScoreAdjustDialog,
                style: ElevatedButton.styleFrom(backgroundColor: FactionColors.gold),
                child: const Text('調整積分', style: TextStyle(color: Colors.white)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 快捷新增打卡點
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: const CircleAvatar(
                backgroundColor: Colors.blueAccent,
                child: Icon(Icons.add_location, color: Colors.white),
              ),
              title: const Text('新增打卡任務', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('建立新的 GPS/相機打卡點'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AddLocationScreen()));
              },
            ),
          ),
          const SizedBox(height: 16),
          // 快捷新增店家
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: const CircleAvatar(
                backgroundColor: Colors.green,
                child: Icon(Icons.storefront, color: Colors.white),
              ),
              title: const Text('新增合作店家', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('建立地圖上的商店與任務'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AddStoreScreen()));
              },
            ),
          ),
        ],
      ),
    );
  }
}
