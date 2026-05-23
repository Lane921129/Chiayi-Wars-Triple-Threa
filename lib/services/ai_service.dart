import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'api_key_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}

class AiService extends ChangeNotifier {
  final ApiKeyService apiKeyService;
  
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _error;

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;

  AiService(this.apiKeyService) {
    _messages.add(ChatMessage(text: '你好！我是諸羅小嚮導，有什麼關於嘉義的歷史故事或任務想問我的嗎？', isUser: false));
  }

  void clearMessages() {
    _messages.clear();
    _messages.add(ChatMessage(text: '你好！我是諸羅小嚮導，有什麼關於嘉義的歷史故事或任務想問我的嗎？', isUser: false));
    notifyListeners();
  }

  Future<void> sendMessage(String text, {String? contextPrompt}) async {
    final key = apiKeyService.geminiKey;
    if (key.isEmpty) {
      _error = '尚未設定 Gemini API Key，請至設定頁面輸入。';
      _messages.add(ChatMessage(text: '錯誤：$_error', isUser: false));
      notifyListeners();
      return;
    }

    _messages.add(ChatMessage(text: text, isUser: true));
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: key,
        systemInstruction: Content.system('你是一個名為「諸羅小嚮導」的 AI 導覽員，專門介紹嘉義市的歷史、美食與文化。你的語氣應該要像是一位古代的謀士或將軍，有時候會帶點三國演義的幽默感。回覆請盡量簡短有力。'),
      );

      final prompt = contextPrompt != null ? '背景資訊：$contextPrompt\n\n玩家問題：$text' : text;
      final response = await model.generateContent([Content.text(prompt)]);

      if (response.text != null) {
        _messages.add(ChatMessage(text: response.text!, isUser: false));
      } else {
        _messages.add(ChatMessage(text: '小嚮導似乎有點暈眩，無法回答...', isUser: false));
      }
    } catch (e) {
      _error = 'AI 連線失敗: $e';
      _messages.add(ChatMessage(text: '連線發生錯誤，請檢查網路或 API Key 是否正確。', isUser: false));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
