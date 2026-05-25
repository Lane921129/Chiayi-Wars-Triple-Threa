import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/theme_provider.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';

class AddLocationScreen extends StatefulWidget {
  const AddLocationScreen({super.key});

  @override
  State<AddLocationScreen> createState() => _AddLocationScreenState();
}

class _AddLocationScreenState extends State<AddLocationScreen> {
  final _formKey = GlobalKey<FormState>();
  
  String _name = '';
  String _address = '';
  double _lat = 23.4800;
  double _lng = 120.4500;
  String _category = 'food';
  int _basePoints = 100;
  String _factionBonus = 'red';
  int _radiusMeters = 100;
  String _imageUrl = '';
  String _status = 'active';

  bool _isSubmitting = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final docRef = FirebaseFirestore.instance.collection('locations').doc();

      await docRef.set({
        'name': _name,
        'address': _address,
        'lat': _lat,
        'lng': _lng,
        'category': _category,
        'basePoints': _basePoints,
        'factionBonus': _factionBonus,
        'radiusMeters': _radiusMeters,
        'imageUrl': _imageUrl,
        'status': _status,
        'totalCheckIns': 0,
        'checkInsByFaction': {
          'red': 0,
          'green': 0,
          'blue': 0,
        },
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': user?.uid ?? 'unknown',
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('打卡點新增成功！')));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('錯誤: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final textColor = isDarkMode ? FactionColors.textPrimary : Colors.black87;

    return Scaffold(
      appBar: AppBar(
        title: const Text('新增打卡點 (Locations)'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      backgroundColor: isDarkMode ? FactionColors.darkBg : const Color(0xFFF5F5F5),
      body: _isSubmitting
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  TextFormField(
                    decoration: InputDecoration(labelText: '打卡點名稱', labelStyle: TextStyle(color: textColor)),
                    style: TextStyle(color: textColor),
                    validator: (v) => v!.isEmpty ? '請輸入名稱' : null,
                    onSaved: (v) => _name = v!,
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: '地址', labelStyle: TextStyle(color: textColor)),
                    style: TextStyle(color: textColor),
                    onSaved: (v) => _address = v ?? '',
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          decoration: InputDecoration(labelText: '緯度 (Lat)', labelStyle: TextStyle(color: textColor)),
                          style: TextStyle(color: textColor),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          initialValue: '23.4800',
                          validator: (v) => double.tryParse(v!) == null ? '無效數字' : null,
                          onSaved: (v) => _lat = double.parse(v!),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          decoration: InputDecoration(labelText: '經度 (Lng)', labelStyle: TextStyle(color: textColor)),
                          style: TextStyle(color: textColor),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          initialValue: '120.4500',
                          validator: (v) => double.tryParse(v!) == null ? '無效數字' : null,
                          onSaved: (v) => _lng = double.parse(v!),
                        ),
                      ),
                    ],
                  ),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(labelText: '分類', labelStyle: TextStyle(color: textColor)),
                    dropdownColor: isDarkMode ? FactionColors.cardBg : Colors.white,
                    style: TextStyle(color: textColor),
                    initialValue: _category,
                    items: const [
                      DropdownMenuItem(value: 'food', child: Text('美食 (Food)')),
                      DropdownMenuItem(value: 'heritage', child: Text('古蹟 (Heritage)')),
                      DropdownMenuItem(value: 'cafe', child: Text('咖啡 (Cafe)')),
                    ],
                    onChanged: (v) => setState(() => _category = v!),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          decoration: InputDecoration(labelText: '基礎積分', labelStyle: TextStyle(color: textColor)),
                          style: TextStyle(color: textColor),
                          keyboardType: TextInputType.number,
                          initialValue: '100',
                          validator: (v) => int.tryParse(v!) == null ? '無效數字' : null,
                          onSaved: (v) => _basePoints = int.parse(v!),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          decoration: InputDecoration(labelText: '打卡半徑 (公尺)', labelStyle: TextStyle(color: textColor)),
                          style: TextStyle(color: textColor),
                          keyboardType: TextInputType.number,
                          initialValue: '100',
                          validator: (v) => int.tryParse(v!) == null ? '無效數字' : null,
                          onSaved: (v) => _radiusMeters = int.parse(v!),
                        ),
                      ),
                    ],
                  ),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(labelText: '對應陣營加成', labelStyle: TextStyle(color: textColor)),
                    dropdownColor: isDarkMode ? FactionColors.cardBg : Colors.white,
                    style: TextStyle(color: textColor),
                    initialValue: _factionBonus,
                    items: const [
                      DropdownMenuItem(value: 'red', child: Text('紅軍 (美食)')),
                      DropdownMenuItem(value: 'green', child: Text('綠軍 (古蹟)')),
                      DropdownMenuItem(value: 'blue', child: Text('藍軍 (咖啡)')),
                      DropdownMenuItem(value: 'all', child: Text('無 (通用)')),
                    ],
                    onChanged: (v) => setState(() => _factionBonus = v!),
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: '圖片 URL', labelStyle: TextStyle(color: textColor)),
                    style: TextStyle(color: textColor),
                    onSaved: (v) => _imageUrl = v ?? '',
                  ),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(labelText: '狀態', labelStyle: TextStyle(color: textColor)),
                    dropdownColor: isDarkMode ? FactionColors.cardBg : Colors.white,
                    style: TextStyle(color: textColor),
                    initialValue: _status,
                    items: const [
                      DropdownMenuItem(value: 'active', child: Text('直接發布 (Active)')),
                      DropdownMenuItem(value: 'draft', child: Text('草稿 (Draft)')),
                    ],
                    onChanged: (v) => setState(() => _status = v!),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                    onPressed: _submit,
                    child: const Text('新增打卡點', style: TextStyle(fontSize: 18)),
                  ),
                ],
              ),
            ),
    );
  }
}
