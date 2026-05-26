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
  
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _error;

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // 嘗試的模型清單（依照優先序排列）
  static const _modelCandidates = [
    'models/gemini-1.5-flash',
    'gemini-1.5-flash',
    'models/gemini-1.5-pro',
    'models/gemini-2.5-flash',
    'gemini-2.5-flash',
  ];

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
      _error = '尚未設定 Gemini API Key';
      _messages.add(ChatMessage(
        text: '❌ 尚未設定 Gemini API Key，請點選上方「前往設定」按鈕輸入你的金鑰。',
        isUser: false,
      ));
      notifyListeners();
      return;
    }

    _messages.add(ChatMessage(text: text, isUser: true));
    _isLoading = true;
    _error = null;
    notifyListeners();

    final prompt = contextPrompt != null ? '背景資訊：$contextPrompt\n\n玩家問題：$text' : text;
    
    List<String> diagErrors = [];
    for (final modelName in _modelCandidates) {
      try {
        final model = GenerativeModel(
          model: modelName,
          apiKey: key,
          systemInstruction: Content.system('你是一個名為「諸羅小嚮導」的 AI 導覽員，專門介紹嘉義市的歷史、美食與文化。請使用友善、現代的語氣，可以帶有微量的歷史典故，但不要過度使用文言文。如果玩家要求安排行程，請務必使用條列式或表格，明確標示「時間、地點、活動內容」，提供具體且順暢的嘉義市旅遊路線。回覆請盡量排版清晰、實用且簡短有力。'),
        );
        final response = await model.generateContent([Content.text(prompt)]);

        if (response.text != null) {
          _messages.add(ChatMessage(text: response.text!, isUser: false));
          _isLoading = false;
          notifyListeners();
          return; // 成功，直接 return
        }
      } catch (e) {
        diagErrors.add('[$modelName] 錯誤：$e');
      }
    }

    // 所有模型都失敗
    String maskedKey = key.length > 8 ? '${key.substring(0, 4)}...${key.substring(key.length - 4)}' : key;
    String errorMsg = diagErrors.join('\n');
    _error = '連線失敗';
    _messages.add(ChatMessage(
      text: '❌ 所有 AI 模型都連線失敗。\n\n🔑 目前讀取的金鑰為: $maskedKey (長度: ${key.length})\n\n詳細錯誤報表：\n$errorMsg\n\n請至 Google AI Studio 確認金鑰有效並開通 Gemini API。',
      isUser: false,
    ));
    _isLoading = false;
    notifyListeners();
  }
}
