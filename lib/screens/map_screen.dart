import 'dart:ui' as ui;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';
import '../services/weather_service.dart';
import '../services/bus_service.dart';
import 'faction_select_screen.dart';
import 'ai_chat_bottom_sheet.dart';
import '../widgets/map_multi_fab.dart';
import 'backpack_screen.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  // 公開屬性與方法給 HomeScreen 控制 (簡潔模式)
  bool get isRouteRecording => _isRouteRecording;
  bool get showBus => _showBus;

  bool _isMenuOpenFromHome = false;
  void setMenuOpen(bool isOpen) {
    setState(() {
      _isMenuOpenFromHome = isOpen;
    });
  }

  void toggleRouteRecording() => _toggleRouteRecording();
  
  void recenter() => _mapController.move(_chiayi, 15);
  
  void zoomIn() {
    final cur = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, cur + 1);
  }
  
  void zoomOut() {
    final cur = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, cur - 1);
  }
  
  Future<void> toggleBus() async {
    setState(() {
      _showBus = !_showBus;
    });
    if (_showBus) {
      final busService = Provider.of<BusService>(context, listen: false);
      await busService.fetchBusData();
      if (!mounted) return;
      if (busService.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(busService.error!)));
      }
    }
  }
  final MapController _mapController = MapController();
  bool _isRouteRecording = false;
  final String _faction = 'red';
  String _missionFilter = 'all'; // 'all', 'food', 'heritage', 'cafe'
  bool _showBus = false;
  bool _showFactionLayer = true;
  double _sheetHeight = 170.0;

  late AnimationController _recordingPulse;
  
  final List<LatLng> _routePoints = [];
  StreamSubscription<Position>? _positionStream;
  Timer? _timer;
  int _elapsedSeconds = 0;

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
    _positionStream?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _toggleRouteRecording() async {
    if (_isRouteRecording) {
      // 停止錄製
      setState(() {
        _isRouteRecording = false;
      });
      _positionStream?.cancel();
      _timer?.cancel();

      // 結算與存檔
      if (_routePoints.length >= 2) {
        double totalDistance = 0;
        final Distance distanceCalc = const Distance();
        for (int i = 0; i < _routePoints.length - 1; i++) {
          totalDistance += distanceCalc.as(LengthUnit.Meter, _routePoints[i], _routePoints[i+1]);
        }

        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await _firestore.collection('users').doc(user.uid).collection('routes').add({
            'timestamp': FieldValue.serverTimestamp(),
            'durationSeconds': _elapsedSeconds,
            'distanceMeters': totalDistance,
            'points': _routePoints.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('跑圖已儲存！總距離：${totalDistance.toStringAsFixed(0)}m')),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('跑圖距離過短，未儲存')),
          );
        }
      }
      
      setState(() {
        _routePoints.clear();
        _elapsedSeconds = 0;
      });
    } else {
      // 開始錄製
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      setState(() {
        _isRouteRecording = true;
        _routePoints.clear();
        _elapsedSeconds = 0;
      });

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _elapsedSeconds++;
        });
      });

      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      );

      _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position pos) {
        final point = LatLng(pos.latitude, pos.longitude);
        setState(() {
          _routePoints.add(point);
        });
        _mapController.move(point, 17);
      });
    }
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
              interactionOptions: InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              // OSM Tile Layer
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.zhuluo_app',
                tileProvider: FMTCTileProvider(
                  stores: const {
                    'chiayi_store': BrowseStoreStrategy.readUpdateCreate,
                  },
                ),
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
                    if (r > g && r > b) {
                      color = FactionColors.redPrimary;
                    } else if (g > r && g > b) {
                      color = FactionColors.greenPrimary;
                    } else if (b > r && b > g) {
                      color = FactionColors.bluePrimary;
                    } else if (r > 0 || g > 0 || b > 0) {
                      color = Colors.white; // 平手
                    }

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
                      if (_showFactionLayer)
                        PolygonLayer(
                          polygons: _buildFactionPolygons(docs),
                        ),
                      CircleLayer(circles: circles),
                      // 跑圖軌跡
                      if (_routePoints.isNotEmpty)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: _routePoints,
                              strokeWidth: 4.0,
                              color: FactionColors.gold,
                            ),
                          ],
                        ),
                      MarkerLayer(markers: markers),
                      
                      // 公車動態 Markers
                      if (_showBus)
                        Consumer<BusService>(
                          builder: (context, busService, child) {
                            return MarkerLayer(
                              markers: busService.busStops.map((stop) {
                                return Marker(
                                  point: stop.position,
                                  width: 40,
                                  height: 40,
                                  child: GestureDetector(
                                    onTap: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('${stop.name}: ${stop.estimateTime > 0 ? "約 ${stop.estimateTime ~/ 60} 分鐘到站" : "未發車或末班車已過"}')),
                                      );
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.blueAccent,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                      child: const Icon(Icons.directions_bus, color: Colors.white, size: 20),
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
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
                          color: isDarkMode ? Colors.black.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
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

          // ── 天氣資訊小工具 ─────────────────────────────────────────
          Positioned(
            top: isSimplified ? 115 : 24,
            right: isSimplified ? 16 : 16,
            child: Consumer<WeatherService>(
              builder: (context, weatherService, child) {
                if (weatherService.isLoading) {
                  return const CircularProgressIndicator();
                }
                final weather = weatherService.currentWeather;
                if (weather == null) return const SizedBox.shrink();

                IconData weatherIcon;
                if (weather.description.contains('雨')) {
                  weatherIcon = Icons.beach_access;
                } else if (weather.description.contains('雲') || weather.description.contains('陰')) {
                  weatherIcon = Icons.cloud;
                } else {
                  weatherIcon = Icons.wb_sunny;
                }

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: (isDarkMode ? FactionColors.darkBg : Colors.white).withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: factionColor.withValues(alpha: 0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(weatherIcon, color: FactionColors.gold, size: 20),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('${weather.minTemp}°C - ${weather.maxTemp}°C', 
                              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 12)),
                          Text(weather.description, 
                              style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54, fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // ── 中央準心與雷達掃描動畫 ─────────────────────────────────────────
          if (_isRouteRecording)
            Positioned(
              top: 90,
              left: 16,
              right: 16,
              child: AnimatedBuilder(
                animation: _recordingPulse,
                 builder: (context, _) => Container(
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
                      Text(
                          '${(_elapsedSeconds ~/ 60).toString().padLeft(2, '0')}:${(_elapsedSeconds % 60).toString().padLeft(2, '0')}',
                          style: const TextStyle(
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

          // ── 右下：折疊式多功能懸浮選單 ────────────────────────────
          Positioned(
            bottom: isSimplified ? 40 : _sheetHeight + 16,
            right: 16,
            child: MapMultiFab(
              onAi: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const AiChatBottomSheet(),
                );
              },
              onBus: () async {
                setState(() {
                  _showBus = !_showBus;
                });
                if (_showBus) {
                  final busService = Provider.of<BusService>(context, listen: false);
                  await busService.fetchBusData();
                  if (!context.mounted) return;
                  if (busService.error != null) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(busService.error!)));
                  }
                }
              },
              onLocate: () => _mapController.move(_chiayi, 15),
              onRoute: _toggleRouteRecording,
              onZoomIn: () {
                final cur = _mapController.camera.zoom;
                _mapController.move(_mapController.camera.center, cur + 1);
              },
              onZoomOut: () {
                final cur = _mapController.camera.zoom;
                _mapController.move(_mapController.camera.center, cur - 1);
              },
              onToggleLayer: () {
                setState(() {
                  _showFactionLayer = !_showFactionLayer;
                });
              },
              showFactionLayer: _showFactionLayer,
              isRouteRecording: _isRouteRecording,
              showBus: _showBus,
              factionColor: factionColor,
              recordingPulse: _recordingPulse,
              isOpen: isSimplified ? _isMenuOpenFromHome : null,
              hideMainButton: isSimplified,
            ),
          ),

          // ── 左下：我的背包按鈕 (僅在常規/遊戲模式顯示) ────────────────────────────
          if (!isSimplified)
            Positioned(
              bottom: _sheetHeight + 16,
              left: 16,
              child: FloatingActionButton(
                heroTag: 'game_backpack',
                backgroundColor: FactionColors.bluePrimary,
                child: const Icon(Icons.backpack, color: Colors.white),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const BackpackBottomSheet(),
                  );
                },
              ),
            ),

          // ── 底部：附近任務快速列表 (僅在常規/遊戲模式顯示) ────────────────────────────
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
      if (value == 'food') {
        bgColor = FactionColors.redPrimary;
      } else if (value == 'heritage') {
        bgColor = FactionColors.greenPrimary;
      } else if (value == 'cafe') {
        bgColor = FactionColors.bluePrimary;
      } else {
        bgColor = Colors.black87;
      }
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
    final textColor = isDarkMode ? FactionColors.textPrimary : Colors.black87;
    final cardBgColor = isDarkMode ? FactionColors.cardBg : Colors.white;

    return GestureDetector(
      onVerticalDragUpdate: (details) {
        setState(() {
          _sheetHeight = (_sheetHeight - details.delta.dy).clamp(40.0, 500.0);
        });
      },
      onVerticalDragEnd: (details) {
        double target;
        if (_sheetHeight < 105.0) {
          target = 40.0;
        } else if (_sheetHeight < 335.0) {
          target = 170.0;
        } else {
          target = 500.0;
        }
        setState(() {
          _sheetHeight = target;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: _sheetHeight,
        decoration: BoxDecoration(
          color: isDarkMode ? FactionColors.cardBg : Colors.white,
          border: Border(top: BorderSide(color: isDarkMode ? FactionColors.cardBorder : Colors.grey.shade300)),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
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
            // 頂部拖拽條
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

            // 狀態 1：最小化
            if (_sheetHeight <= 60)
              Expanded(
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.keyboard_arrow_up, color: FactionColors.gold, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '附近任務 (向上拉起展開)',
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.7),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            // 狀態 2 & 3
            else ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Text(
                      _sheetHeight > 300 ? '🗺️ 附近任務列表' : '📍 附近任務',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      _sheetHeight > 300 ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                      color: FactionColors.gold,
                      size: 18,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
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

                    // 狀態 3：全開狀態，垂直排列
                    if (_sheetHeight > 300) {
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: docs.length,
                        itemBuilder: (_, i) {
                          final data = docs[i].data() as Map<String, dynamic>;
                          final color = _categoryColor(data['category'] ?? '');

                          String emoji = '📍';
                          if (data['category'] == 'heritage') emoji = '🏛️';
                          if (data['category'] == 'food') emoji = '🍜';
                          if (data['category'] == 'cafe') emoji = '☕';

                          return Card(
                            color: cardBgColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(color: color.withValues(alpha: 0.3)),
                            ),
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: Text(emoji, style: const TextStyle(fontSize: 26)),
                              title: Text(
                                data['name'] ?? '',
                                style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              subtitle: Text(
                                data['category'] == 'food'
                                    ? '美食打卡點'
                                    : data['category'] == 'heritage'
                                        ? '古蹟打卡點'
                                        : '咖啡廳打卡點',
                                style: TextStyle(color: textColor.withValues(alpha: 0.6), fontSize: 12),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star, color: FactionColors.gold, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    '+${data['basePoints']}',
                                    style: const TextStyle(color: FactionColors.gold, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.chevron_right, color: Colors.grey),
                                ],
                              ),
                              onTap: () {
                                data['id'] = docs[i].id;
                                data['emoji'] = emoji;
                                _showMissionSheet(data);
                              },
                            ),
                          );
                        },
                      );
                    }

                    // 狀態 2：中度狀態，水平排列
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
                              border: Border.all(color: color.withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(emoji, style: const TextStyle(fontSize: 22)),
                                Text(
                                  data['name'] ?? '',
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.star, color: FactionColors.gold, size: 13),
                                    const SizedBox(width: 3),
                                    Text(
                                      '+${data['basePoints']}',
                                      style: const TextStyle(
                                        color: FactionColors.gold,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
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
          ],
        ),
      ),
    );
  }

  void _showMissionSheet(Map<String, dynamic> m) {
    final color = _categoryColor(m['category'] as String);
    
    // 同陣營 20% 加成邏輯
    final String userFaction = _faction; 
    String missionFaction = 'none';
    if (m['category'] == 'food') missionFaction = 'red';
    if (m['category'] == 'heritage') missionFaction = 'green';
    if (m['category'] == 'cafe') missionFaction = 'blue';
    
    final bool hasBonus = userFaction == missionFaction;
    final int basePoints = (m['basePoints'] ?? 100) as int;
    final int bonusPoints = hasBonus ? (basePoints * 0.2).toInt() : 0;
    final bonusColor = FactionColors.forFaction(userFaction);

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
              '基礎積分 +$basePoints',
              style: TextStyle(color: color, fontSize: 15),
            ),
            if (hasBonus) ...[
              const SizedBox(height: 4),
              Text(
                '${FactionColors.emojiForFaction(userFaction)} 同陣營加成 +$bonusPoints',
                style: TextStyle(color: bonusColor, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
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
                onPressed: () {
                  Navigator.pop(context); // 關閉任務彈窗
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SimulatedScannerPage(
                        mission: m,
                        userFaction: _faction,
                      ),
                    ),
                  );
                },
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

  List<Polygon> _buildFactionPolygons(List<QueryDocumentSnapshot> docs) {
    final List<Polygon> polygons = [];
    
    // 嘉義市邊界網格 (4x4)
    const double latMin = 23.4400;
    const double latMax = 23.5100;
    const double lngMin = 120.4100;
    const double lngMax = 120.4800;
    
    const int gridCount = 4;
    const double latStep = (latMax - latMin) / gridCount;
    const double lngStep = (lngMax - lngMin) / gridCount;
    
    for (int row = 0; row < gridCount; row++) {
      for (int col = 0; col < gridCount; col++) {
        final cellLatMin = latMin + row * latStep;
        final cellLatMax = cellLatMin + latStep;
        final cellLngMin = lngMin + col * lngStep;
        final cellLngMax = cellLngMin + lngStep;
        
        int redCheckIns = 0;
        int greenCheckIns = 0;
        int blueCheckIns = 0;
        
        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final double? lat = data['lat'] as double?;
          final double? lng = data['lng'] as double?;
          
          if (lat != null && lng != null) {
            if (lat >= cellLatMin && lat < cellLatMax && lng >= cellLngMin && lng < cellLngMax) {
              final checkIns = data['checkInsByFaction'] as Map<String, dynamic>? ?? {};
              redCheckIns += (checkIns['red'] ?? 0) as int;
              greenCheckIns += (checkIns['green'] ?? 0) as int;
              blueCheckIns += (checkIns['blue'] ?? 0) as int;
            }
          }
        }
        
        Color fillColor = Colors.transparent;
        Color borderColor = Colors.transparent;
        
        if (redCheckIns > greenCheckIns && redCheckIns > blueCheckIns) {
          fillColor = FactionColors.redPrimary.withValues(alpha: 0.12);
          borderColor = FactionColors.redPrimary.withValues(alpha: 0.4);
        } else if (greenCheckIns > redCheckIns && greenCheckIns > blueCheckIns) {
          fillColor = FactionColors.greenPrimary.withValues(alpha: 0.12);
          borderColor = FactionColors.greenPrimary.withValues(alpha: 0.4);
        } else if (blueCheckIns > redCheckIns && blueCheckIns > greenCheckIns) {
          fillColor = FactionColors.bluePrimary.withValues(alpha: 0.12);
          borderColor = FactionColors.bluePrimary.withValues(alpha: 0.4);
        } else if (redCheckIns > 0 || greenCheckIns > 0 || blueCheckIns > 0) {
          fillColor = Colors.white.withValues(alpha: 0.08);
          borderColor = Colors.white.withValues(alpha: 0.3);
        } else {
          // No check-ins yet, show faint grid
          fillColor = Colors.grey.withValues(alpha: 0.05);
          borderColor = Colors.grey.withValues(alpha: 0.2);
        }
        
        if (fillColor != Colors.transparent) {
          polygons.add(
            Polygon(
              points: [
                LatLng(cellLatMin, cellLngMin),
                LatLng(cellLatMax, cellLngMin),
                LatLng(cellLatMax, cellLngMax),
                LatLng(cellLatMin, cellLngMax),
              ],
              color: fillColor,
              borderColor: borderColor,
              borderStrokeWidth: 1.5,
            ),
          );
        }
      }
    }
    
    return polygons;
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

// 實裝手機鏡頭/模擬掃描 QR Code 頁面
class SimulatedScannerPage extends StatefulWidget {
  final Map<String, dynamic> mission;
  final String userFaction;
  
  const SimulatedScannerPage({
    super.key,
    required this.mission,
    required this.userFaction,
  });

  @override
  State<SimulatedScannerPage> createState() => _SimulatedScannerPageState();
}

class _SimulatedScannerPageState extends State<SimulatedScannerPage> with SingleTickerProviderStateMixin {
  late AnimationController _scanController;
  late Animation<double> _scanAnimation;
  bool _isScanningDone = false;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_scanController);
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  Future<void> _performCheckIn() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final m = widget.mission;
    final faction = widget.userFaction;

    // 計算分數
    final int basePoints = (m['basePoints'] ?? 100) as int;
    String missionFaction = 'none';
    if (m['category'] == 'food') missionFaction = 'red';
    if (m['category'] == 'heritage') missionFaction = 'green';
    if (m['category'] == 'cafe') missionFaction = 'blue';

    final bool hasBonus = faction == missionFaction;
    final int bonusPoints = hasBonus ? (basePoints * 0.2).toInt() : 0;
    final int totalEarned = basePoints + bonusPoints;

    try {
      final missionRef = FirebaseFirestore.instance.collection('missions').doc(m['id']);
      final userPublicRef = FirebaseFirestore.instance.collection('users_public').doc(user.uid);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        transaction.update(missionRef, {
          'totalCheckIns': FieldValue.increment(1),
          'checkInsByFaction.$faction': FieldValue.increment(1),
        });
        transaction.update(userPublicRef, {
          'totalScore': FieldValue.increment(totalEarned),
        });
      });

      final updatedDoc = await FirebaseFirestore.instance.collection('missions').doc(m['id']).get();
      final updatedData = updatedDoc.data() ?? {};
      final checkIns = updatedData['checkInsByFaction'] as Map<String, dynamic>? ?? {'red': 0, 'green': 0, 'blue': 0};

      int rCount = (checkIns['red'] ?? 0) as int;
      int gCount = (checkIns['green'] ?? 0) as int;
      int bCount = (checkIns['blue'] ?? 0) as int;

      if (!mounted) return;
      Navigator.pop(context); // 關閉掃描頁

      // 彈出打卡成功與分數、勢力次數結算
      showDialog(
        context: context,
        builder: (dialogCtx) {
          final isDarkMode = Provider.of<ThemeProvider>(dialogCtx, listen: false).isDarkMode;
          return AlertDialog(
            backgroundColor: isDarkMode ? FactionColors.darkBg : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: [
                Text(m['emoji'] as String, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 8),
                Text('打卡成功！', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('已征服【${m['name']}】', style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star, color: FactionColors.gold, size: 24),
                    const SizedBox(width: 6),
                    Text(
                      '+$totalEarned 積分',
                      style: const TextStyle(color: FactionColors.gold, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                if (hasBonus) ...[
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      '🎉 享有同陣營加成額外 +$bonusPoints 積分！',
                      style: TextStyle(color: FactionColors.forFaction(faction), fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 10),
                const Text('🔥 各方勢力打卡總次數：', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: FactionColors.gold)),
                const SizedBox(height: 8),
                _buildFactionResultRow('🔴 美食紅勢力：', rCount, FactionColors.redPrimary),
                const SizedBox(height: 6),
                _buildFactionResultRow('🟢 古蹟綠勢力：', gCount, FactionColors.greenPrimary),
                const SizedBox(height: 6),
                _buildFactionResultRow('🔵 咖啡藍勢力：', bCount, FactionColors.bluePrimary),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogCtx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: FactionColors.forFaction(faction),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('確認', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('打卡失敗: $e')),
      );
    }
  }

  Widget _buildFactionResultRow(String label, int count, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.white70)),
        Text('$count 次完成', style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 鏡頭畫面/相機底座
          Positioned.fill(
            child: ClipRect(
              child: MobileScanner(
                controller: MobileScannerController(
                  detectionSpeed: DetectionSpeed.normal,
                  facing: CameraFacing.back,
                ),
                onDetect: (capture) {
                  final List<Barcode> barcodes = capture.barcodes;
                  for (final barcode in barcodes) {
                    if (barcode.rawValue != null && !_isScanningDone) {
                      _isScanningDone = true;
                      _performCheckIn();
                      break;
                    }
                  }
                },
              ),
            ),
          ),

          // 深色覆蓋遮罩以突顯掃描框
          Positioned.fill(
            child: Container(
              color: Colors.black54,
            ),
          ),
          
          // 掃描框與介面提示
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 40),
                const Text(
                  '📸 對準 QR Code 掃描打卡',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  '請將條碼置於下方金色框線中',
                  style: TextStyle(color: Colors.white60, fontSize: 13),
                ),
                const Spacer(),
                
                // 掃描框
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      // 邊框
                      Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          border: Border.all(color: FactionColors.gold, width: 3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      // 掃描雷射線
                      AnimatedBuilder(
                        animation: _scanAnimation,
                        builder: (context, child) {
                          return Positioned(
                            top: 10 + (230 * _scanAnimation.value),
                            left: 10,
                            right: 10,
                            child: Container(
                              height: 3,
                              decoration: BoxDecoration(
                                color: Colors.greenAccent,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.greenAccent.withValues(alpha: 0.8),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      
                      // 模擬掃描按鈕 (測試用，極度方便在電腦模擬器無鏡頭時測試)
                      Positioned(
                        bottom: -45,
                        child: TextButton(
                          onPressed: () {
                            if (!_isScanningDone) {
                              _isScanningDone = true;
                              _performCheckIn();
                            }
                          },
                          child: const Text(
                            '⚡ 點此模擬掃描成功 (測試專用)',
                            style: TextStyle(color: FactionColors.gold, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 40.0),
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white54),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    child: const Text('取消返回', style: TextStyle(color: Colors.white70)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

