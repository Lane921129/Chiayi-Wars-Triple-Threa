import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';

class BackpackBottomSheet extends StatefulWidget {
  const BackpackBottomSheet({super.key});

  @override
  State<BackpackBottomSheet> createState() => _BackpackBottomSheetState();
}

class _BackpackBottomSheetState extends State<BackpackBottomSheet> {
  final List<Map<String, dynamic>> _items = [
    {'name': '加速卷軸', 'icon': '📜', 'count': 3, 'desc': '使用後 30 分鐘內跑圖積分 +50%'},
    {'name': '陣營號角', 'icon': '🎺', 'count': 1, 'desc': '向周圍 1 公里內的同陣營玩家發送集結通知'},
    {'name': '體力藥水', 'icon': '🧪', 'count': 5, 'desc': '立即回復 50 點體力'},
    {'name': '神祕羅盤', 'icon': '🧭', 'count': 2, 'desc': '揭露附近隱藏的特殊任務地點'},
    {'name': '和平鴿', 'icon': '🕊️', 'count': 1, 'desc': '將敵方佔領圈的中立化時間縮短一半'},
  ];

  void _showUseDialog(BuildContext context, Map<String, dynamic> item, int index) {
    int maxCount = item['count'] as int;
    if (maxCount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('該道具數量不足！')),
      );
      return;
    }

    int selectedCount = 1;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isDarkMode = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
            final dialogBg = isDarkMode ? FactionColors.darkBg : Colors.white;
            final textColor = isDarkMode ? Colors.white : Colors.black87;

            return AlertDialog(
              backgroundColor: dialogBg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                '使用 ${item['name']}',
                style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['desc'] as String,
                    style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '持有數量: $maxCount | 選擇使用數量:',
                    style: const TextStyle(color: FactionColors.gold, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: selectedCount > 1
                            ? () => setDialogState(() => selectedCount--)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline, color: FactionColors.gold, size: 28),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          '$selectedCount',
                          style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        onPressed: selectedCount < maxCount
                            ? () => setDialogState(() => selectedCount++)
                            : null,
                        icon: const Icon(Icons.add_circle_outline, color: FactionColors.gold, size: 28),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('取消', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    setState(() {
                      item['count'] = (item['count'] as int) - selectedCount;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('成功使用了 $selectedCount 個 ${item['name']}！')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FactionColors.gold,
                    foregroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('確認使用', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final textColor = isDarkMode ? FactionColors.textPrimary : Colors.black87;
    final cardBgColor = isDarkMode ? FactionColors.cardBg : Colors.white;
    final borderColor = isDarkMode ? FactionColors.cardBorder : Colors.grey.shade300;

    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 頂部拖曳把手
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
                  '🎒 我的背包',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close, color: textColor),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: cardBgColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                      boxShadow: isDarkMode ? [] : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _showUseDialog(context, item, index),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(item['icon'], style: const TextStyle(fontSize: 48)),
                              const SizedBox(height: 12),
                              Text(
                                item['name'],
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '數量: ${item['count']}',
                                style: const TextStyle(
                                  color: FactionColors.gold,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                item['desc'],
                                style: TextStyle(
                                  color: isDarkMode ? Colors.white54 : Colors.black54,
                                  fontSize: 11,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
