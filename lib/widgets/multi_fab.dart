import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/simplified_theme.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';

class MultiFab extends StatefulWidget {
  final VoidCallback onShop;
  final VoidCallback onMission;
  final VoidCallback onBackpack;

  const MultiFab({
    super.key,
    required this.onShop,
    required this.onMission,
    required this.onBackpack,
  });

  @override
  State<MultiFab> createState() => _MultiFabState();
}

class _MultiFabState extends State<MultiFab> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
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
  }

  Widget _buildItem(IconData icon, String label, Color color, double dy, VoidCallback onTap) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, dy * (1 - _controller.value)),
          child: Opacity(
            opacity: _controller.value,
            child: child,
          ),
        );
      },
      child: IgnorePointer(
        ignoring: !_isOpen,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: SizedBox(
            width: 48, // Mini FAB size
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
                      color: isDarkMode ? Colors.black54 : Colors.white70,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                  ),
                ),
                FloatingActionButton(
                  heroTag: label,
                  mini: true,
                  backgroundColor: color,
                  onPressed: () {
                    _toggle();
                    onTap();
                  },
                  child: Icon(icon, color: Colors.white),
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
        _buildItem(Icons.card_giftcard, 'Shop (兌換)', FactionColors.redPrimary, 180, widget.onShop),
        _buildItem(Icons.assignment, 'Mission (任務)', FactionColors.greenPrimary, 120, widget.onMission),
        _buildItem(Icons.backpack, 'Backpack (背包)', FactionColors.bluePrimary, 60, widget.onBackpack),
        FloatingActionButton(
          heroTag: 'main_fab',
          backgroundColor: SimplifiedTheme.primary,
          onPressed: _toggle,
          child: AnimatedIcon(
            icon: AnimatedIcons.menu_close,
            progress: _controller,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
