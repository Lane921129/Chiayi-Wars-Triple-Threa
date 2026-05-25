import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/theme_provider.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';

class AddStoreScreen extends StatefulWidget {
  const AddStoreScreen({super.key});

  @override
  State<AddStoreScreen> createState() => _AddStoreScreenState();
}

class _AddStoreScreenState extends State<AddStoreScreen> {
  final _formKey = GlobalKey<FormState>();
  
  String _name = '';
  String _description = '';
  String _address = '';
  String _phone = '';
  String _openHours = '';
  double _lat = 23.4800;
  double _lng = 120.4500;
  String _redeemCode = '';
  String _discountDescription = '';
  String _faction = 'all';
  int _requiredPoints = 500;
  int _voucherValidDays = 7;
  int _maxVouchersPerUser = 1;
  String _imageUrl = '';
  bool _isActive = true;

  bool _isSubmitting = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isSubmitting = true);

    try {
      final docRef = FirebaseFirestore.instance.collection('stores').doc();

      await docRef.set({
        'name': _name,
        'description': _description,
        'address': _address,
        'phone': _phone,
        'openHours': _openHours,
        'lat': _lat,
        'lng': _lng,
        'redeemCode': _redeemCode,
        'discountDescription': _discountDescription,
        'faction': _faction,
        'requiredPoints': _requiredPoints,
        'voucherValidDays': _voucherValidDays,
        'maxVouchersPerUser': _maxVouchersPerUser,
        'imageUrl': _imageUrl,
        'isActive': _isActive,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('店家新增成功！')));
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
        title: const Text('新增合作店家'),
        backgroundColor: Colors.orange,
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
                    decoration: InputDecoration(labelText: '店家名稱', labelStyle: TextStyle(color: textColor)),
                    style: TextStyle(color: textColor),
                    validator: (v) => v!.isEmpty ? '請輸入名稱' : null,
                    onSaved: (v) => _name = v!,
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: '店家介紹', labelStyle: TextStyle(color: textColor)),
                    style: TextStyle(color: textColor),
                    onSaved: (v) => _description = v ?? '',
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
                          decoration: InputDecoration(labelText: '電話', labelStyle: TextStyle(color: textColor)),
                          style: TextStyle(color: textColor),
                          onSaved: (v) => _phone = v ?? '',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          decoration: InputDecoration(labelText: '營業時間', labelStyle: TextStyle(color: textColor)),
                          style: TextStyle(color: textColor),
                          onSaved: (v) => _openHours = v ?? '',
                        ),
                      ),
                    ],
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
                  TextFormField(
                    decoration: InputDecoration(labelText: '核銷代碼 (店家輸入用)', labelStyle: TextStyle(color: textColor)),
                    style: TextStyle(color: textColor),
                    validator: (v) => v!.isEmpty ? '請設定核銷代碼' : null,
                    onSaved: (v) => _redeemCode = v!,
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: '優惠說明 (如: 飲品 9 折)', labelStyle: TextStyle(color: textColor)),
                    style: TextStyle(color: textColor),
                    validator: (v) => v!.isEmpty ? '請輸入優惠說明' : null,
                    onSaved: (v) => _discountDescription = v!,
                  ),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(labelText: '對應陣營', labelStyle: TextStyle(color: textColor)),
                    dropdownColor: isDarkMode ? FactionColors.cardBg : Colors.white,
                    style: TextStyle(color: textColor),
                    initialValue: _faction,
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('全陣營通用 (All)')),
                      DropdownMenuItem(value: 'red', child: Text('紅軍 (美食)')),
                      DropdownMenuItem(value: 'green', child: Text('綠軍 (古蹟)')),
                      DropdownMenuItem(value: 'blue', child: Text('藍軍 (咖啡)')),
                    ],
                    onChanged: (v) => setState(() => _faction = v!),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          decoration: InputDecoration(labelText: '兌換所需積分', labelStyle: TextStyle(color: textColor)),
                          style: TextStyle(color: textColor),
                          keyboardType: TextInputType.number,
                          initialValue: '500',
                          validator: (v) => int.tryParse(v!) == null ? '無效數字' : null,
                          onSaved: (v) => _requiredPoints = int.parse(v!),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          decoration: InputDecoration(labelText: '有效天數', labelStyle: TextStyle(color: textColor)),
                          style: TextStyle(color: textColor),
                          keyboardType: TextInputType.number,
                          initialValue: '7',
                          validator: (v) => int.tryParse(v!) == null ? '無效數字' : null,
                          onSaved: (v) => _voucherValidDays = int.parse(v!),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          decoration: InputDecoration(labelText: '每人上限(張)', labelStyle: TextStyle(color: textColor)),
                          style: TextStyle(color: textColor),
                          keyboardType: TextInputType.number,
                          initialValue: '1',
                          validator: (v) => int.tryParse(v!) == null ? '無效數字' : null,
                          onSaved: (v) => _maxVouchersPerUser = int.parse(v!),
                        ),
                      ),
                    ],
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: '圖片 URL', labelStyle: TextStyle(color: textColor)),
                    style: TextStyle(color: textColor),
                    onSaved: (v) => _imageUrl = v ?? '',
                  ),
                  SwitchListTile(
                    title: Text('是否啟用', style: TextStyle(color: textColor)),
                    value: _isActive,
                    activeThumbColor: Colors.orange,
                    onChanged: (bool value) {
                      setState(() {
                        _isActive = value;
                      });
                    },
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                    onPressed: _submit,
                    child: const Text('新增合作店家', style: TextStyle(fontSize: 18)),
                  ),
                ],
              ),
            ),
    );
  }
}
