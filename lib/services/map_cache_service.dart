import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';

class MapCacheService extends ChangeNotifier {
  static const String storeName = 'chiayi_store';

  // 嘉義市的 Bounding Box (大約範圍)
  final BaseRegion _chiayiRegion = RectangleRegion(
    LatLngBounds(
      const LatLng(23.44, 120.41), // 西南角
      const LatLng(23.52, 120.50), // 東北角
    ),
  );

  bool _isDownloading = false;
  bool get isDownloading => _isDownloading;

  int _downloadedTiles = 0;
  int _totalTilesToDownload = 0;
  int get downloadedTiles => _downloadedTiles;
  int get totalTilesToDownload => _totalTilesToDownload;

  double get downloadProgress => _totalTilesToDownload == 0 
      ? 0.0 
      : (_downloadedTiles / _totalTilesToDownload).clamp(0.0, 1.0);

  FMTCStore get _store => FMTCStore(storeName);

  Future<void> startDownload() async {
    if (_isDownloading) return;
    
    _isDownloading = true;
    _downloadedTiles = 0;
    _totalTilesToDownload = 0;
    notifyListeners();

    try {
      final store = _store;
      // 確保 Store 存在
      await store.manage.create();

      final downloadableRegion = _chiayiRegion.toDownloadable(
        minZoom: 13,
        maxZoom: 17,
        options: TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.zhuluo_app',
        ),
      );

      // 計算總瓦片數 (針對 Zoom Level 13~17)
      final count = await store.download.countTiles(downloadableRegion);
      _totalTilesToDownload = count;
      notifyListeners();

      if (count == 0) {
        _isDownloading = false;
        notifyListeners();
        return;
      }

      // 開始下載
      final (:downloadProgress, :tileEvents) = store.download.startForeground(
        region: downloadableRegion,
        parallelThreads: 2, // 限速：最多 2 個併發請求，保護免費伺服器
      );

      downloadProgress.listen((prog) {
        _downloadedTiles = prog.successfulTilesCount;
        notifyListeners();
      }, onDone: () {
        _isDownloading = false;
        notifyListeners();
      }, onError: (e) {
        _isDownloading = false;
        print("Download error: $e");
        notifyListeners();
      });

    } catch (e) {
      _isDownloading = false;
      print("Error initiating download: $e");
      notifyListeners();
    }
  }

  // 取得目前 Store 的統計資訊
  Future<Map<String, dynamic>> getStoreStats() async {
    final store = _store;
    if (!await store.manage.ready) return {'count': 0, 'size': 0};
    
    final stats = await store.stats.all;
    return {
      'count': stats.length,
      'size': stats.size, // bytes
    };
  }

  // 清除快取 (刪除 Store 後重建)
  Future<void> clearCache() async {
    try {
      final store = _store;
      await store.manage.delete();
      await store.manage.create();
      _downloadedTiles = 0;
      _totalTilesToDownload = 0;
      notifyListeners();
    } catch (e) {
      print("Error clearing cache: $e");
    }
  }
}
