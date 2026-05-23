import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'api_key_service.dart';

class BusStop {
  final String uid;
  final String name;
  final LatLng position;
  final String routeName;
  final int estimateTime; // in seconds, -1 if no data
  final int stopStatus; // 0: normal, 1: not yet dispatched, 2: intersection, 3: end, 4: not operational

  BusStop({
    required this.uid,
    required this.name,
    required this.position,
    required this.routeName,
    required this.estimateTime,
    required this.stopStatus,
  });
}

class BusService extends ChangeNotifier {
  final ApiKeyService apiKeyService;
  
  List<BusStop> _busStops = [];
  bool _isLoading = false;
  String? _error;
  String? _accessToken;
  DateTime? _tokenExpiry;

  List<BusStop> get busStops => _busStops;
  bool get isLoading => _isLoading;
  String? get error => _error;

  BusService(this.apiKeyService);

  Future<void> fetchBusData() async {
    final clientId = apiKeyService.tdxClientId;
    final clientSecret = apiKeyService.tdxClientSecret;
    
    if (clientId.isEmpty || clientSecret.isEmpty) {
      _error = '尚未設定 TDX API 金鑰';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _ensureAccessToken(clientId, clientSecret);
      
      if (_accessToken == null) {
        throw Exception('無法取得 Access Token');
      }

      // 取得嘉義市公車預估到站資料
      final url = Uri.parse('https://tdx.transportdata.tw/api/basic/v2/Bus/EstimatedTimeOfArrival/City/Chiayi?\$format=JSON');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $_accessToken',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        
        // 取得嘉義市站牌地理位置 (為了畫在地圖上)
        final stopsUrl = Uri.parse('https://tdx.transportdata.tw/api/basic/v2/Bus/Stop/City/Chiayi?\$format=JSON');
        final stopsResponse = await http.get(stopsUrl, headers: {'Authorization': 'Bearer $_accessToken'});
        
        Map<String, LatLng> stopPositions = {};
        if (stopsResponse.statusCode == 200) {
          final List<dynamic> stopsData = jsonDecode(stopsResponse.body);
          for (var stop in stopsData) {
            final uid = stop['StopUID'];
            final lat = stop['StopPosition']['PositionLat'];
            final lon = stop['StopPosition']['PositionLon'];
            stopPositions[uid] = LatLng(lat, lon);
          }
        }

        final List<BusStop> parsedStops = [];
        
        // 解析即時動態並對應座標
        for (var item in data) {
          final stopUid = item['StopUID'];
          final pos = stopPositions[stopUid];
          
          if (pos != null) {
            parsedStops.add(BusStop(
              uid: stopUid,
              name: item['StopName']['Zh_tw'] ?? '未知站牌',
              position: pos,
              routeName: item['RouteName']['Zh_tw'] ?? '未知路線',
              estimateTime: item['EstimateTime'] ?? -1,
              stopStatus: item['StopStatus'] ?? 0,
            ));
          }
        }
        
        // 過濾掉太多重複的站牌 (簡單示範：依 UID 去重)
        final uniqueStops = <String, BusStop>{};
        for (var stop in parsedStops) {
          if (!uniqueStops.containsKey(stop.uid) || stop.estimateTime > 0) {
            uniqueStops[stop.uid] = stop;
          }
        }

        _busStops = uniqueStops.values.toList();
      } else {
        _error = '取得公車資料失敗: ${response.statusCode}';
      }
    } catch (e) {
      _error = '擷取失敗: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _ensureAccessToken(String id, String secret) async {
    if (_accessToken != null && _tokenExpiry != null && DateTime.now().isBefore(_tokenExpiry!)) {
      return; // Token 仍有效
    }

    final url = Uri.parse('https://tdx.transportdata.tw/auth/realms/TDXConnect/protocol/openid-connect/token');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'grant_type': 'client_credentials',
        'client_id': id,
        'client_secret': secret,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _accessToken = data['access_token'];
      final expiresIn = data['expires_in'] as int;
      _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn - 60)); // 提早一分鐘過期
    } else {
      throw Exception('TDX Token 驗證失敗');
    }
  }
}
