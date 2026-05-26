import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'api_key_service.dart';

class BusRouteData {
  final String routeName;
  final String geometry; // WKT MULTILINESTRING from TDX
  final List<BusStopData> stops;

  BusRouteData({
    required this.routeName,
    required this.geometry,
    required this.stops,
  });
}

class BusStopData {
  final String uid;
  final String name;
  final LatLng position;
  final int sequence;
  final Map<String, List<String>> schedules;

  BusStopData({
    required this.uid,
    required this.name,
    required this.position,
    required this.sequence,
    this.schedules = const {},
  });
}

class BusService extends ChangeNotifier {
  final ApiKeyService apiKeyService;
  
  List<BusRouteData> _routes = [];
  bool _isLoading = false;
  String? _error;
  String? _accessToken;
  DateTime? _tokenExpiry;

  List<BusRouteData> get routes => _routes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  BusService(this.apiKeyService);

  // 1. 從 Firestore 讀取靜態公車資料 (供一般使用者使用，不耗 TDX 額度)
  Future<void> fetchBusData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final snapshot = await FirebaseFirestore.instance.collection('bus_routes').get();
      final List<BusRouteData> parsedRoutes = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final List<dynamic> stopsRaw = data['stops'] ?? [];
        
        final List<BusStopData> stops = stopsRaw.map((s) {
          final schedulesRaw = s['schedules'] as Map<String, dynamic>? ?? {};
          final Map<String, List<String>> schedules = {};
          schedulesRaw.forEach((k, v) {
            if (v is List) schedules[k] = v.map((e) => e.toString()).toList();
          });

          return BusStopData(
            uid: s['uid'] ?? '',
            name: s['name'] ?? '',
            position: LatLng((s['lat'] as num).toDouble(), (s['lng'] as num).toDouble()),
            sequence: s['sequence'] ?? 0,
            schedules: schedules,
          );
        }).toList();
        
        stops.sort((a, b) => a.sequence.compareTo(b.sequence));

