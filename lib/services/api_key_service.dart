import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiKeyService extends ChangeNotifier {
  static const String _cwaKeyPref = 'cwa_api_key';
  static const String _tdxIdPref = 'tdx_client_id';
  static const String _tdxSecretPref = 'tdx_client_secret';
  static const String _geminiKeyPref = 'gemini_api_key';

  String _cwaKey = '';
  String _tdxClientId = '';
  String _tdxClientSecret = '';
  String _geminiKey = '';

  String get cwaKey => _cwaKey;
  String get tdxClientId => _tdxClientId;
  String get tdxClientSecret => _tdxClientSecret;
  String get geminiKey => _geminiKey;

  ApiKeyService() {
    _loadKeys();
  }

  Future<void> _loadKeys() async {
    final prefs = await SharedPreferences.getInstance();
    // 如果沒有設定過，就使用預設的使用者提供金鑰
    _cwaKey = prefs.getString(_cwaKeyPref) ?? 'CWA-452D624D-8575-4637-A3B4-623979108A7C';
    _tdxClientId = prefs.getString(_tdxIdPref) ?? 's1122965-51b51f9e-67a1-4a10';
    _tdxClientSecret = prefs.getString(_tdxSecretPref) ?? '96635a58-dfd2-4d63-a023-1f8dc10b5de6';
    _geminiKey = prefs.getString(_geminiKeyPref) ?? 'gen-lang-client-0752674216';
    notifyListeners();
  }

  Future<void> saveKeys({
    required String cwa,
    required String tdxId,
    required String tdxSecret,
    required String gemini,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cwaKeyPref, cwa);
    await prefs.setString(_tdxIdPref, tdxId);
    await prefs.setString(_tdxSecretPref, tdxSecret);
    await prefs.setString(_geminiKeyPref, gemini);
    
    _cwaKey = cwa;
    _tdxClientId = tdxId;
    _tdxClientSecret = tdxSecret;
    _geminiKey = gemini;
    notifyListeners();
  }
}
