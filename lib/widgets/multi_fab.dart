import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/simplified_theme.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';

class MultiFab extends StatefulWidget {
  final VoidCallback onShop;
  final VoidCallback onMission;
  final VoidCallback onBackpack;
  final Color factionColor;
  final ValueChanged<bool>? onToggle;

  const MultiFab({
    super.key,
    required this.onShop,
    required this.onMission,
    required this.onBackpack,
    required this.factionColor,
    this.onToggle,
  });

  @override
  State<MultiFab> createState() => _MultiFabState();
}

class _MultiFabState extends State<MultiFab> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
    if (widget.onToggle != null) {
      widget.onToggle!(_isOpen);
    }
  }

  Widget _buildItem(IconData icon, String label, Color color, double dy, VoidCallback onTap, {Color iconColor = Colors.white}) {
    final isDarkMode = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    return AnimatedBuilder(
      animation: _expandAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, dy * (1 - _expandAnimation.value)),
          child: Opacity(
            opacity: _expandAnimation.value,
            child: child,
          ),
        );
      },
      child: IgnorePointer(
        ignoring: !_isOpen,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Positioned(
                  right: 60, // 48 + 12px margin
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.black87 : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: color.withValues(alpha: 0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
                FloatingActionButton(
                  heroTag: 'simplified_$label',
                  mini: true,
                  backgroundColor: color,
                  onPressed: () {
                    _toggle();
                    onTap();
                  },
                  child: Icon(icon, color: iconColor, size: 22),
                ),
              ],
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 1. Shop
        _buildItem(Icons.card_giftcard, 'Shop (商店兌換)', FactionColors.redPrimary, 180, widget.onShop),
        
        // 2. Mission
        _buildItem(Icons.assignment, 'Mission (任務列表)', FactionColors.greenPrimary, 120, widget.onMission),
        
        // 3. Backpack
        _buildItem(Icons.backpack, 'Backpack (我的背包)', FactionColors.bluePrimary, 60, widget.onBackpack),
        
        // 主按鈕 (大底座)
        FloatingActionButton(
          heroTag: 'simplified_main_fab',
          backgroundColor: SimplifiedTheme.primary,
          onPressed: _toggle,
          child: AnimatedBuilder(
            animation: _expandAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _expandAnimation.value * 0.75 * 3.14159, // 轉 135 度
                child: Icon(
                  _isOpen ? Icons.close : Icons.menu,
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
