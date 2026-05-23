import 'package:cloud_firestore/cloud_firestore.dart';

class SeedService {
  static Future<void> seedMissions() async {
    final firestore = FirebaseFirestore.instance;
    final missionsRef = firestore.collection('missions');

    // Check if we already seeded
    final existing = await missionsRef.limit(1).get();
    if (existing.docs.isNotEmpty && existing.docs.first.data().containsKey('checkInsByFaction')) {
      // already has data with checkins, but let's just update them anyway to ensure map looks colorful
      final docs = await missionsRef.get();
      for (var doc in docs.docs) {
        final category = doc.data()['category'] as String?;
        int r = 0, g = 0, b = 0;
        
        // bias based on category to make them colorful
        if (category == 'food') {
          r = 20; g = 5; b = 2;
        } else if (category == 'heritage') {
          r = 2; g = 15; b = 3;
        } else if (category == 'cafe') {
          r = 4; g = 2; b = 18;
        } else {
          r = 10; g = 10; b = 10;
        }

        await doc.reference.update({
          'checkInsByFaction': {
            'red': r,
            'green': g,
            'blue': b,
          },
          'totalCheckIns': r + g + b,
        });
      }
      return;
    }

    // Add some default missions around Chiayi if empty
    final demoMissions = [
      {
        'name': '林聰明沙鍋魚頭',
        'category': 'food',
        'lat': 23.4795,
        'lng': 120.4495,
        'basePoints': 100,
        'status': 'active',
        'totalCheckIns': 45,
        'checkInsByFaction': {'red': 30, 'green': 10, 'blue': 5},
      },
      {
        'name': '嘉義文化創意產業園區',
        'category': 'heritage',
        'lat': 23.4750,
        'lng': 120.4410,
        'basePoints': 150,
        'status': 'active',
        'totalCheckIns': 20,
        'checkInsByFaction': {'red': 2, 'green': 15, 'blue': 3},
      },
      {
        'name': '阿里山森林鐵路車庫園區',
        'category': 'heritage',
        'lat': 23.4860,
        'lng': 120.4460,
        'basePoints': 200,
        'status': 'active',
        'totalCheckIns': 30,
        'checkInsByFaction': {'red': 5, 'green': 20, 'blue': 5},
      },
      {
        'name': '嘉義公園',
        'category': 'heritage',
        'lat': 23.4820,
        'lng': 120.4630,
        'basePoints': 100,
        'status': 'active',
        'totalCheckIns': 40,
        'checkInsByFaction': {'red': 10, 'green': 25, 'blue': 5},
      },
      {
        'name': '文化路夜市',
        'category': 'food',
        'lat': 23.4790,
        'lng': 120.4490,
        'basePoints': 120,
        'status': 'active',
        'totalCheckIns': 60,
        'checkInsByFaction': {'red': 40, 'green': 10, 'blue': 10},
      },
      {
        'name': '老院子 1951',
        'category': 'cafe',
        'lat': 23.4815,
        'lng': 120.4550,
        'basePoints': 150,
        'status': 'active',
        'totalCheckIns': 35,
        'checkInsByFaction': {'red': 5, 'green': 5, 'blue': 25},
      },
      {
        'name': '昭和十一咖啡館',
        'category': 'cafe',
        'lat': 23.4830,
        'lng': 120.4625,
        'basePoints': 180,
        'status': 'active',
        'totalCheckIns': 25,
        'checkInsByFaction': {'red': 2, 'green': 3, 'blue': 20},
      },
      {
        'name': '劉里長火雞肉飯',
        'category': 'food',
        'lat': 23.4798,
        'lng': 120.4520,
        'basePoints': 110,
        'status': 'active',
        'totalCheckIns': 55,
        'checkInsByFaction': {'red': 35, 'green': 15, 'blue': 5},
      },
    ];

    for (var m in demoMissions) {
      await missionsRef.add(m);
    }
  }
}
