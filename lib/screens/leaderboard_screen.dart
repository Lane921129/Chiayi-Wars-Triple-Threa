import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';

/// 排行榜頁面
/// 對應 Firestore users_public collection（totalScore / redScore / greenScore / blueScore）
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _currentTab = 'total'; // total / red / green / blue

  // 假資料：users_public collection 排行榜資料
  final List<Map<String, dynamic>> _players = [
    {
      'uid': 'u1',
      'displayName': '諸羅大俠',
      'faction': 'red',
      'totalScore': 8520,
      'redScore': 5200,
      'greenScore': 2100,
      'blueScore': 1220,
      'emoji': '🔴',
    },
    {
      'uid': 'u2',
      'displayName': '古蹟守護者',
      'faction': 'green',
      'totalScore': 7830,
      'redScore': 1800,
      'greenScore': 4700,
      'blueScore': 1330,
      'emoji': '🟢',
    },
    {
      'uid': 'u3',
      'displayName': '咖啡旅人',
      'faction': 'blue',
      'totalScore': 7200,
      'redScore': 1200,
      'greenScore': 1900,
      'blueScore': 4100,
      'emoji': '🔵',
    },
    {
      'uid': 'u4',
      'displayName': '在地美食通',
      'faction': 'red',
      'totalScore': 6450,
      'redScore': 4300,
      'greenScore': 1250,
      'blueScore': 900,
      'emoji': '🔴',
    },
    {
      'uid': 'u5',
      'displayName': '嘉義探索者',
      'faction': 'green',
      'totalScore': 5980,
      'redScore': 1100,
      'greenScore': 3880,
      'blueScore': 1000,
      'emoji': '🟢',
    },
    {
      'uid': 'me',
      'displayName': '我（你）',
      'faction': 'red',
      'totalScore': 3850,
      'redScore': 2100,
      'greenScore': 980,
      'blueScore': 770,
      'emoji': '🔴',
    },
  ];

  // 三陣營總積分（faction war 戰況）
  final Map<String, int> _factionTotals = {
    'red': 18520,
    'green': 15430,
    'blue': 12780,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {
        switch (_tabController.index) {
          case 0:
            _currentTab = 'total';
          case 1:
            _currentTab = 'red';
          case 2:
            _currentTab = 'green';
          case 3:
            _currentTab = 'blue';
        }
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _sortedPlayers {
    final sorted = List<Map<String, dynamic>>.from(_players);
    sorted.sort((a, b) {
      final scoreKey = _currentTab == 'total' ? 'totalScore' : '${_currentTab}Score';
      return (b[scoreKey] as int).compareTo(a[scoreKey] as int);
    });
    return sorted;
  }

  int _getScore(Map<String, dynamic> player) {
    final key = _currentTab == 'total' ? 'totalScore' : '${_currentTab}Score';
    return player[key] as int;
  }

  @override
  Widget build(BuildContext context) {
    final sorted = _sortedPlayers;
    final totalFaction = _factionTotals.values.fold(0, (a, b) => a + b);
    
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final textColor = isDarkMode ? FactionColors.textPrimary : Colors.black87;
    final textSubColor = isDarkMode ? FactionColors.textSecondary : Colors.black54;
    final cardBgColor = isDarkMode ? FactionColors.cardBg : Colors.white;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── 頂部標題 ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🏆 天下排行榜',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '三軍征戰 · 爭奪諸羅',
                    style: TextStyle(
                      color: textSubColor,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── 三陣營戰況 Bar ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildFactionWarBar(totalFaction, isDarkMode),
            ),

            const SizedBox(height: 16),

            // ── 分類 Tabs ──
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDarkMode ? FactionColors.cardBorder : Colors.grey.shade300),
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
                  Tab(text: '總積分'),
                  Tab(text: '🔴 紅'),
                  Tab(text: '🟢 綠'),
                  Tab(text: '🔵 藍'),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── 前三名 Podium ──
            if (sorted.length >= 3) _buildPodium(sorted, isDarkMode),

            // ── 排行榜列表 ──
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: sorted.length,
                itemBuilder: (_, i) => _buildPlayerRow(sorted[i], i + 1, isDarkMode),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFactionWarBar(int total, bool isDarkMode) {
    final redPct = _factionTotals['red']! / total;
    final greenPct = _factionTotals['green']! / total;
    final bluePct = _factionTotals['blue']! / total;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? FactionColors.cardBg : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDarkMode ? FactionColors.cardBorder : Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('⚔️ 三國戰況',
                  style: TextStyle(
                    color: isDarkMode ? FactionColors.textPrimary : Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  )),
              Text('實時更新',
                  style: TextStyle(
                    color: isDarkMode ? FactionColors.textSecondary : Colors.black54,
                    fontSize: 11,
                  )),
            ],
          ),
          const SizedBox(height: 12),
          // 進度條
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                Expanded(
                  flex: (redPct * 100).round(),
                  child: Container(
                    height: 14,
                    color: FactionColors.redPrimary,
                  ),
                ),
                Expanded(
                  flex: (greenPct * 100).round(),
                  child: Container(
                    height: 14,
                    color: FactionColors.greenPrimary,
                  ),
                ),
                Expanded(
                  flex: (bluePct * 100).round(),
                  child: Container(
                    height: 14,
                    color: FactionColors.bluePrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _FactionStat(
                emoji: '🍜',
                name: '紅軍',
                score: _factionTotals['red']!,
                color: FactionColors.redPrimary,
                pct: redPct,
              ),
              _FactionStat(
                emoji: '🏯',
                name: '綠軍',
                score: _factionTotals['green']!,
                color: FactionColors.greenPrimary,
                pct: greenPct,
              ),
              _FactionStat(
                emoji: '☕',
                name: '藍軍',
                score: _factionTotals['blue']!,
                color: FactionColors.bluePrimary,
                pct: bluePct,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPodium(List<Map<String, dynamic>> sorted, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd
          Expanded(child: _PodiumSlot(player: sorted[1], rank: 2, score: _getScore(sorted[1]), isDarkMode: isDarkMode)),
          const SizedBox(width: 8),
          // 1st (taller)
          Expanded(child: _PodiumSlot(player: sorted[0], rank: 1, score: _getScore(sorted[0]), isDarkMode: isDarkMode)),
          const SizedBox(width: 8),
          // 3rd
          Expanded(child: _PodiumSlot(player: sorted[2], rank: 3, score: _getScore(sorted[2]), isDarkMode: isDarkMode)),
        ],
      ),
    );
  }

  Widget _buildPlayerRow(Map<String, dynamic> player, int rank, bool isDarkMode) {
    final isMe = player['uid'] == 'me';
    final score = _getScore(player);
    final factionColor = FactionColors.forFaction(player['faction'] as String);

    Color rankColor = FactionColors.textSecondary;
    if (rank == 1) rankColor = FactionColors.gold;
    if (rank == 2) rankColor = const Color(0xFFC0C0C0);
    if (rank == 3) rankColor = const Color(0xFFCD7F32);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isMe
            ? FactionColors.gold.withValues(alpha: 0.08)
            : (isDarkMode ? FactionColors.cardBg : Colors.white),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isMe
              ? FactionColors.gold.withValues(alpha: 0.4)
              : (isDarkMode ? FactionColors.cardBorder : Colors.grey.shade300),
          width: isMe ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // 排名
          SizedBox(
            width: 30,
            child: Text(
              rank <= 3 ? ['🥇', '🥈', '🥉'][rank - 1] : '#$rank',
              style: TextStyle(
                fontSize: rank <= 3 ? 20 : 14,
                color: rankColor,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 12),
          // 陣營標示
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: factionColor.withValues(alpha: 0.15),
              border: Border.all(color: factionColor.withValues(alpha: 0.5)),
            ),
            child: Center(
              child: Text(
                FactionColors.emojiForFaction(player['faction'] as String),
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 名稱
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player['displayName'] as String,
                  style: TextStyle(
                    color: isMe
                        ? FactionColors.gold
                        : (isDarkMode ? FactionColors.textPrimary : Colors.black87),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  FactionColors.nameForFaction(player['faction'] as String),
                  style: TextStyle(
                    color: factionColor,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          // 積分
          Text(
            score.toString().replaceAllMapped(
                RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                (m) => '${m[1]},'),
            style: TextStyle(
              color: isMe ? FactionColors.gold : (isDarkMode ? FactionColors.textPrimary : Colors.black87),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _FactionStat extends StatelessWidget {
  final String emoji;
  final String name;
  final int score;
  final Color color;
  final double pct;

  const _FactionStat({
    required this.emoji,
    required this.name,
    required this.score,
    required this.color,
    required this.pct,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$emoji $name',
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(
          score.toString().replaceAllMapped(
              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},'),
          style: TextStyle(
              color: color, fontSize: 14, fontWeight: FontWeight.bold),
        ),
        Text('${(pct * 100).toStringAsFixed(1)}%',
            style: const TextStyle(
                color: FactionColors.textSecondary, fontSize: 10)),
      ],
    );
  }
}

class _PodiumSlot extends StatelessWidget {
  final Map<String, dynamic> player;
  final int rank;
  final int score;
  final bool isDarkMode;

  const _PodiumSlot(
      {required this.player, required this.rank, required this.score, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    final factionColor = FactionColors.forFaction(player['faction'] as String);
    final heights = {1: 90.0, 2: 68.0, 3: 52.0};
    final height = heights[rank]!;
    final medals = {1: '🥇', 2: '🥈', 3: '🥉'};

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          FactionColors.emojiForFaction(player['faction'] as String),
          style: const TextStyle(fontSize: 28),
        ),
        const SizedBox(height: 4),
        Text(
          player['displayName'] as String,
          style: TextStyle(
            color: isDarkMode ? FactionColors.textPrimary : Colors.black87,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          score.toString().replaceAllMapped(
              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},'),
          style: TextStyle(
            color: factionColor,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                factionColor.withValues(alpha: 0.4),
                factionColor.withValues(alpha: 0.2),
              ],
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
            border: Border.all(color: factionColor.withValues(alpha: 0.4)),
          ),
          child: Center(
            child: Text(
              medals[rank]!,
              style: const TextStyle(fontSize: 28),
            ),
          ),
        ),
      ],
    );
  }
}
