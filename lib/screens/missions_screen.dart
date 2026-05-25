import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';
import 'ai_chat_bottom_sheet.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 任務列表頁面
/// 對應 Firestore missions/{missionId} collection
class MissionsScreen extends StatelessWidget {
  const MissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final textColor = isDarkMode ? FactionColors.textPrimary : Colors.black87;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('勢力任務', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: const MissionsScreenBody(),
    );
  }
}

class MissionsScreenBody extends StatefulWidget {
  const MissionsScreenBody({super.key});

  @override
  State<MissionsScreenBody> createState() => _MissionsScreenBodyState();
}

class _MissionsScreenBodyState extends State<MissionsScreenBody>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'all'; // all / food / heritage / cafe

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {
        switch (_tabController.index) {
          case 0:
            _selectedCategory = 'all';
          case 1:
            _selectedCategory = 'food';
          case 2:
            _selectedCategory = 'heritage';
          case 3:
            _selectedCategory = 'cafe';
        }
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final textColor = isDarkMode ? FactionColors.textPrimary : Colors.black87;
    final textSubColor = isDarkMode ? FactionColors.textSecondary : Colors.black54;
    final cardBgColor = isDarkMode ? FactionColors.cardBg : Colors.white;

    return SafeArea(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('missions').where('status', isEqualTo: 'active').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allDocs = snapshot.data!.docs;
          final allMissions = allDocs.map((d) {
            final data = d.data() as Map<String, dynamic>;
            data['id'] = d.id;
            return data;
          }).toList();

          final filteredMissions = _selectedCategory == 'all'
              ? allMissions
              : allMissions.where((m) => m['category'] == _selectedCategory).toList();

          final completedCount = allMissions.where((m) => m['completed'] == true).length;
          final totalCount = allMissions.length;

          return Column(
            children: [
              // ── 頂部標題 ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '⚔️ 任務中心',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '完成任務 · 累積軍功',
                          style: TextStyle(
                            color: textSubColor,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // 進度圓圈
                    if (totalCount > 0)
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 52,
                            height: 52,
                            child: CircularProgressIndicator(
                              value: completedCount / totalCount,
                              strokeWidth: 4,
                              backgroundColor:
                                  FactionColors.cardBorder,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  FactionColors.gold),
                            ),
                          ),
                          Text(
                            '$completedCount/$totalCount',
                            style: const TextStyle(
                              color: FactionColors.gold,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              // ── 分類 Tabs ──
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: cardBgColor,
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: isDarkMode ? FactionColors.cardBorder : Colors.grey.shade300),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [FactionColors.gold, Color(0xFFFFB300)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: isDarkMode ? FactionColors.darkBg : Colors.white,
                  unselectedLabelColor: textSubColor,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  tabs: const [
                    Tab(text: '全部'),
                    Tab(text: '🍜 美食'),
                    Tab(text: '🏯 古蹟'),
                    Tab(text: '☕ 咖啡'),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ── 任務列表 ──
              Expanded(
                child: ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredMissions.length,
                  itemBuilder: (_, i) =>
                      _buildMissionCard(filteredMissions[i], isDarkMode),
                ),
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _buildMissionCard(Map<String, dynamic> m, bool isDarkMode) {
    final userFaction = 'red'; // 預設使用者為紅軍，日後由 Provider 取得
    final isCompleted = m['completed'] ?? false;
    final missionFaction = m['factionBonus'] ?? 'none';
    final categoryColor = _getCategoryColor(m['category'] as String);

    final cardBgColor = isDarkMode ? FactionColors.cardBg : Colors.white;
    final borderColor = isDarkMode ? FactionColors.cardBorder : Colors.grey.shade300;
    final textPrimary = isDarkMode ? FactionColors.textPrimary : Colors.black87;
    final textSecondary = isDarkMode ? FactionColors.textSecondary : Colors.black54;

    // 同陣營 20% 加成
    final basePoints = m['basePoints'] ?? 100;
    final hasBonus = userFaction == missionFaction;
    final bonusPoints = m['bonusPoints'] ?? (hasBonus ? (basePoints * 0.2).toInt() : 0);
    final bonusColor = FactionColors.forFaction(userFaction);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isCompleted
            ? cardBgColor.withValues(alpha: 0.5)
            : cardBgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isCompleted
              ? borderColor
              : categoryColor.withValues(alpha: 0.35),
          width: isCompleted ? 1 : 1.5,
        ),
        boxShadow: isCompleted
            ? []
            : [
                BoxShadow(
                  color: categoryColor.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _showMissionDetail(m, isDarkMode),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 圖示
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? FactionColors.cardBorder
                        : categoryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      m['imageEmoji'] ?? '📝',
                      style: TextStyle(
                        fontSize: 28,
                        color: isCompleted ? Colors.grey : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // 內容
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              m['name'] ?? '未知任務',
                              style: TextStyle(
                                color: isCompleted
                                    ? textSecondary
                                    : textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                decoration: isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                          if (isCompleted)
                            const Icon(Icons.check_circle,
                                color: FactionColors.greenGlow,
                                size: 20),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        m['description'] ?? '',
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          // 距離
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: FactionColors.cardBorder,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.near_me,
                                    color: FactionColors.textSecondary,
                                    size: 12),
                                const SizedBox(width: 3),
                                Text(
                                  m['distance'] ?? '未知距離',
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // 基礎積分
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: FactionColors.gold.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star,
                                    color: FactionColors.gold,
                                    size: 12),
                                const SizedBox(width: 3),
                                Text(
                                  '+${m['basePoints']}',
                                  style: const TextStyle(
                                    color: FactionColors.gold,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // 陣營加成 (如果同陣營則顯示)
                          if (hasBonus)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: bonusColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${FactionColors.emojiForFaction(userFaction)} 同陣營 +$bonusPoints',
                                style: TextStyle(
                                  color: bonusColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  color: isCompleted
                      ? FactionColors.cardBorder
                      : categoryColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMissionDetail(Map<String, dynamic> m, bool isDarkMode) {
    final userFaction = 'red'; // 預設使用者為紅軍
    final isCompleted = m['completed'] ?? false;
    final missionFaction = m['factionBonus'] ?? 'none';
    final categoryColor = _getCategoryColor(m['category'] ?? '');

    final cardBgColor = isDarkMode ? FactionColors.cardBg : Colors.white;
    final textPrimary = isDarkMode ? FactionColors.textPrimary : Colors.black87;
    final textSecondary = isDarkMode ? FactionColors.textSecondary : Colors.black54;

    // 同陣營 20% 加成
    final basePoints = m['basePoints'] ?? 100;
    final hasBonus = userFaction == missionFaction;
    final bonusPoints = m['bonusPoints'] ?? (hasBonus ? (basePoints * 0.2).toInt() : 0);
    final bonusColor = FactionColors.forFaction(userFaction);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: categoryColor.withValues(alpha: 0.4)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(m['imageEmoji'] ?? '📝',
                  style: const TextStyle(fontSize: 60)),
            ),
            const SizedBox(height: 16),
            Text(
              m['name'] ?? '未知任務',
              style: TextStyle(
                color: textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              m['description'] ?? '',
              style: TextStyle(
                color: textSecondary,
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _DetailChip(
                  icon: Icons.star,
                  label: '基礎 +${m['basePoints']}',
                  color: FactionColors.gold,
                ),
                if (hasBonus) ...[
                  const SizedBox(width: 8),
                  _DetailChip(
                    label: '${FactionColors.emojiForFaction(userFaction)} 同陣營加成 +$bonusPoints',
                    color: bonusColor,
                  ),
                ],
                const SizedBox(width: 8),
                _DetailChip(
                  icon: Icons.near_me,
                  label: m['distance'] ?? '未知距離',
                  color: textSecondary,
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                icon: Icon(isCompleted
                    ? Icons.check_circle
                    : Icons.qr_code_scanner),
                label: Text(
                  isCompleted ? '已完成任務' : '掃描打卡',
                  style: const TextStyle(fontSize: 17),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isCompleted ? FactionColors.cardBorder : categoryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: isCompleted ? 0 : 4,
                ),
                onPressed: isCompleted ? null : () => Navigator.pop(context),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.auto_awesome),
                label: const Text(
                  '詢問 AI 更多歷史故事與提示',
                  style: TextStyle(fontSize: 16),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: FactionColors.gold,
                  side: const BorderSide(color: FactionColors.gold),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  Navigator.pop(context); // Close detail sheet
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) {
                      final title = m['title'] ?? '未知景點';
                      return AiChatBottomSheet(
                        initialPrompt: '請告訴我更多關於「$title」的歷史故事或是過關提示。',
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'food':
        return FactionColors.redPrimary;
      case 'heritage':
        return FactionColors.greenPrimary;
      case 'cafe':
        return FactionColors.bluePrimary;
      default:
        return FactionColors.gold;
    }
  }
}

class _DetailChip extends StatelessWidget {
  final IconData? icon;
  final String label;
  final Color color;

  const _DetailChip({this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
          ],
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
