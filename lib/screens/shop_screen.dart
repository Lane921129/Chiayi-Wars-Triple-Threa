import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';

class ShopBottomSheet extends StatefulWidget {
  const ShopBottomSheet({super.key});

  @override
  State<ShopBottomSheet> createState() => _ShopBottomSheetState();
}

class _ShopBottomSheetState extends State<ShopBottomSheet> {
  final user = FirebaseAuth.instance.currentUser;

  Future<void> _buyItem(Map<String, dynamic> item, int userPoints) async {
    if (user == null) return;
    int price = item['price'];

    if (userPoints < price) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('積分不足！')),
      );
      return;
    }

    try {
      // 扣除積分並新增至背包
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final userRef = FirebaseFirestore.instance.collection('users_public').doc(user!.uid);
        final userSnapshot = await transaction.get(userRef);

        if (!userSnapshot.exists) return;
        
        int currentPoints = userSnapshot.data()?['score'] ?? 0;
        if (currentPoints < price) throw Exception('積分不足');

        transaction.update(userRef, {'score': currentPoints - price});

        final inventoryRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('inventory')
            .doc();

        transaction.set(inventoryRef, {
          'itemType': item['type'],
          'name': item['name'],
          'quantity': 1,
          'obtainedFrom': 'shop',
          'obtainedAt': FieldValue.serverTimestamp(),
          'activeUntil': null, // 尚未啟用
        });
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('成功兌換：${item['name']}！')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('兌換失敗：$e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.white24 : Colors.black26,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Text(
                  '🎁 兌換商店',
                  style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (user != null)
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance.collection('users_public').doc(user!.uid).snapshots(),
                    builder: (context, snapshot) {
                      int points = 0;
                      if (snapshot.hasData && snapshot.data!.data() != null) {
                        points = (snapshot.data!.data() as Map<String, dynamic>)['score'] ?? 0;
                      }
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: FactionColors.gold.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: FactionColors.gold),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.stars, color: FactionColors.gold, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '$points',
                              style: const TextStyle(color: FactionColors.gold, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                IconButton(
                  icon: Icon(Icons.close, color: textColor),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('shop_items').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final items = snapshot.data?.docs ?? [];
                
                // 如果商店沒有資料，提供預設商品
                final displayItems = items.isEmpty ? [
                  {'name': '積分加速器', 'description': '使用後 30 分鐘內積分獲得量 +50%', 'price': 500, 'icon': '⚡', 'type': 'boost_score'},
                  {'name': '同陣營雙倍卡', 'description': '下次完成同陣營任務時積分雙倍', 'price': 800, 'icon': '🔥', 'type': 'double_faction'},
                  {'name': '隨機積分福袋', 'description': '開啟獲得 100~1000 隨機積分', 'price': 300, 'icon': '🎁', 'type': 'random_bonus'},
                  {'name': '店家折價券', 'description': '合作咖啡廳 9 折優惠券', 'price': 1500, 'icon': '☕', 'type': 'coupon'},
                ] : items.map((doc) => doc.data() as Map<String, dynamic>).toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: displayItems.length,
                  itemBuilder: (context, index) {
                    final item = displayItems[index];
                    return Card(
                      color: isDarkMode ? FactionColors.cardBg : Colors.white,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: isDarkMode ? Colors.white12 : Colors.black12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: FactionColors.gold.withOpacity(0.2),
                          child: Text(item['icon'] ?? '🛍️', style: const TextStyle(fontSize: 20)),
                        ),
                        title: Text(item['name'], style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          item['description'],
                          style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54, fontSize: 12),
                        ),
                        trailing: StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance.collection('users_public').doc(user?.uid).snapshots(),
                          builder: (context, userSnap) {
                            int userPoints = 0;
                            if (userSnap.hasData && userSnap.data!.data() != null) {
                              userPoints = (userSnap.data!.data() as Map<String, dynamic>)['score'] ?? 0;
                            }
                            final canAfford = userPoints >= (item['price'] as int);
                            return ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: canAfford ? FactionColors.gold : Colors.grey,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                              onPressed: canAfford ? () => _buyItem(item, userPoints) : null,
                              child: Text('${item['price']} 積分', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            );
                          }
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
}
