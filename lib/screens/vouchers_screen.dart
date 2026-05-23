import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 優惠券頁面
/// 對應 Firestore vouchers/{voucherId} collection
class VouchersScreen extends StatelessWidget {
  const VouchersScreen({super.key});

  // 假資料：vouchers collection
  static final List<Map<String, dynamic>> _vouchers = [
    {
      'id': 'v1',
      'storeName': '阿里山咖啡小棧',
      'storeEmoji': '☕',
      'discountDescription': '消費滿 200 元享 9 折優惠',
      'isRedeemed': false,
      'createdAt': '2026-05-15',
      'expiresAt': '2026-06-15',
      'faction': 'blue',
    },
    {
      'id': 'v2',
      'storeName': '文化路夜市美食攤',
      'storeEmoji': '🍜',
      'discountDescription': '雞肉飯買一送一',
      'isRedeemed': false,
      'createdAt': '2026-05-18',
      'expiresAt': '2026-05-25',
      'faction': 'red',
    },
    {
      'id': 'v3',
      'storeName': '嘉義舊監獄紀念館',
      'storeEmoji': '🏛️',
      'discountDescription': '門票 8 折',
      'isRedeemed': true,
      'createdAt': '2026-05-10',
      'expiresAt': '2026-05-20',
      'redeemedAt': '2026-05-12',
      'faction': 'green',
    },
    {
      'id': 'v4',
      'storeName': '蘭潭咖啡廳',
      'storeEmoji': '🌅',
      'discountDescription': '下午茶套餐 85 折',
      'isRedeemed': true,
      'createdAt': '2026-05-05',
      'expiresAt': '2026-05-19',
      'redeemedAt': '2026-05-17',
      'faction': 'blue',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final available = _vouchers.where((v) => !(v['isRedeemed'] as bool)).toList();
    final used = _vouchers.where((v) => v['isRedeemed'] as bool).toList();

    return Scaffold(
      backgroundColor: FactionColors.darkBg,
      appBar: AppBar(
        title: const Text('🎟️ 我的優惠券'),
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
          // 可用優惠券
          _SectionHeader(
            title: '✅ 可使用',
            count: available.length,
            color: FactionColors.greenGlow,
          ),
          const SizedBox(height: 8),
          ...available.map((v) => _buildVoucherCard(context, v)),

          const SizedBox(height: 16),

          // 已使用
          _SectionHeader(
            title: '🔒 已使用',
            count: used.length,
            color: FactionColors.textSecondary,
          ),
          const SizedBox(height: 8),
          ...used.map((v) => _buildVoucherCard(context, v)),
        ],
      ),
    );
  }

  Widget _buildVoucherCard(BuildContext context, Map<String, dynamic> v) {
    final isRedeemed = v['isRedeemed'] as bool;
    final factionColor = FactionColors.forFaction(v['faction'] as String);
    final factionGlow = FactionColors.glowForFaction(v['faction'] as String);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isRedeemed
            ? FactionColors.cardBg.withValues(alpha: 0.5)
            : FactionColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isRedeemed
              ? FactionColors.cardBorder
              : factionColor.withValues(alpha: 0.5),
          width: isRedeemed ? 1 : 1.5,
        ),
        boxShadow: isRedeemed
            ? []
            : [
                BoxShadow(
                  color: factionGlow.withValues(alpha: 0.08),
                  blurRadius: 16,
                ),
              ],
      ),
      child: Stack(
        children: [
          // 左側色條
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 6,
              decoration: BoxDecoration(
                color: isRedeemed
                    ? FactionColors.cardBorder
                    : factionColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
              ),
            ),
          ),
          // 內容
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
            child: Row(
              children: [
                // Emoji
                Text(
                  v['storeEmoji'] as String,
                  style: TextStyle(
                    fontSize: 40,
                    color: isRedeemed ? Colors.grey : null,
                  ),
                ),
                const SizedBox(width: 14),
                // 文字內容
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        v['storeName'] as String,
                        style: TextStyle(
                          color: isRedeemed
                              ? FactionColors.textSecondary
                              : FactionColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        v['discountDescription'] as String,
                        style: TextStyle(
                          color: isRedeemed
                              ? FactionColors.textSecondary.withValues(alpha: 0.6)
                              : factionColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isRedeemed
                            ? '已核銷：${v['redeemedAt']}'
                            : '有效期：${v['expiresAt']}',
                        style: TextStyle(
                          color: isRedeemed
                              ? FactionColors.textSecondary.withValues(alpha: 0.5)
                              : FactionColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                // 右側按鈕
                if (!isRedeemed)
                  GestureDetector(
                    onTap: () => _showRedeemDialog(context, v),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: FactionColors.gradientForFaction(
                              v['faction'] as String),
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        '使用',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  )
                else
                  const Icon(Icons.lock, color: FactionColors.textSecondary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showRedeemDialog(BuildContext context, Map<String, dynamic> v) {
    final factionColor = FactionColors.forFaction(v['faction'] as String);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: FactionColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Text(v['storeEmoji'] as String, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 10),
            const Flexible(
              child: Text('確認使用優惠券',
                  style: TextStyle(
                      color: FactionColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(v['storeName'] as String,
                style: const TextStyle(
                    color: FactionColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: factionColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: factionColor.withValues(alpha: 0.3)),
              ),
              child: Text(v['discountDescription'] as String,
                  style: TextStyle(
                      color: factionColor,
                      fontSize: 15,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            const Text(
              '請將此畫面出示給店家掃描核銷\n使用後無法復原，確定要使用嗎？',
              style: TextStyle(color: FactionColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消',
                  style: TextStyle(color: FactionColors.textSecondary))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: factionColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              // TODO: 更新 Firestore voucher.isRedeemed = true
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('優惠券已核銷！謝謝光臨～'),
                  backgroundColor: FactionColors.greenDark,
                ),
              );
            },
            child: const Text('確認核銷'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color color;

  const _SectionHeader({
    required this.title,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            )),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text('$count',
              style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
