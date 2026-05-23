import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_key_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';

class ApiKeyScreen extends StatefulWidget {
  const ApiKeyScreen({super.key});

  @override
  State<ApiKeyScreen> createState() => _ApiKeyScreenState();
}

class _ApiKeyScreenState extends State<ApiKeyScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _cwaController;
  late TextEditingController _tdxIdController;
  late TextEditingController _tdxSecretController;
  late TextEditingController _geminiController;

  @override
  void initState() {
    super.initState();
    final apiKeyService = Provider.of<ApiKeyService>(context, listen: false);
    _cwaController = TextEditingController(text: apiKeyService.cwaKey);
    _tdxIdController = TextEditingController(text: apiKeyService.tdxClientId);
    _tdxSecretController = TextEditingController(text: apiKeyService.tdxClientSecret);
    _geminiController = TextEditingController(text: apiKeyService.geminiKey);
  }

  @override
  void dispose() {
    _cwaController.dispose();
    _tdxIdController.dispose();
    _tdxSecretController.dispose();
    _geminiController.dispose();
    super.dispose();
  }

  void _saveKeys() async {
    if (_formKey.currentState!.validate()) {
      final apiKeyService = Provider.of<ApiKeyService>(context, listen: false);
      await apiKeyService.saveKeys(
        cwa: _cwaController.text.trim(),
        tdxId: _tdxIdController.text.trim(),
        tdxSecret: _tdxSecretController.text.trim(),
        gemini: _geminiController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('API Keys 儲存成功！')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Key 設定'),
        backgroundColor: isDarkMode ? FactionColors.bgDark : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : Colors.black,
      ),
      backgroundColor: isDarkMode ? FactionColors.bgDark : Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('天氣服務 (中央氣象署 CWA)'),
              _buildTextField(_cwaController, 'CWA API Key', isDarkMode),
              const SizedBox(height: 24),
              
              _buildSectionTitle('公車動態 (交通部 TDX)'),
              _buildTextField(_tdxIdController, 'TDX Client ID', isDarkMode),
              const SizedBox(height: 12),
              _buildTextField(_tdxSecretController, 'TDX Client Secret', isDarkMode),
              const SizedBox(height: 24),
              
              _buildSectionTitle('AI 導覽 (Google Gemini)'),
              _buildTextField(_geminiController, 'Gemini API Key', isDarkMode),
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveKeys,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FactionColors.gold,
                    foregroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('儲存設定', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          color: FactionColors.gold,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, bool isDarkMode) {
    return TextFormField(
      controller: controller,
      style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black54),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: isDarkMode ? Colors.white24 : Colors.black26),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: FactionColors.gold),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
