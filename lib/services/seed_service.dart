import 'package:cloud_firestore/cloud_firestore.dart';

class SeedService {
  static Future<void> seedLocationsAndMissions({Function(String)? onProgress}) async {
    final firestore = FirebaseFirestore.instance;
    final locationsRef = firestore.collection('locations');
    final missionsRef = firestore.collection('missions');

    onProgress?.call('開始上傳測試資料...\n檢查地圖打卡點...');
    // Check if we already seeded locations
    final existingLocations = await locationsRef.limit(1).get();
    if (existingLocations.docs.isNotEmpty && existingLocations.docs.first.data().containsKey('checkInsByFaction')) {
      // already has data with checkins, but let's just update them anyway to ensure map looks colorful
      final docs = await locationsRef.get();
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
      onProgress?.call('更新舊打卡點顏色完成！');
    }

    onProgress?.call('檢查合作店家與道具...');
    // 1. Seed Shop Items
    final shopRef = firestore.collection('shop_items');
    final existingShop = await shopRef.limit(1).get();
    if (existingShop.docs.isEmpty) {
      final defaultItems = [
        {
          'id': 'energy_drink_1',
          'name': '能量飲料',
          'description': '恢復 50 點體力，讓你跑圖更持久。',
          'price': 100,
          'effectType': 'energy',
        },
        {
          'id': 'score_multiplier_1',
          'name': '分數加倍卡',
          'description': '接下來的 3 次打卡，獲得的分數將提升為 1.5 倍。',
          'price': 300,
          'effectType': 'multiplier',
        },
        {
          'id': 'radar_scan_1',
          'name': '全域雷達',
          'description': '掃描地圖上隱藏的特殊高分任務點。',
          'price': 500,
          'effectType': 'reveal',
        }
      ];
      for (var item in defaultItems) {
        await shopRef.doc(item['id'] as String).set(item);
      }
      onProgress?.call('新增 3 件商店道具！');
    } else {
      onProgress?.call('商店道具已存在，跳過。');
    }

    onProgress?.call('檢查排行榜虛擬玩家...');
    // 2. Seed Dummy Users (for Leaderboard)
    final usersPublicRef = firestore.collection('users_public');
    final existingUsers = await usersPublicRef.where('isDummy', isEqualTo: true).limit(1).get();
    if (existingUsers.docs.isEmpty) {
      final dummyUsers = [
        {'uid': 'dummy_red_1', 'displayName': '嘉義城隍爺', 'faction': 'red', 'totalPoints': 8500, 'isDummy': true},
        {'uid': 'dummy_green_1', 'displayName': '阿里山神木', 'faction': 'green', 'totalPoints': 7200, 'isDummy': true},
        {'uid': 'dummy_blue_1', 'displayName': '噴水池圓環', 'faction': 'blue', 'totalPoints': 9100, 'isDummy': true},
      ];
      for (var u in dummyUsers) {
        await usersPublicRef.doc(u['uid'] as String).set(u);
      }
      onProgress?.call('新增 3 名虛擬玩家！');
    } else {
      onProgress?.call('虛擬玩家已存在，跳過。');
    }

    onProgress?.call('檢查地圖打卡點 (Locations)...');
    // 3. Add default locations (打卡點) around Chiayi if empty
    if (existingLocations.docs.isEmpty) {
      final demoLocations = [
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

      int count = 0;
      for (var loc in demoLocations) {
        await locationsRef.add(loc);
        count++;
        onProgress?.call('新增打卡點: ${loc['name']} ($count/8)');
      }
      onProgress?.call('打卡點上傳完成！');
    } else {
      onProgress?.call('打卡點已存在，跳過上傳。');
    }

    onProgress?.call('清理舊版勢力任務...');
    // 4. Seed Missions (任務)
    // Clean up all old missions entirely for a clean state
    final oldMissions = await missionsRef.get();
    int deleted = 0;
    for (var doc in oldMissions.docs) {
      await doc.reference.delete();
      deleted++;
    }
    if (deleted > 0) onProgress?.call('已清除 $deleted 筆舊版任務！');

    onProgress?.call('開始寫入全新勢力任務...');
    final demoMissions = [
        {
          'name': '嘉義舊監獄巡禮',
          'description': '建於1919年的日式監獄建築，現為國定古蹟，見證諸羅百年歷史。前往舊監獄打卡即可完成任務。',
          'category': 'heritage',
          'factionBonus': 'green',
          'basePoints': 150,
          'bonusPoints': 50,
          'status': 'active',
          'createdAt': FieldValue.serverTimestamp(),
          'imageEmoji': '🏛️',
          'distance': '320m',
          'lat': 23.4845,
          'lng': 120.4615,
        },
        {
          'name': '尋找最棒的雞肉飯',
          'description': '嘉義最具代表性的在地美食。前往任意美食打卡點進行打卡即可。',
          'category': 'food',
          'factionBonus': 'red',
          'basePoints': 100,
          'bonusPoints': 40,
          'status': 'active',
          'createdAt': FieldValue.serverTimestamp(),
          'imageEmoji': '🍜',
          'distance': '180m',
          'lat': 23.4810,
          'lng': 120.4530,
        },
        {
          'name': '午後的咖啡時光',
          'description': '享受悠閒的午後，前往咖啡廳打卡，感受諸羅的慢活步調。',
          'category': 'cafe',
          'factionBonus': 'blue',
          'basePoints': 120,
          'bonusPoints': 45,
          'status': 'active',
          'createdAt': FieldValue.serverTimestamp(),
          'imageEmoji': '☕',
          'distance': '500m',
          'lat': 23.4785,
          'lng': 120.4455,
        },
      ];
      int mCount = 0;
      for (var m in demoMissions) {
        await missionsRef.add(m);
        mCount++;
        onProgress?.call('新增勢力任務: ${m['name']} ($mCount/3)');
      }
      onProgress?.call('勢力任務上傳完成！');
    onProgress?.call('全部上傳處理完畢！');
  }
}
