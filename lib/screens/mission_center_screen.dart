import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';
import 'missions_screen.dart';
import 'leaderboard_screen.dart';

class MissionCenterScreen extends StatelessWidget {
  const MissionCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final textColor = isDarkMode ? FactionColors.textPrimary : Colors.black87;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text('任務中心', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          bottom: TabBar(
            indicatorColor: FactionColors.gold,
            labelColor: isDarkMode ? FactionColors.gold : Colors.black87,
            unselectedLabelColor: isDarkMode ? Colors.white54 : Colors.black54,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            tabs: const [
              Tab(text: '區域任務'),
              Tab(text: '天下排行'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            MissionsScreenBody(),
            LeaderboardScreen(),
          ],
        ),
      ),
    );
  }
}
