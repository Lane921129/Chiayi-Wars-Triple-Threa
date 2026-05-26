import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'api_key_service.dart';

class UbikeStation {
  final String uid;
  final String name;
  final LatLng position;
  final int availableBikes;
  final int availableReturns;
  final int status; // 1: normal, 0: suspended, 2: not operational

  UbikeStation({
    required this.uid,
    required this.name,
    required this.position,
    required this.availableBikes,
    required this.availableReturns,
    required this.status,
  });
}

class UbikeService extends ChangeNotifier {
  final ApiKeyService apiKeyService;
  
  List<UbikeStation> _stations = [];
  bool _isLoading = false;
  String? _error;
  String? _accessToken;
  DateTime? _tokenExpiry;

  List<UbikeStation> get stations => _stations;
  bool get isLoading => _isLoading;
  String? get error => _error;

  UbikeService(this.apiKeyService);

  Future<void> fetchUbikeData() async {
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

      // Fetch station positions and names
      final stationUrl = Uri.parse('https://tdx.transportdata.tw/api/basic/v2/Bike/Station/City/Chiayi?\$format=JSON');
      final stationResponse = await http.get(
        stationUrl,
        headers: {'Authorization': 'Bearer $_accessToken'},
      );

      // Fetch station availability (bikes and docks)
      final availabilityUrl = Uri.parse('https://tdx.transportdata.tw/api/basic/v2/Bike/Availability/City/Chiayi?\$format=JSON');
      final availabilityResponse = await http.get(
        availabilityUrl,
        headers: {'Authorization': 'Bearer $_accessToken'},
      );

      if (stationResponse.statusCode == 200 && availabilityResponse.statusCode == 200) {
        final List<dynamic> stationData = jsonDecode(stationResponse.body);
        final List<dynamic> availabilityData = jsonDecode(availabilityResponse.body);
        
        // Build availability map for quick lookup
        Map<String, Map<String, dynamic>> availabilityMap = {};
        for (var item in availabilityData) {
          availabilityMap[item['StationUID']] = {
            'AvailableRentBikes': item['AvailableRentBikes'] ?? 0,
            'AvailableReturnBikes': item['AvailableReturnBikes'] ?? 0,
            'ServiceStatus': item['ServiceStatus'] ?? 0, // 1 is normal
          };
        }

        final List<UbikeStation> parsedStations = [];
        
        for (var station in stationData) {
          final uid = station['StationUID'];
          final name = station['StationName']['Zh_tw'] ?? '未知站點';
          final lat = station['StationPosition']['PositionLat'];
          final lon = station['StationPosition']['PositionLon'];
          
          final avail = availabilityMap[uid] ?? {
            'AvailableRentBikes': 0,
            'AvailableReturnBikes': 0,
            'ServiceStatus': 2,
          };

          parsedStations.add(UbikeStation(
            uid: uid,
            name: name,
            position: LatLng(lat, lon),
            availableBikes: avail['AvailableRentBikes'],
            availableReturns: avail['AvailableReturnBikes'],
            status: avail['ServiceStatus'],
          ));
        }

        _stations = parsedStations;
      } else {
        _error = '取得 UBike 資料失敗';
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
      return; 
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
      _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn - 60)); 
    } else {
      throw Exception('TDX Token 驗證失敗');
    }
  }
}
