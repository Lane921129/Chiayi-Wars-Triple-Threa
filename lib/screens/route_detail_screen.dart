import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';

class RouteDetailScreen extends StatefulWidget {
  final Map<String, dynamic> record;

  const RouteDetailScreen({super.key, required this.record});

  @override
  State<RouteDetailScreen> createState() => _RouteDetailScreenState();
}

class _RouteDetailScreenState extends State<RouteDetailScreen> {
  final MapController _mapController = MapController();
  List<LatLng> _points = [];

  @override
  void initState() {
    super.initState();
    final rawPoints = widget.record['points'] as List<dynamic>? ?? [];
    for (var p in rawPoints) {
      if (p is Map<String, dynamic>) {
        _points.add(LatLng(p['lat'] as double, p['lng'] as double));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final factionColor = FactionColors.forFaction(widget.record['faction'] ?? 'red');
    
    final distance = widget.record['distanceMeters'] as num? ?? 0;
    final duration = widget.record['durationSeconds'] as num? ?? 0;
    final avgSpeed = duration > 0 ? (distance / duration) * 3.6 : 0.0; // km/h
    final weather = widget.record['weather'] ?? '未知天氣';
    final timestamp = widget.record['timestamp'] as Timestamp?;
    final dateStr = timestamp != null
        ? '${timestamp.toDate().year}/${timestamp.toDate().month.toString().padLeft(2, '0')}/${timestamp.toDate().day.toString().padLeft(2, '0')} ${timestamp.toDate().hour.toString().padLeft(2, '0')}:${timestamp.toDate().minute.toString().padLeft(2, '0')}'
        : '未知時間';
    final displayName = widget.record['displayName'] ?? '跑圖紀錄';

    LatLngBounds? bounds;
    if (_points.isNotEmpty) {
      bounds = LatLngBounds.fromPoints(_points);
    }
    
    final mapCenter = _points.isNotEmpty ? _points.first : const LatLng(23.4800, 120.4491);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('$displayName的軌跡', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, shadows: [Shadow(color: Colors.black87, blurRadius: 4)])),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white, shadows: [Shadow(color: Colors.black87, blurRadius: 4)]),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: mapCenter,
              initialZoom: 15.0,
              initialCameraFit: bounds != null
                  ? CameraFit.bounds(
                      bounds: bounds,
                      padding: const EdgeInsets.all(50),
                    )
                  : null,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.zhuluo_app',
                tileBuilder: isDarkMode
                    ? (context, tileWidget, tile) {
                        return ColorFiltered(
                          colorFilter: const ColorFilter.matrix([
                            -1, 0, 0, 0, 255,
                            0, -1, 0, 0, 255,
                            0, 0, -1, 0, 255,
                            0, 0, 0, 1, 0,
                          ]),
                          child: tileWidget,
                        );
                      }
                    : null,
              ),
              if (_points.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _points,
                      strokeWidth: 6.0,
                      color: factionColor.withValues(alpha: 0.8),
                      borderStrokeWidth: 2.0,
                      borderColor: Colors.black87,
                    ),
                  ],
                ),
              if (_points.isNotEmpty)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _points.first,
                      child: const Icon(Icons.play_circle_fill, color: Colors.green, size: 30),
                    ),
                    if (_points.length > 1)
                      Marker(
                        point: _points.last,
                        child: const Icon(Icons.stop_circle, color: Colors.red, size: 30),
                      ),
                  ],
                ),
            ],
          ),
          
          // Stats Card
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDarkMode ? FactionColors.cardBg.withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, spreadRadius: 2),
                ],
                border: Border.all(color: factionColor.withValues(alpha: 0.5), width: 2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(dateStr, style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54, fontSize: 13, fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          Icon(Icons.cloud, size: 16, color: factionColor),
                          const SizedBox(width: 4),
                          Text(weather, style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87, fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(
                        icon: Icons.route,
                        label: '距離',
                        value: (distance / 1000).toStringAsFixed(2),
                        unit: 'km',
                        color: factionColor,
                        isDarkMode: isDarkMode,
                      ),
                      _StatItem(
                        icon: Icons.timer,
                        label: '時間',
                        value: '${duration ~/ 60}:${(duration % 60).toString().padLeft(2, '0')}',
                        unit: 'min',
                        color: factionColor,
                        isDarkMode: isDarkMode,
                      ),
                      _StatItem(
                        icon: Icons.speed,
                        label: '均速',
                        value: avgSpeed.toStringAsFixed(1),
                        unit: 'km/h',
                        color: factionColor,
                        isDarkMode: isDarkMode,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;
  final bool isDarkMode;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.white54 : Colors.black54, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(width: 2),
            Text(
              unit,
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.white70 : Colors.black54,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
