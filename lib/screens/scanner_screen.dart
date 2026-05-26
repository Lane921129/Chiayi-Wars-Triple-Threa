import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';

class ScannerScreen extends StatefulWidget {
  final Map<String, dynamic> missionData;
  const ScannerScreen({super.key, required this.missionData});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController controller = MobileScannerController();
  bool _isScanned = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isScanned) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        final code = barcode.rawValue!;
        // 假設 QR Code 內容格式是 missionId: <id>
        final expectedCode = 'mission:${widget.missionData['id']}';
        if (code == expectedCode) {
          _isScanned = true;
          Navigator.pop(context, true); // 回傳 true 代表掃描成功
          break;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('無效的 QR Code 或非此任務的 QR Code')),
          );
          // 加上延遲避免瘋狂觸發
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) setState(() => _isScanned = false);
          });
          _isScanned = true;
          break;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('掃描打卡'),
        backgroundColor: isDarkMode ? Colors.black : Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: _onDetect,
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.greenAccent, width: 4),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.flash_on),
                label: const Text('⚡ 點此模擬掃描成功 (測試專用)', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                ),
                onPressed: () {
                  if (!_isScanned) {
                    _isScanned = true;
                    Navigator.pop(context, true);
                  }
                },
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Text(
              '請將鏡頭對準任務 QR Code',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                backgroundColor: Colors.black.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
