import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';
import 'faction_select_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  bool _isRouteRecording = false;
  final String _faction = 'red';
  String _missionFilter = 'all'; // 'all', 'food', 'heritage', 'cafe'

  late AnimationController _recordingPulse;

  // 嘉義市中心座標
  static const LatLng _chiayi = LatLng(23.4800, 120.4491);

  // Firebase Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _recordingPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _recordingPulse.dispose();
    super.dispose();
  }

  Color _categoryColor(String cat) {
    switch (cat) {
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

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isSimplified = themeProvider.isSimplifiedMode;
    final isDarkMode = themeProvider.isDarkMode;

    final factionColor = FactionColors.forFaction(_faction);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // ── OSM 地圖 ─────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: _chiayi,
              initialZoom: 15.0,
              minZoom: 10,
              maxZoom: 18,
            ),
            children: [
              // OSM Tile Layer
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.zhuluo_app',
                // 深色濾鏡：如果目前是夜間模式，讓 OSM 配合 App 暗色主題；明亮模式則直接原圖
                tileBuilder: (context, child, tile) {
                  if (!isDarkMode) return child;
                  return ColorFiltered(
                    colorFilter: const ColorFilter.matrix(<double>[
                      -0.85,  0,     0,     0, 255,
                       0,    -0.85,  0,     0, 255,
                       0,     0,    -0.85,  0, 255,
                       0,     0,     0,     1,   0,
                    ]),
                    child: child,
                  );
                },
              ),

              // 即時監聽 Firestore Missions
              StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('missions')
                    .where('status', isEqualTo: 'active')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox.shrink();

                  final docs = snapshot.data!.docs;
                  
                  final filteredDocs = docs.where((doc) {
                    if (_missionFilter == 'all') return true;
                    final data = doc.data() as Map<String, dynamic>;
                    return data['category'] == _missionFilter;
                  }).toList();

                  // 1. 領地控制圓圈 (CircleLayer)
                  final circles = filteredDocs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    
                    // 動態計算佔領陣營
                    final checkIns = data['checkInsByFaction'] as Map<String, dynamic>? ?? {'red': 0, 'green': 0, 'blue': 0};
                    int r = (checkIns['red'] ?? 0) as int;
                    int g = (checkIns['green'] ?? 0) as int;
                    int b = (checkIns['blue'] ?? 0) as int;
                    
                    Color color = Colors.grey; // 預設無人佔領
                    if (r > g && r > b) color = FactionColors.redPrimary;
                    else if (g > r && g > b) color = FactionColors.greenPrimary;
                    else if (b > r && b > g) color = FactionColors.bluePrimary;
                    else if (r > 0 || g > 0 || b > 0) color = Colors.white; // 平手

                    final totalCheckIns = data['totalCheckIns'] ?? 0;
                    final radius = (50.0 + (totalCheckIns * 5)).clamp(50.0, 300.0);
                    
                    return CircleMarker(
                      point: LatLng(data['lat'] ?? 0.0, data['lng'] ?? 0.0),
                      radius: radius,
                      useRadiusInMeter: true,
                      color: color.withValues(alpha: 0.35),
                      borderColor: color.withValues(alpha: 0.9),
                      borderStrokeWidth: 3,
                    );
                  }).toList();

                  // 2. 任務點地標 (MarkerLayer)
                  final markers = filteredDocs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final color = _categoryColor(data['category'] ?? '');
                    
                    // 決定 Emoji
                    String emoji = '📍';
                    if (data['category'] == 'heritage') emoji = '🏛️';
                    if (data['category'] == 'food') emoji = '🍜';
                    if (data['category'] == 'cafe') emoji = '☕';
                    
                    return Marker(
                      point: LatLng(data['lat'] ?? 0.0, data['lng'] ?? 0.0),
                      width: 56,
                      height: 70,
                      child: GestureDetector(
                        onTap: () {
                          data['id'] = doc.id; // 帶入 ID
                          data['emoji'] = emoji;
                          _showMissionSheet(data);
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.55),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  emoji,
                                  style: const TextStyle(fontSize: 22),
                                ),
                              ),
                            ),
                            // 箭頭
                            CustomPaint(
                              size: const Size(14, 8),
                              painter: _MarkerArrow(color: color),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList();

                  return Stack(
                    children: [
                      CircleLayer(circles: circles),
                      MarkerLayer(markers: markers),
                    ],
                  );
                },
              ),
            ],
          ),

          // ── 頂部 HUD (根據模式切換) ─────────────────────────────────────
          if (isSimplified)
            Positioned(
              top: 0, left: 0, right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        height: 50,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.black.withOpacity(0.4) : Colors.white.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.menu, color: isDarkMode ? Colors.white : Colors.black87),
                              onPressed: () => Scaffold.of(context).openDrawer(),
                            ),
                            const Spacer(),
                            _buildFilterBtn('全部', 'all', isDarkMode),
                            _buildFilterBtn('美食紅', 'food', isDarkMode),
                            _buildFilterBtn('古蹟綠', 'heritage', isDarkMode),
                            _buildFilterBtn('咖啡藍', 'cafe', isDarkMode),
                            const Spacer(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            )
          else
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                    // 陣營徽章
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const FactionSelectScreen(),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: FactionColors.cardBg.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: factionColor.withValues(alpha: 0.6),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              FactionColors.emojiForFaction(_faction),
                              style: const TextStyle(fontSize: 18),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              FactionColors.nameForFaction(_faction),
                              style: TextStyle(
                                color: factionColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    // 積分
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: FactionColors.cardBg.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: FactionColors.gold.withValues(alpha: 0.4),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star,
                              color: FactionColors.gold, size: 16),
                          SizedBox(width: 4),
                          Text(
                            '3,850',
                            style: TextStyle(
                              color: FactionColors.gold,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── 跑圖錄製 HUD ─────────────────────────────────────
          if (_isRouteRecording)
            Positioned(
              top: 90,
              left: 16,
              right: 16,
              child: AnimatedBuilder(
                animation: _recordingPulse,
                builder: (_, __) => Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: FactionColors.redDark.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: FactionColors.redGlow.withValues(
                          alpha: 0.4 + 0.5 * _recordingPulse.value),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: FactionColors.redGlow.withValues(
                              alpha: 0.5 + 0.5 * _recordingPulse.value),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('跑圖記錄中',
                          style: TextStyle(
                            color: FactionColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          )),
                      const Spacer(),
                      const Text('00:00',
                          style: TextStyle(
                            color: FactionColors.gold,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            fontFamily: 'monospace',
                          )),
                    ],
                  ),
                ),
              ),
            ),

          // ── 右下：縮放 + 跑圖按鈕 ────────────────────────────
          Positioned(
            bottom: 200,
            right: 16,
            child: Column(
              children: [
                // 放大
                _MapFab(
                  icon: Icons.add,
                  onTap: () {
                    final cur = _mapController.camera.zoom;
                    _mapController.move(_mapController.camera.center, cur + 1);
                  },
                ),
                const SizedBox(height: 8),
                // 縮小
                _MapFab(
                  icon: Icons.remove,
                  onTap: () {
                    final cur = _mapController.camera.zoom;
                    _mapController.move(_mapController.camera.center, cur - 1);
                  },
                ),
                const SizedBox(height: 8),
                // 回中心
                _MapFab(
                  icon: Icons.my_location,
                  onTap: () => _mapController.move(_chiayi, 15),
                  color: factionColor,
                ),
                const SizedBox(height: 12),
                // 跑圖按鈕
                AnimatedBuilder(
                  animation: _recordingPulse,
                  builder: (_, __) => GestureDetector(
                    onTap: () =>
                        setState(() => _isRouteRecording = !_isRouteRecording),
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isRouteRecording
                            ? FactionColors.redPrimary
                            : FactionColors.cardBg,
                        border: Border.all(
                          color: _isRouteRecording
                              ? FactionColors.redGlow.withValues(
                                  alpha: 0.5 +
                                      0.5 * _recordingPulse.value)
                              : FactionColors.gold.withValues(alpha: 0.7),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (_isRouteRecording
                                    ? FactionColors.redGlow
                                    : FactionColors.gold)
                                .withValues(alpha: 0.25),
                            blurRadius: 14,
                          ),
                        ],
                      ),
                      child: Icon(
                        _isRouteRecording
                            ? Icons.stop
                            : Icons.directions_run,
                        color: _isRouteRecording
                            ? Colors.white
                            : FactionColors.gold,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── 底部：附近任務快速列表 ────────────────────────────
          if (!isSimplified)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomSheet(),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterBtn(String label, String value, bool isDarkMode) {
    final isSelected = _missionFilter == value;
    final textColor = isSelected 
        ? Colors.white 
        : (isDarkMode ? Colors.white70 : Colors.black54);
    
    Color bgColor = Colors.transparent;
    if (isSelected) {
      if (value == 'food') bgColor = FactionColors.redPrimary;
      else if (value == 'heritage') bgColor = FactionColors.greenPrimary;
      else if (value == 'cafe') bgColor = FactionColors.bluePrimary;
      else bgColor = Colors.black87;
    }

    return GestureDetector(
      onTap: () => setState(() => _missionFilter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  // 任務 Bottom Sheet
  Widget _buildBottomSheet() {
    final isDarkMode = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    return Container(
      height: 170,
      decoration: BoxDecoration(
        color: isDarkMode ? FactionColors.cardBg : Colors.white,
        border: Border(top: BorderSide(color: isDarkMode ? FactionColors.cardBorder : Colors.grey.shade300)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: isDarkMode ? FactionColors.cardBorder : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text('附近任務',
                    style: TextStyle(
                      color: isDarkMode ? FactionColors.textPrimary : Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    )),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('missions')
                  .where('status', isEqualTo: 'active')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(
                    child: Text('目前沒有可接取的任務', style: TextStyle(color: Colors.white54)),
                  );
                }

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final color = _categoryColor(data['category'] ?? '');
                    
                    String emoji = '📍';
                    if (data['category'] == 'heritage') emoji = '🏛️';
                    if (data['category'] == 'food') emoji = '🍜';
                    if (data['category'] == 'cafe') emoji = '☕';

                    return GestureDetector(
                      onTap: () {
                        data['id'] = docs[i].id;
                        data['emoji'] = emoji;
                        _showMissionSheet(data);
                      },
                      child: Container(
                        width: 150,
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: color.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(emoji, style: const TextStyle(fontSize: 22)),
                            Text(
                              data['name'] ?? '',
                              style: TextStyle(
                                color: isDarkMode ? FactionColors.textPrimary : Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Row(
                              children: [
                                const Icon(Icons.star,
                                    color: FactionColors.gold, size: 13),
                                const SizedBox(width: 3),
                                Text('+${data['basePoints']}',
                                    style: const TextStyle(
                                        color: FactionColors.gold,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
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

  void _showMissionSheet(Map<String, dynamic> m) {
    final color = _categoryColor(m['category'] as String);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: FactionColors.cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(m['emoji'] as String,
                style: const TextStyle(fontSize: 52)),
            const SizedBox(height: 12),
            Text(m['name'] as String,
                style: const TextStyle(
                  color: FactionColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                )),
            const SizedBox(height: 6),
            Text(
              '基礎積分 +${m['basePoints']}',
              style: TextStyle(color: color, fontSize: 15),
            ),
            const SizedBox(height: 16),
            
            // 陣營佔領戰況
            _buildTerritoryStats(m),

            const SizedBox(height: 20),
            // 在地圖上置中
            OutlinedButton.icon(
              icon: Icon(Icons.center_focus_strong, color: color),
              label: Text('地圖定位', style: TextStyle(color: color)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: color),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pop(context);
                _mapController.move(
                  LatLng(m['lat'] as double, m['lng'] as double),
                  17,
                );
              },
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('掃描打卡',
                    style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildTerritoryStats(Map<String, dynamic> m) {
    final checkIns = m['checkInsByFaction'] as Map<String, dynamic>? ?? {'red': 0, 'green': 0, 'blue': 0};
    int r = (checkIns['red'] ?? 0) as int;
    int g = (checkIns['green'] ?? 0) as int;
    int b = (checkIns['blue'] ?? 0) as int;
    int total = r + g + b;
    if (total == 0) total = 1; // 避免除以 0

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('陣營佔領戰況', style: TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 8),
        _buildStatRow('美食紅', r, total, FactionColors.redPrimary),
        const SizedBox(height: 6),
        _buildStatRow('古蹟綠', g, total, FactionColors.greenPrimary),
        const SizedBox(height: 6),
        _buildStatRow('咖啡藍', b, total, FactionColors.bluePrimary),
      ],
    );
  }

  Widget _buildStatRow(String label, int count, int total, Color color) {
    double ratio = count / total;
    return Row(
      children: [
        SizedBox(width: 48, child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold))),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(width: 30, child: Text('$count 次', style: const TextStyle(color: Colors.white, fontSize: 12), textAlign: TextAlign.right)),
      ],
    );
  }
}

// 地圖浮動按鈕
class _MapFab extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const _MapFab(
      {required this.icon, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: FactionColors.cardBg.withValues(alpha: 0.95),
          shape: BoxShape.circle,
          border: Border.all(
            color: (color ?? FactionColors.cardBorder)
                .withValues(alpha: 0.5),
          ),
          boxShadow: const [
            BoxShadow(color: Colors.black38, blurRadius: 6)
          ],
        ),
        child: Icon(icon,
            color: color ?? FactionColors.textSecondary, size: 20),
      ),
    );
  }
}

// Marker 底部三角箭頭
class _MarkerArrow extends CustomPainter {
  final Color color;
  _MarkerArrow({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = ui.Paint()..color = color;
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}
