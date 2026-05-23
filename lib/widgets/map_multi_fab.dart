import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MapMultiFab extends StatefulWidget {
  final VoidCallback onAi;
  final VoidCallback onBus;
  final VoidCallback onLocate;
  final VoidCallback onRoute;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onToggleLayer;
  final bool showFactionLayer;
  final bool isRouteRecording;
  final bool showBus;
  final Color factionColor;
  final AnimationController recordingPulse;
  final bool? isOpen; // 外部控制開關 (簡潔模式用)
  final bool hideMainButton; // 隱藏主按鈕 (簡潔模式用)

  const MapMultiFab({
    super.key,
    required this.onAi,
    required this.onBus,
    required this.onLocate,
    required this.onRoute,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onToggleLayer,
    required this.showFactionLayer,
    required this.isRouteRecording,
    required this.showBus,
    required this.factionColor,
    required this.recordingPulse,
    this.isOpen,
    this.hideMainButton = false,
  });

  @override
  State<MapMultiFab> createState() => _MapMultiFabState();
}

class _MapMultiFabState extends State<MapMultiFab> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    
    // 如果外部有給定初始狀態
    if (widget.isOpen == true) {
      _isOpen = true;
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(MapMultiFab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen != null && widget.isOpen != oldWidget.isOpen) {
      setState(() {
        _isOpen = widget.isOpen!;
      });
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    if (widget.isOpen != null) return; // 外部控制時，不響應點擊主按鈕
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  Widget _buildItem(IconData icon, String label, Color color, double dy, VoidCallback onTap, {Color iconColor = Colors.white}) {
    return AnimatedBuilder(
      animation: _expandAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, dy * (1 - _expandAnimation.value)),
          child: Opacity(
            opacity: _expandAnimation.value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: IgnorePointer(
        ignoring: !_isOpen,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: SizedBox(
            width: 46,
            height: 46,
            child: FloatingActionButton(
              heroTag: label,
              mini: true,
              backgroundColor: color,
              onPressed: () {
                if (widget.isOpen == null) {
                  _toggle();
                }
                onTap();
              },
              child: Icon(icon, color: iconColor, size: 20),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 勢力圖層開關 (最頂端)
        _buildItem(
          widget.showFactionLayer ? Icons.layers : Icons.layers_outlined, 
          'map_layer', 
          widget.showFactionLayer ? Colors.orangeAccent : FactionColors.cardBg, 
          405, 
          widget.onToggleLayer, 
          iconColor: widget.showFactionLayer ? Colors.white : widget.factionColor
        ),

        // 放大按鈕
        _buildItem(
          Icons.add, 
          'map_zoom_in', 
          FactionColors.cardBg, 
          350, 
          widget.onZoomIn, 
          iconColor: widget.factionColor
        ),

        // 縮小按鈕
        _buildItem(
          Icons.remove, 
          'map_zoom_out', 
          FactionColors.cardBg, 
          295, 
          widget.onZoomOut, 
          iconColor: widget.factionColor
        ),

        // AI 嚮導
        _buildItem(
          Icons.auto_awesome, 
          'map_ai', 
          FactionColors.gold, 
          240, 
          widget.onAi, 
          iconColor: Colors.black87
        ),
        
        // 公車動態
        _buildItem(
          widget.showBus ? Icons.directions_bus : Icons.directions_bus_outlined,
          'map_bus',
          widget.showBus ? Colors.blueAccent : FactionColors.cardBg,
          185,
          widget.onBus,
          iconColor: widget.showBus ? Colors.white : FactionColors.textPrimary,
        ),
        
        // 定位回中心
        _buildItem(
          Icons.my_location,
          'map_locate',
          FactionColors.cardBg,
          130,
          widget.onLocate,
          iconColor: widget.factionColor,
        ),
        
        // 跑圖錄製按鈕
        AnimatedBuilder(
          animation: _expandAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, 75 * (1 - _expandAnimation.value)),
              child: Opacity(
                opacity: _expandAnimation.value.clamp(0.0, 1.0),
                child: child,
              ),
            );
          },
          child: IgnorePointer(
            ignoring: !_isOpen,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: AnimatedBuilder(
                animation: widget.recordingPulse,
                builder: (context, _) => GestureDetector(
                  onTap: () {
                    if (widget.isOpen == null) {
                      _toggle();
                    }
                    widget.onRoute();
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.isRouteRecording
                          ? FactionColors.redPrimary
                          : FactionColors.cardBg,
                      border: Border.all(
                        color: widget.isRouteRecording
                            ? FactionColors.redGlow.withValues(
                                alpha: 0.5 + 0.5 * widget.recordingPulse.value)
                            : FactionColors.gold.withValues(alpha: 0.7),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (widget.isRouteRecording
                                  ? FactionColors.redGlow
                                  : FactionColors.gold)
                              .withValues(
                                  alpha: widget.isRouteRecording
                                      ? (0.2 + 0.3 * widget.recordingPulse.value)
                                      : 0.1),
                          blurRadius: widget.isRouteRecording ? 12 : 6,
                          spreadRadius: widget.isRouteRecording ? 2 : 0,
                        )
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        widget.isRouteRecording ? Icons.stop : Icons.directions_run,
                        color: widget.isRouteRecording ? Colors.white : FactionColors.gold,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // 主按鈕 (底座)
        if (widget.hideMainButton)
          const SizedBox(height: 10)
        else
          FloatingActionButton(
            heroTag: 'map_main_fab',
            backgroundColor: widget.factionColor,
            onPressed: _toggle,
            child: AnimatedBuilder(
              animation: _expandAnimation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _expandAnimation.value * 0.75 * 3.14159, // 轉 135 度
                  child: Icon(
                    _isOpen ? Icons.close : Icons.explore,
                    color: Colors.white,
                    size: 26,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
