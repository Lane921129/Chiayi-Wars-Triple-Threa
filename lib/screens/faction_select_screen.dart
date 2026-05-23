import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

/// 陣營選擇頁面
/// 寫入 Firestore users_public/{userId}.faction
class FactionSelectScreen extends StatefulWidget {
  const FactionSelectScreen({super.key});

  @override
  State<FactionSelectScreen> createState() => _FactionSelectScreenState();
}

class _FactionSelectScreenState extends State<FactionSelectScreen>
    with TickerProviderStateMixin {
  String? _selectedFaction;
  late AnimationController _glowController;

  final List<Map<String, dynamic>> _factions = [
    {
      'id': 'red',
      'name': '美食紅軍',
      'subtitle': '諸羅美食征服者',
      'emoji': '🍜',
      'color': FactionColors.redPrimary,
      'glow': FactionColors.redGlow,
      'gradient': [FactionColors.redDark, FactionColors.redPrimary],
      'description': '走遍嘉義大街小巷，\n探索每一份道地美味，\n讓美食成為你的武器！',
      'bonus': '完成美食任務 +40 bonus pts',
      'missions': ['噴水圓環雞肉飯', '文化路夜市', '蒜頭蔗埕文化園區'],
    },
    {
      'id': 'green',
      'name': '古蹟綠軍',
      'subtitle': '諸羅歷史守護者',
      'emoji': '🏯',
      'color': FactionColors.greenPrimary,
      'glow': FactionColors.greenGlow,
      'gradient': [FactionColors.greenDark, FactionColors.greenPrimary],
      'description': '穿越百年時光隧道，\n守護嘉義的歷史文化，\n讓古蹟講述故事！',
      'bonus': '完成古蹟任務 +50 bonus pts',
      'missions': ['嘉義舊監獄', '城隍廟', '嘉義公園'],
    },
    {
      'id': 'blue',
      'name': '咖啡藍軍',
      'subtitle': '諸羅文青探索者',
      'emoji': '☕',
      'color': FactionColors.bluePrimary,
      'glow': FactionColors.blueGlow,
      'gradient': [FactionColors.blueDark, FactionColors.bluePrimary],
      'description': '在阿里山咖啡香氣中，\n尋找嘉義的慢活節奏，\n讓品味成為你的力量！',
      'bonus': '完成咖啡任務 +45 bonus pts',
      'missions': ['阿里山咖啡小棧', '蘭潭湖畔', '文化創意園區'],
    },
  ];

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FactionColors.darkBg,
      body: Stack(
        children: [
          // 背景漸層
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topCenter,
                radius: 1.5,
                colors: [Color(0xFF1A1A3E), FactionColors.darkBg],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // 返回按鈕
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new,
                          color: FactionColors.textSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),

                // 標題
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Text(
                        '⚔️ 選擇你的陣營',
                        style: TextStyle(
                          color: FactionColors.gold,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '一旦加入陣營，30天內不可更換\n請謹慎選擇你的歸屬！',
                        style: TextStyle(
                          color: FactionColors.textSecondary,
                          fontSize: 14,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 陣營卡片列表
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _factions.length,
                    itemBuilder: (_, i) => _buildFactionCard(_factions[i]),
                  ),
                ),

                // 確認按鈕
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: AnimatedBuilder(
                    animation: _glowController,
                    builder: (_, child) => Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: _selectedFaction != null
                            ? [
                                BoxShadow(
                                  color: FactionColors.forFaction(
                                          _selectedFaction!)
                                      .withValues(
                                          alpha: 0.4 * _glowController.value),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ]
                            : [],
                      ),
                      child: child,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _selectedFaction == null
                            ? null
                            : () async {
                                final user = FirebaseAuth.instance.currentUser;
                                if (user != null) {
                                  await FirebaseFirestore.instance
                                      .collection('users_public')
                                      .doc(user.uid)
                                      .update({
                                    'faction': _selectedFaction,
                                    'factionJoinedAt': FieldValue.serverTimestamp(),
                                  });
                                }

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          '${FactionColors.emojiForFaction(_selectedFaction!)} 已加入 ${FactionColors.nameForFaction(_selectedFaction!)}！'),
                                      backgroundColor: FactionColors.forFaction(_selectedFaction!),
                                    ),
                                  );
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedFaction != null
                              ? FactionColors.forFaction(_selectedFaction!)
                              : FactionColors.cardBorder,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: _selectedFaction != null ? 6 : 0,
                        ),
                        child: Text(
                          _selectedFaction != null
                              ? '確認加入 ${FactionColors.nameForFaction(_selectedFaction!)}'
                              : '請先選擇陣營',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
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

  Widget _buildFactionCard(Map<String, dynamic> faction) {
    final isSelected = _selectedFaction == faction['id'];
    final color = faction['color'] as Color;
    final glow = faction['glow'] as Color;
    final gradient = faction['gradient'] as List<Color>;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? color : FactionColors.cardBorder,
          width: isSelected ? 2.5 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: glow.withValues(alpha: 0.25),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      child: Material(
        color: isSelected
            ? Color.lerp(FactionColors.cardBg, color.withValues(alpha: 0.2), 0.5)
            : FactionColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => setState(() => _selectedFaction = faction['id'] as String),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    // 左側漸層圓
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: gradient,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                    color: glow.withValues(alpha: 0.4),
                                    blurRadius: 12,
                                    spreadRadius: 2)
                              ]
                            : [],
                      ),
                      child: Center(
                        child: Text(
                          faction['emoji'] as String,
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // 文字
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                faction['name'] as String,
                                style: TextStyle(
                                  color: isSelected
                                      ? color
                                      : FactionColors.textPrimary,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text('已選擇',
                                      style: TextStyle(
                                          color: FactionColors.gold,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            faction['subtitle'] as String,
                            style: TextStyle(
                              color: isSelected
                                  ? color.withValues(alpha: 0.7)
                                  : FactionColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 選擇標記
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? color : Colors.transparent,
                        border: Border.all(
                          color: isSelected ? color : FactionColors.cardBorder,
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check,
                              color: Colors.white, size: 14)
                          : null,
                    ),
                  ],
                ),

                // 展開內容
                if (isSelected) ...[
                  const SizedBox(height: 14),
                  const Divider(color: FactionColors.divider),
                  const SizedBox(height: 10),
                  Text(
                    faction['description'] as String,
                    style: TextStyle(
                      color: color.withValues(alpha: 0.85),
                      fontSize: 14,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: color.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bolt, color: color, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          faction['bonus'] as String,
                          style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                              fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  // 代表任務
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: (faction['missions'] as List<String>)
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
                                      fontSize: 12)),
                            ))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
