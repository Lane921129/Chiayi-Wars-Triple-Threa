import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'api_key_service.dart';

class WeatherData {
  final String description; // Wx
  final String maxTemp; // MaxT
  final String minTemp; // MinT
  final String pop; // PoP (Probability of Precipitation)

  WeatherData({
    required this.description,
    required this.maxTemp,
    required this.minTemp,
    required this.pop,
  });
}

class WeatherService extends ChangeNotifier {
  final ApiKeyService apiKeyService;
  WeatherData? _currentWeather;
  bool _isLoading = false;
  String? _error;

  WeatherData? get currentWeather => _currentWeather;
  bool get isLoading => _isLoading;
  String? get error => _error;

  WeatherService(this.apiKeyService) {
    // 監聽 ApiKeyService 變化，若更新了 Key 則重新抓取
    apiKeyService.addListener(_fetchWeather);
    _fetchWeather();
  }

  @override
  void dispose() {
    apiKeyService.removeListener(_fetchWeather);
    super.dispose();
  }

  Future<void> _fetchWeather() async {
    final key = apiKeyService.cwaKey;
    if (key.isEmpty) {
      _error = '尚未設定氣象 API Key';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final url = Uri.parse(
          'https://opendata.cwa.gov.tw/api/v1/rest/datastore/F-C0032-001?Authorization=$key&locationName=嘉義市');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final locations = data['records']['location'] as List;
        if (locations.isNotEmpty) {
          final chiayi = locations[0];
          final weatherElements = chiayi['weatherElement'] as List;
          
          String getElement(String name) {
            final element = weatherElements.firstWhere((e) => e['elementName'] == name, orElse: () => null);
            return element?['time'][0]['parameter']['parameterName'] ?? '';
          }

          _currentWeather = WeatherData(
            description: getElement('Wx'),
            maxTemp: getElement('MaxT'),
            minTemp: getElement('MinT'),
            pop: getElement('PoP'),
          );
        } else {
          _error = '找不到嘉義市天氣資料';
        }
      } else {
        _error = '連線失敗 (${response.statusCode})';
      }
    } catch (e) {
      _error = '擷取失敗: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
