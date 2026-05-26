import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import '../theme/app_theme.dart';
import 'add_mission_screen.dart';
import 'add_location_screen.dart';
import 'add_store_screen.dart';
import '../services/bus_service.dart' as bus_service;

class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('管理員專區'),
        backgroundColor: Colors.deepPurpleAccent,
        foregroundColor: Colors.white,
      ),
      backgroundColor: isDarkMode ? FactionColors.darkBg : const Color(0xFFF5F5F5),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              '資料管理',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          Card(
            color: isDarkMode ? FactionColors.cardBg : Colors.white,
            child: ListTile(
              leading: const Icon(Icons.assignment, color: Colors.blue),
              title: Text('新增勢力任務', style: TextStyle(color: isDarkMode ? FactionColors.textPrimary : Colors.black87)),
              subtitle: Text('發布給各陣營玩家解題的任務', style: TextStyle(color: isDarkMode ? FactionColors.textSecondary : Colors.black54)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AddMissionScreen()));
              },
            ),
          ),
          const SizedBox(height: 8),
          Card(
            color: isDarkMode ? FactionColors.cardBg : Colors.white,
            child: ListTile(
              leading: const Icon(Icons.add_location_alt, color: Colors.green),
              title: Text('新增打卡點', style: TextStyle(color: isDarkMode ? FactionColors.textPrimary : Colors.black87)),
              subtitle: Text('建立地圖上的新據點供玩家爭奪', style: TextStyle(color: isDarkMode ? FactionColors.textSecondary : Colors.black54)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AddLocationScreen()));
              },
            ),
          ),
          const SizedBox(height: 8),
          Card(
            color: isDarkMode ? FactionColors.cardBg : Colors.white,
            child: ListTile(
              leading: const Icon(Icons.storefront, color: Colors.orange),
              title: Text('新增合作店家', style: TextStyle(color: isDarkMode ? FactionColors.textPrimary : Colors.black87)),
              subtitle: Text('建立新的特約商家與優惠券兌換', style: TextStyle(color: isDarkMode ? FactionColors.textSecondary : Colors.black54)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AddStoreScreen()));
              },
            ),
          ),
          const SizedBox(height: 8),
          Consumer<bus_service.BusService>(
            builder: (context, busService, child) {
              return Card(
                color: isDarkMode ? FactionColors.cardBg : Colors.white,
                child: ListTile(
                  leading: busService.isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator())
                      : const Icon(Icons.directions_bus, color: Colors.blueAccent),
                  title: Text('同步公車資料至雲端', style: TextStyle(color: isDarkMode ? FactionColors.textPrimary : Colors.black87)),
                  subtitle: Text('從 TDX 抓取最新路線與軌跡並覆寫至 Firestore', style: TextStyle(color: isDarkMode ? FactionColors.textSecondary : Colors.black54)),
                  trailing: const Icon(Icons.sync),
                  onTap: busService.isLoading ? null : () async {
                    try {
                      await busService.syncBusDataToFirestore();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('同步公車資料成功！')));
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('同步失敗：$e')));
                      }
                    }
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
