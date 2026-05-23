# 🏯 探索諸羅：三國爭霸

> 一款結合 GPS 定位、陣營佔領與 Gemini AI 導覽的嘉義在地旅遊遊戲化 App

---

## 📱 專案簡介

「探索諸羅：三國爭霸」是一款以嘉義市區為舞台的 Flutter 旅遊 App，將觀光探索轉化為三個歷史陣營（美食紅、古蹟綠、咖啡藍）的領地佔領遊戲。玩家實地走訪景點打卡、累積積分，並可兌換合作商家優惠券，串聯虛擬成就與實體消費。

**技術棧**：Flutter + Firebase + OpenStreetMap + Google Gemini AI

---

## 🚀 快速開始

### 1. 環境需求
- Flutter SDK `≥ 3.11.0`
- Node.js `≥ 18.0.0`（用於 Firebase 管理腳本）
- Firebase CLI (`npm install -g firebase-tools`)

### 2. 安裝 Flutter 依賴
```bash
flutter pub get
```

### 3. Firebase 設定

#### 3a. 取得 `google-services.json`（Android）
1. 前往 [Firebase Console](https://console.firebase.google.com/) → 選擇專案 `turkey-5b3f5`
2. 專案設定 → Android App → 下載 `google-services.json`
3. 將檔案放到 `android/app/google-services.json`

#### 3b. 取得 `GoogleService-Info.plist`（iOS，若需要）
1. 同上，選擇 iOS App → 下載 `GoogleService-Info.plist`
2. 將檔案放到 `ios/Runner/GoogleService-Info.plist`

#### 3c. 重新產生 `firebase_options.dart`（若有需要）
```bash
# 安裝 FlutterFire CLI
dart pub global activate flutterfire_cli

# 重新設定（選擇 turkey-5b3f5 專案）
flutterfire configure
```

### 4. 部署 Firestore Security Rules
```bash
firebase deploy --only firestore:rules
```

### 5. 執行 App
```bash
flutter run
```

---

## 🗄️ 資料庫設計

詳見 [`firestore_design.md`](./firestore_design.md)

### Collection 速覽

| Collection | 說明 |
|---|---|
| `users_public` | 公開玩家資料（排行榜用） |
| `users_private` | 私人資料（email、isAdmin 權限） |
| `missions` | 任務景點（管理員維護） |
| `stores` | 合作商家（管理員維護） |
| `point_logs` | 積分流水帳（防作弊，不可修改） |
| `vouchers` | 玩家優惠券 |
| `route_sessions` | 跑圖摘要 |
| `achievements` | 成就定義 |
| `user_achievements` | 玩家已解鎖成就 |
| `app_config` | App 全域設定 |

---

## 📦 批次上傳 / 備份 / 還原

### 事前準備：取得 Firebase Admin SDK 金鑰

1. Firebase Console → 專案設定 → **服務帳戶**
2. 點擊「產生新的私密金鑰」→ 下載 JSON
3. 將檔案命名為 `serviceAccountKey.json` 並放到 `scripts/` 目錄下
4. ⚠️ 此檔案已在 `.gitignore` 中，**絕對不要 commit 到 GitHub**

### 安裝腳本依賴
```bash
cd scripts
npm install
```

### 批次上傳任務資料
```bash
# 上傳 data/missions_chiayi.json 到 Firestore
npm run upload:missions

# 上傳 data/stores_chiayi.json 到 Firestore
npm run upload:stores

# 一次上傳全部
npm run upload:all
```

### 備份 Firestore 資料
```bash
# 備份所有 Collection 到 data/backup_YYYYMMDD_HHMMSS/
npm run backup
```

### 從備份還原資料（重建雲端）
```bash
# 從指定備份目錄還原
node scripts/restore_firestore.js --from data/backup_20260523_090000
```

---

## 📱 手機端資料儲存

| 儲存方式 | 資料 | 加密 |
|---|---|---|
| `flutter_secure_storage` | Gemini API Key | ✅ Keychain/Keystore |
| 本機 JSON 檔 | GPS 跑圖原始軌跡 | ❌（App 沙盒內） |
| SharedPreferences | 通知開關、UI 偏好 | ❌ |

本機 GPS 檔案位置：`{AppDocumentsDir}/routes/route_{sessionId}.json`

---

## 🔐 安全性說明

- `firebase_options.dart` 的 API Key 是 **公開設計**，不構成安全風險（受 Firebase Security Rules 保護）
- 真正敏感的 `google-services.json` 和 `GoogleService-Info.plist` 已加入 `.gitignore`
- Admin SDK 金鑰 `serviceAccountKey.json` **絕對不可 commit**
- Firestore Security Rules 確保用戶只能讀寫自己的資料

---

## 📁 專案結構

```
untitled3/
├── lib/
│   ├── main.dart              # App 入口、Firebase 初始化、Auth Wrapper
│   ├── firebase_options.dart  # FlutterFire 設定（自動產生）
│   ├── screens/               # UI 頁面
│   │   ├── login_screen.dart
│   │   ├── home_screen.dart
│   │   ├── map_screen.dart
│   │   ├── missions_screen.dart
│   │   ├── vouchers_screen.dart
│   │   ├── profile_screen.dart
│   │   └── ...
│   ├── services/              # Firebase 服務層
│   │   └── auth_service.dart
│   └── theme/                 # App 主題設計
│       └── app_theme.dart
├── data/                      # 批次上傳用的資料
│   ├── missions_chiayi.json   # 嘉義任務景點資料
│   └── stores_chiayi.json     # 嘉義合作商家資料
├── scripts/                   # Firebase 管理腳本 (Node.js)
│   ├── upload_missions.js     # 批次上傳任務
│   ├── upload_stores.js       # 批次上傳商家
│   ├── backup_firestore.js    # 備份所有資料
│   ├── restore_firestore.js   # 從備份還原
│   └── package.json
├── firestore.rules            # Firestore 安全規則
├── firestore_design.md        # 資料庫設計文件
└── firebase.json              # Firebase 部署設定
```

---

## 👥 組員分工

| 姓名 | 負責 |
|---|---|
| 連智弘 | 系統邏輯、AI 串接、遊戲機制 |
| 陳韋如 | Flutter UI / UX、狀態管理 |
| 蔡秉勳 | Firebase 後端、資料庫、Security Rules |

---

## 📚 參考資料

- [Flutter 官方文件](https://flutter.dev/docs)
- [Firebase 開發者文件](https://firebase.google.com/docs)
- [flutter_map (OSM)](https://docs.fleaflet.dev/)
- [Google Gemini API](https://ai.google.dev/docs)