        parsedRoutes.add(BusRouteData(
          routeName: data['routeName'] ?? '未知路線',
          geometry: data['geometry'] ?? '',
          stops: stops,
        ));
      }
      
      _routes = parsedRoutes;
    } catch (e) {
      _error = '讀取公車資料失敗: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 2. 透過 TDX 抓取最新資料並上傳至 Firestore (僅限管理員使用)
  Future<void> syncBusDataToFirestore() async {
    final clientId = apiKeyService.tdxClientId;
    final clientSecret = apiKeyService.tdxClientSecret;
    
    if (clientId.isEmpty || clientSecret.isEmpty) {
      throw Exception('尚未設定 TDX API 金鑰');
    }

    _isLoading = true;
    notifyListeners();

    try {
      await _ensureAccessToken(clientId, clientSecret);
      
      // 取得路線形狀 (Geometry)
      final shapeUrl = Uri.parse('https://tdx.transportdata.tw/api/basic/v2/Bus/Shape/City/Chiayi?\$format=JSON');
      final shapeRes = await http.get(shapeUrl, headers: {'Authorization': 'Bearer $_accessToken'});
      
      // 取得路線站序 (StopOfRoute)
      final stopsUrl = Uri.parse('https://tdx.transportdata.tw/api/basic/v2/Bus/StopOfRoute/City/Chiayi?\$format=JSON');
      final stopsRes = await http.get(stopsUrl, headers: {'Authorization': 'Bearer $_accessToken'});

      // 取得班表 (Schedule)
      final scheduleUrl = Uri.parse('https://tdx.transportdata.tw/api/basic/v2/Bus/Schedule/City/Chiayi?\$format=JSON');
      final scheduleRes = await http.get(scheduleUrl, headers: {'Authorization': 'Bearer $_accessToken'});

      if (shapeRes.statusCode == 200 && stopsRes.statusCode == 200 && scheduleRes.statusCode == 200) {
        final List<dynamic> shapeData = jsonDecode(shapeRes.body);
        final List<dynamic> stopsData = jsonDecode(stopsRes.body);
        final List<dynamic> scheduleData = jsonDecode(scheduleRes.body);

        Map<String, String> geometries = {};
        for (var shape in shapeData) {
          final routeName = shape['RouteName']['Zh_tw'];
          final geometry = shape['Geometry'];
          geometries[routeName] = geometry;
        }

        // 解析班表資料
        Map<String, Map<String, Map<String, List<String>>>> routeStopSchedules = {};
        for (var sRoute in scheduleData) {
          final routeName = sRoute['RouteName']['Zh_tw'];
          routeStopSchedules[routeName] ??= {};
          
          final timetables = sRoute['Timetables'] as List<dynamic>? ?? [];
          for (var t in timetables) {
            final serviceDay = t['ServiceDay'] ?? {};
            List<String> activeDays = [];
            if (serviceDay['Monday'] == 1) activeDays.add('1');
            if (serviceDay['Tuesday'] == 1) activeDays.add('2');
            if (serviceDay['Wednesday'] == 1) activeDays.add('3');
            if (serviceDay['Thursday'] == 1) activeDays.add('4');
            if (serviceDay['Friday'] == 1) activeDays.add('5');
            if (serviceDay['Saturday'] == 1) activeDays.add('6');
            if (serviceDay['Sunday'] == 1) activeDays.add('7');

            final stopTimes = t['StopTimes'] as List<dynamic>? ?? [];
            for (var st in stopTimes) {
              final stopUid = st['StopUID'];
              final depTime = st['DepartureTime'] ?? st['ArrivalTime'];
              if (depTime == null) continue;
              
              String timeStr = depTime.toString().substring(0, 5); // 取得 HH:mm
              
              routeStopSchedules[routeName]![stopUid] ??= {};
              for (var day in activeDays) {
                routeStopSchedules[routeName]![stopUid]![day] ??= [];
                if (!routeStopSchedules[routeName]![stopUid]![day]!.contains(timeStr)) {
                  routeStopSchedules[routeName]![stopUid]![day]!.add(timeStr);
                }
              }
            }
          }
        }
        
        // 將時間排序
        routeStopSchedules.forEach((routeName, stops) {
          stops.forEach((stopUid, days) {
            days.forEach((day, times) {
              times.sort();
            });
          });
        });

        Map<String, List<Map<String, dynamic>>> routeStops = {};
        for (var route in stopsData) {
          final routeName = route['RouteName']['Zh_tw'];
          final stops = route['Stops'] as List<dynamic>;
          
          List<Map<String, dynamic>> parsedStops = stops.map((s) {
            final stopUid = s['StopUID'];
            return {
              'uid': stopUid,
              'name': s['StopName']['Zh_tw'],
              'lat': s['StopPosition']['PositionLat'],
              'lng': s['StopPosition']['PositionLon'],
              'sequence': s['StopSequence'],
              'schedules': routeStopSchedules[routeName]?[stopUid] ?? {},
            };
          }).toList();
          
          // 如果有多個方向 (Direction 0/1)，簡單起見我們合併或只取 Direction 0
          // 這裡我們直接覆寫，保留最後一個方向的站點，或可根據需求調整。
          routeStops[routeName] = parsedStops;
        }

        // 上傳至 Firestore
        final collectionRef = FirebaseFirestore.instance.collection('bus_routes');
        
        // 先清空舊資料
        final oldDocs = await collectionRef.get();
        
        // 分批執行 (Firestore batch limit is 500)
        List<WriteBatch> batches = [FirebaseFirestore.instance.batch()];
        int operationCount = 0;
        
        void addOperation(void Function(WriteBatch) op) {
          if (operationCount >= 450) {
            batches.add(FirebaseFirestore.instance.batch());
            operationCount = 0;
          }
          op(batches.last);
          operationCount++;
        }

        for (var doc in oldDocs.docs) {
          addOperation((b) => b.delete(doc.reference));
        }

        // 寫入新資料
        for (var routeName in routeStops.keys) {
          final docRef = collectionRef.doc();
          addOperation((b) => b.set(docRef, {
            'routeName': routeName,
            'geometry': geometries[routeName] ?? '',
            'stops': routeStops[routeName],
            'updatedAt': FieldValue.serverTimestamp(),
          }));
        }

        for (var b in batches) {
          if (operationCount > 0 || batches.length > 1) {
            await b.commit();
          }
        }
        await fetchBusData(); // 重新讀取本地狀態
      } else {
        throw Exception('TDX API 請求失敗');
      }
    } catch (e) {
      _error = '同步失敗: $e';
      throw Exception(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _ensureAccessToken(String id, String secret) async {
    if (_accessToken != null && _tokenExpiry != null && DateTime.now().isBefore(_tokenExpiry!)) {
      return;
    }

    final url = Uri.parse('https://tdx.transportdata.tw/auth/realms/TDXConnect/protocol/openid-connect/token');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'grant_type': 'client_credentials', 'client_id': id, 'client_secret': secret},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _accessToken = data['access_token'];
      final expiresIn = data['expires_in'] as int;
      _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn - 60));
    } else {
      throw Exception('TDX Token 驗證失敗');
    }
  }
}
