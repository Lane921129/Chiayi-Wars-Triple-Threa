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

## 🗄️ 探索諸羅：三國爭霸 — 完整 Firestore 資料庫設計

---

### 一、資料庫架構總覽

```
Firestore
├── users_public/{userId}           ← 公開的玩家資料（任何已登入用戶可讀）
├── users_private/{userId}          ← 私人資料（只有本人可讀寫）
├── missions/{missionId}            ← 任務資料（管理員發布，玩家解任務獲取額外積分）
├── stores/{storeId}                ← 合作商家資料（管理員維護）
├── shop_items/{itemId}             ← 商店道具資料（管理員維護）
├── point_logs/{logId}              ← 積分流水帳（只能新增，不能修改）
├── vouchers/{voucherId}            ← 優惠券（玩家擁有，店家核銷）
├── route_sessions/{sessionId}      ← 跑圖摘要（登入後皆可讀以供好友查看，本機存 GPS 軌跡）
├── achievements/{achievementId}    ← 成就定義（管理員維護）
├── user_achievements/{docId}       ← 玩家已解鎖成就（只可讀寫自己的，不可刪除）
├── app_config/{configId}           ← App 全域設定（管理員維護）
├── friendships/{docId}             ← 社群好友關係（包含兩個人 UID，狀態 pending / accepted）
├── mission_interactions/{docId}    ← 任務互動記錄（簽到與收藏歷史）
├── user_bookmarks/{docId}          ← 使用者收藏書籤（收藏的景點）
└── chats/{chatId}                  ← 聊天頻道與訊息（支援即時通訊，子資料集 messages）
```

> ✅ GPS 原始座標全部存在手機本機（JSON 檔），Firestore 只存摘要，不消耗免費額度。

---

### 二、各 Collection 欄位設計

#### 📁 `users_public/{userId}`
公開的玩家資料，所有已登入用戶可讀取（用於排行榜、地圖渲染）

| 欄位 | 類型 | 說明 |
|---|---|---|
| `displayName` | string | 顯示名稱 |
| `avatarUrl` | string | 頭像 URL（可空） |
| `faction` | string | 陣營：`"red"` / `"green"` / `"blue"` / `""` (未選擇) |
| `factionJoinedAt` | timestamp | 加入陣營時間 |
| `totalScore` | number | 三系積分總和（快取值，用於排行榜） |
| `redScore` | number | 美食紅軍積分 |
| `greenScore` | number | 古蹟綠軍積分 |
| `blueScore` | number | 咖啡藍軍積分 |
| `totalRouteDistance` | number | 累計跑圖距離（公尺） |
| `completedMissions` | array\<string\> | 已完成的任務 ID 清單（防止重複解任務刷分）【新增】 |
| `totalMissionsCompleted` | number | 已完成任務總數（快取，用於成就判斷）【新增】 |
| `createdAt` | timestamp | 帳號建立時間 |

---

#### 📁 `users_private/{userId}`
私人資料，只有本人可讀寫

| 欄位 | 類型 | 說明 |
|---|---|---|
| `email` | string | 登入信箱 |
| `encryptedApiKey` | string | 若需跨裝置同步 API Key 才存這裡，否則只存手機本機 |
| `notificationEnabled` | boolean | 是否開啟通知 |
| `lastLoginAt` | timestamp | 最後登入時間 |
| `isAdmin` | boolean | 是否為管理員（決定能否開啟 App 管理員模式） |
| `preferredLanguage` | string | 偏好語言（`"zh_TW"` / `"en"`，預設 `"zh_TW"`）【新增】 |

---

#### 📁 `missions/{missionId}`
任務地點資料，由管理員建立，玩家唯讀

| 欄位 | 類型 | 說明 |
|---|---|---|
| `name` | string | 任務名稱（如：嘉義舊監獄） |
| `description` | string | 任務描述（200字以內） |
| `lat` | number | 緯度 |
| `lng` | number | 經度 |
| `address` | string | 文字地址（輔助顯示）【新增】 |
| `radiusMeters` | number | 打卡有效半徑（建議 100） |
| `category` | string | `"food"` / `"heritage"` / `"cafe"` |
| `factionBonus` | string | 對應陣營（red/green/blue），任務完成額外加分 |
| `basePoints` | number | 完成任務的基礎積分 |
| `bonusPoints` | number | 對應陣營的額外加分 |
| `imageUrl` | string | 地點圖片 URL |
| `status` | string | `"draft"` (草稿/等待AI發布) / `"active"` (已發布) |
| `aiPublishConditions` | string | 給 AI 的發布條件提示（如：「假日發布」）|
| `totalCheckIns` | number | 累計打卡次數（所有玩家），用於陣營領地計算【新增】 |
| `createdAt` | timestamp | 建立時間【新增】 |
| `createdBy` | string | 建立者 UID（管理員）【新增】 |

---

#### 📁 `stores/{storeId}`
合作商家，由管理員建立，玩家唯讀

| 欄位 | 類型 | 說明 |
|---|---|---|
| `name` | string | 店家名稱 |
| `description` | string | 店家介紹 |
| `lat` | number | 緯度 |
| `lng` | number | 經度 |
| `address` | string | 文字地址【新增】 |
| `phone` | string | 聯絡電話（可空）【新增】 |
| `openHours` | string | 營業時間說明（可空）【新增】 |
| `redeemCode` | string | 核銷代碼（店家輸入用） |
| `discountDescription` | string | 優惠說明（如：消費 9 折） |
| `faction` | string | 對應陣營（或 `"all"` 全陣營可用） |
| `requiredPoints` | number | 兌換所需積分 |
| `voucherValidDays` | number | 優惠券有效天數（兌換後幾天到期）【新增】 |
| `maxVouchersPerUser` | number | 每位玩家最多可兌換幾張（防刷，預設 1）【新增】 |
| `isActive` | boolean | 是否啟用 |
| `imageUrl` | string | 店家圖片 |
| `createdAt` | timestamp | 建立時間【新增】 |

---

#### 📁 `point_logs/{logId}`
積分流水帳，只能新增，不能修改或刪除（防止作弊）

| 欄位 | 類型 | 說明 |
|---|---|---|
| `userId` | string | 玩家 UID |
| `missionId` | string | 關聯任務 ID（打卡時填入；核銷時留空） |
| `storeId` | string | 關聯商家 ID（核銷消費時填入）【新增】 |
| `type` | string | `"earn"` 賺取 / `"spend"` 消費 |
| `faction` | string | 積分歸屬陣營 (red/green/blue) |
| `points` | number | 本次變動積分（正數賺取、負數消費） |
| `reason` | string | 說明（如：完成任務、兌換優惠券） |
| `timestamp` | timestamp | 發生時間（伺服器時間） |

---

#### 📁 `vouchers/{voucherId}`
玩家已兌換的優惠券

| 欄位 | 類型 | 說明 |
|---|---|---|
| `userId` | string | 持有者 UID |
| `storeId` | string | 商家 ID |
| `storeName` | string | 商家名稱（快取，避免多次讀取 stores） |
| `discountDescription` | string | 優惠說明（快取） |
| `requiredPoints` | number | 兌換時消費的積分（快取）【新增】 |
| `faction` | string | 兌換時使用的陣營積分【新增】 |
| `isRedeemed` | boolean | 是否已核銷 |
| `redeemedAt` | timestamp | 核銷時間（未核銷時為 null） |
| `createdAt` | timestamp | 兌換時間 |
| `expiresAt` | timestamp | 有效期限 |

---

#### 📁 `route_sessions/{sessionId}`
**僅存摘要！GPS 原始點存在手機本機。**

| 欄位 | 類型 | 說明 |
|---|---|---|
| `userId` | string | 玩家 UID |
| `startTime` | timestamp | 開始跑圖時間 |
| `endTime` | timestamp | 結束跑圖時間 |
| `durationSeconds` | number | 跑圖總時長（秒） |
| `totalDistanceMeters` | number | 跑圖總距離（公尺） |
| `missionsCompleted` | array\<string\> | 本次完成的任務 ID 清單 |
| `pointsEarned` | number | 本次跑圖獲得的總積分 |
| `localFileName` | string | 手機本機 GPS 檔案名稱（如 `route_abc123.json`） |
| `hasLocalFile` | boolean | 本機檔案是否還存在（用戶刪除後設為 false） |
| `boundingBoxNorth` | number | 路線最北緯度（用於縮圖預覽） |
| `boundingBoxSouth` | number | 路線最南緯度 |
| `boundingBoxEast` | number | 路線最東經度 |
| `boundingBoxWest` | number | 路線最西經度 |

---

#### 📁 `achievements/{achievementId}` 【新增】
成就定義，由管理員建立，玩家唯讀

| 欄位 | 類型 | 說明 |
|---|---|---|
| `name` | string | 成就名稱（如：古蹟初探者） |
| `description` | string | 達成說明（如：完成 3 個古蹟任務） |
| `iconUrl` | string | 成就圖示 URL |
| `condition` | string | 判斷條件類型：`"missions_count"` / `"score_total"` / `"faction_score"` |
| `conditionValue` | number | 達成門檻數值（如：3 個任務） |
| `conditionFaction` | string | 限定陣營（可空，空則通用） |
| `rewardPoints` | number | 解鎖獎勵積分（0 表示無獎勵） |

---

#### 📁 `user_achievements/{docId}` 【新增】
玩家已解鎖的成就（docId = `{userId}_{achievementId}`）

| 欄位 | 類型 | 說明 |
|---|---|---|
| `userId` | string | 玩家 UID |
| `achievementId` | string | 成就 ID |
| `unlockedAt` | timestamp | 解鎖時間 |

---

#### 📁 `app_config/{configId}` 【新增】
App 全域設定，由管理員維護

| 欄位 | 類型 | 說明 |
|---|---|---|
| `aiSchedulerEnabled` | boolean | 是否啟用 AI 自動發布任務排程 |
| `aiSchedulerPrompt` | string | AI 排程使用的系統 Prompt 範本 |
| `maintenanceMode` | boolean | 維護模式（true 時 App 顯示維護中） |
| `maintenanceMessage` | string | 維護公告文字 |
| `version` | string | 目前 App 最低支援版本（可做強制更新）【預備】 |

---

### 三、📱 本機 GPS 檔案格式（存在手機本地，不上雲端）

檔案路徑：`{AppDocumentsDir}/routes/route_{sessionId}.json`

```json
{
  "sessionId": "abc123",
  "recordedAt": "2026-05-18T11:00:00Z",
  "points": [
    { "lat": 23.4789, "lng": 120.4418, "timestamp": 1716026400000, "accuracy": 5.2 },
    { "lat": 23.4791, "lng": 120.4420, "timestamp": 1716026405000, "accuracy": 4.8 }
  ]
}
```

**Flutter 套件推薦：`path_provider` + `dart:io`（直接讀寫 JSON）**

---

### 四、📊 手機端儲存方式總覽

| 儲存方式 | Flutter 套件 | 儲存的資料 | 安全等級 |
|---|---|---|---|
| Secure Storage | `flutter_secure_storage` | Gemini API Key | 🔒 最高（系統 Keychain/Keystore 加密） |
| 本地 JSON 檔 | `path_provider` + `dart:io` | GPS 跑圖軌跡 | 🔓 一般（存於 App 沙盒目錄） |
| SharedPreferences | `shared_preferences` | 通知開關、UI 偏好、暗色模式 | 🔓 一般（純文字鍵值） |

---

### 五、🔐 完整 Security Rules（最終版，含管理員支援）

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // ── 判斷是否為管理員（讀取 users_private 中的 isAdmin 欄位）
    function isAdmin() {
      return request.auth != null &&
        get(/databases/$(database)/documents/users_private/$(request.auth.uid)).data.isAdmin == true;
    }

    // ── 公開玩家資料（排行榜、地圖渲染）
    match /users_public/{userId} {
      allow read: if request.auth != null;
      // 允許本人修改自己的資料，也允許管理員修改（為了寫入虛擬排行榜資料）
      allow write: if (request.auth != null && request.auth.uid == userId) || isAdmin();
    }

    // ── 私人玩家資料（email、isAdmin、API Key 備援）
    match /users_private/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    // ── 打卡地點（管理員可寫，玩家唯讀）
    match /locations/{locationId} {
      allow read: if request.auth != null;
      allow write: if isAdmin();
    }

    // ── 任務地點（管理員可寫，玩家唯讀）
    match /missions/{missionId} {
      allow read: if request.auth != null;
      allow write: if isAdmin();
    }

    // ── 合作商家（管理員可寫，玩家唯讀）
    match /stores/{storeId} {
      allow read: if request.auth != null;
      allow write: if isAdmin();
    }

    // ── 商店道具（管理員可寫，玩家唯讀）
    match /shop_items/{itemId} {
      allow read: if request.auth != null;
      allow write: if isAdmin();
    }

    // ── 積分流水帳（防作弊：只能新增、不能修改刪除）
    match /point_logs/{logId} {
      allow read: if request.auth != null &&
                  request.auth.uid == resource.data.userId;
      allow create: if request.auth != null &&
                    request.auth.uid == request.resource.data.userId &&
                    request.resource.data.points <= 100 &&
                    request.resource.data.timestamp == request.time &&
                    request.resource.data.faction in ['red', 'green', 'blue'];
      allow update, delete: if false;
    }

    // ── 優惠券（只能讀自己的；核銷只能更新兩個欄位）
    match /vouchers/{voucherId} {
      allow read: if request.auth != null &&
                  request.auth.uid == resource.data.userId;
      allow create: if request.auth != null &&
                    request.auth.uid == request.resource.data.userId;
      allow update: if request.auth != null &&
                    request.auth.uid == resource.data.userId &&
                    request.resource.data.diff(resource.data).affectedKeys()
                       .hasOnly(['isRedeemed', 'redeemedAt']);
      allow delete: if false;
    }

    // ── 跑圖摘要（只能寫自己的，登入後皆可讀以供好友查看）
    match /route_sessions/{sessionId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null &&
                    request.auth.uid == request.resource.data.userId;
      allow update: if request.auth != null &&
                    request.auth.uid == resource.data.userId &&
                    request.resource.data.diff(resource.data).affectedKeys()
                       .hasOnly(['hasLocalFile']);
      allow delete: if request.auth != null &&
                    request.auth.uid == resource.data.userId;
    }

    // ── 成就定義（管理員維護，玩家唯讀）
    match /achievements/{achievementId} {
      allow read: if request.auth != null;
      allow write: if isAdmin();
    }

    // ── 玩家已解鎖成就（只能讀寫自己的，不能刪除）
    match /user_achievements/{docId} {
      allow read: if request.auth != null &&
                  request.auth.uid == resource.data.userId;
      allow create: if request.auth != null &&
                    request.auth.uid == request.resource.data.userId;
      allow update, delete: if false;
    }

    // ── App 全域設定（管理員維護，玩家唯讀）
    match /app_config/{configId} {
      allow read: if request.auth != null;
      allow write: if isAdmin();
    }

    // ── 社群功能 ──────────────────────────────────────────────
    match /friendships/{docId} {
      allow read: if request.auth != null && request.auth.uid in resource.data.users;
      allow create: if request.auth != null && request.auth.uid == request.resource.data.requesterId;
      allow update: if request.auth != null && request.auth.uid in resource.data.users;
      allow delete: if request.auth != null && request.auth.uid in resource.data.users;
    }

    match /mission_interactions/{docId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null && request.auth.uid == request.resource.data.userId;
      allow delete: if request.auth != null && request.auth.uid == resource.data.userId;
    }

    match /user_bookmarks/{docId} {
      allow read, write: if request.auth != null && request.auth.uid == request.resource.data.userId;
    }

    match /chats/{chatId} {
      allow read, write: if request.auth != null && request.auth.uid in resource.data.participants;
      
      match /messages/{messageId} {
        allow read: if request.auth != null && request.auth.uid in get(/databases/$(database)/documents/chats/$(chatId)).data.participants;
        allow create: if request.auth != null 
                      && request.auth.uid == request.resource.data.senderId
                      && request.auth.uid in get(/databases/$(database)/documents/chats/$(chatId)).data.participants;
      }
    }
  }
}
```

---

### 六、💰 Firebase 免費額度估算

| 操作 | 免費額度 | 預估用量（本設計）|
|---|---|---|
| Firestore 讀取 | 50,000 次/天 | 輕鬆達標（route_session 只讀摘要）|
| Firestore 寫入 | 20,000 次/天 | 每次打卡寫 1 point_log，很安全 |
| Firestore 儲存 | 1 GB | GPS 不上雲，幾乎不消耗 |
| Storage（圖片）| 5 GB | 地點圖片放 imageUrl 連外部即可 |

**結論：「本機存 GPS、雲端存摘要」設計是最省額度的正確方案。**

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
│   ├── main.dart              # App 入口、Firebase 初始化、各 Service 注入與路由
│   ├── firebase_options.dart  # FlutterFire 設定（自動產生）
│   ├── screens/               # 遊戲 UI 頁面
│   │   ├── login_screen.dart        # 玩家登入與帳號註冊（支援 Google 登入、匿名登入）
│   │   ├── home_screen.dart         # 主導航頁（Map、Missions、Shop、Leaderboard、Profile）
│   │   ├── map_screen.dart          # 核心遊戲地圖（顯示玩家位置、陣營佔領景點、即時快取）
│   │   ├── missions_screen.dart     # 任務景點總覽（顯示加成與狀態，支援打卡）
│   │   ├── shop_screen.dart         # 陣營商店頁面（使用積分換取道具或加成）
│   │   ├── leaderboard_screen.dart  # 排行榜頁面（顯示紅、綠、藍三系積分排行）
│   │   ├── vouchers_screen.dart     # 已兌換的優惠券清單（支援實體店家核銷）
│   │   ├── profile_screen.dart      # 我的主頁（簡潔模式切換、下載快取地圖、好友系統、開發專區）
│   │   ├── friends_screen.dart      # 好友管理面版（我的好友、待處理申請、Email搜尋新增）
│   │   ├── route_history_screen.dart# 跑圖記錄頁面（分頁顯示「我的紀錄」與「好友紀錄」）
│   │   ├── performance_screen.dart  # 跑圖績效分析（軌跡視覺化、統計數據）
│   │   ├── faction_select_screen.dart# 陣營選擇頁面（引導玩家選擇紅、綠、藍軍陣營）
│   │   ├── admin_panel_screen.dart  # 管理員控制面版（手動新增打卡點、任務與合作商家）
│   │   ├── add_location_screen.dart # [管理員] 手動新增打卡點
│   │   ├── add_mission_screen.dart  # [管理員] 手動新增任務
│   │   ├── add_store_screen.dart    # [管理員] 手動新增合作商家
│   │   ├── api_key_screen.dart      # Gemini AI 金鑰設定頁（獨立加密儲存）
│   │   ├── ai_chat_bottom_sheet.dart# AI 景點導覽對話框（透過 Gemini 提供沉浸式導覽）
│   │   └── missions_bottom_sheet.dart# 地圖上景點任務簡短資訊與簽到入口
│   ├── services/              # 商業邏輯與雲端服務層
│   │   ├── auth_service.dart        # 使用者身分驗證與 Firestore 私密資料同步
│   │   ├── friend_service.dart      # 社群好友關係維護、雙向確認流、好友名單 Stream
│   │   ├── ai_service.dart          # 整合 Google Gemini AI 提供智慧導覽與語音合成
│   │   ├── api_key_service.dart     # 管理加密後的 Gemini API 金鑰 (Secure Storage)
│   │   ├── bus_service.dart         # 串接嘉義市即時公車動態 API 與站點定位
│   │   ├── map_cache_service.dart   # OpenStreetMap 離線地圖瓦片下載與快取管理
│   │   ├── seed_service.dart        # [開發人員] 批次上傳測試資料與初始任務種子
│   │   └── weather_service.dart     # 串接嘉義氣象局即時天氣與陣營出戰建議
│   ├── widgets/               # 可複用自訂組件
│   │   ├── multi_fab.dart           # 主地圖多功能浮動操作按鈕
│   │   └── map_multi_fab.dart       # 地圖專屬複合按鈕組件
│   └── theme/                 # 視覺主題與樣式設計
│       ├── app_theme.dart           # 遊戲風暗色/亮色主題與陣營特別配色 (FactionColors)
│       ├── simplified_theme.dart    # 為年長者/純工具用途設計的超清晰簡潔主題
│       └── theme_provider.dart      # 全域主題與簡潔/遊戲模式狀態管理器
├── data/                      # 批次匯入用的嘉義在地資料庫種子
│   ├── missions_chiayi.json   # 嘉義十大人文景點/任務預載資料
│   └── stores_chiayi.json     # 嘉義合作特約特惠商家資料
├── scripts/                   # Firebase 管理與維護運作腳本 (Node.js)
│   ├── backup_firestore.js    # 全庫自動化備份腳本，將資料匯出至本地 data/ JSON
│   ├── restore_firestore.js   # 災後全重建與移機還原腳本
│   ├── upload_missions.js     # 批次重新發布嘉義市任務景點資料
│   ├── upload_stores.js       # 批次重新發布合作商家優惠資料
│   ├── set_admin.js           # 指派特定用戶為超級管理員權限
│   └── package.json           # 運作腳本依賴套件設定
├── firestore.rules            # 經優化且修復重複項的 Firebase 安全性規則
├── firestore.indexes.json      # Firestore 複合索引設定檔
└── firebase.json              # Firebase 部署控制設定檔
```

---

## 👥 社群好友系統 (Friends System)

「探索諸羅：三國爭霸」配備了完整的玩家社群與好友分享功能，增加遊戲趣味性與陣營凝聚力：
- **Email 雙向好友邀請**：玩家可以透過搜尋好友註冊的電子郵件發送好友申請。系統透過 Firebase Firestore 即時雙向同步好友狀態。若雙方皆發出邀請，系統將自動確認為好友。
- **好友申請管理面版**：提供直覺簡便的待處理申請清單，支援一鍵「同意」或「拒絕」好友請求。
- **好友跑圖紀錄共享**：在跑圖記錄中新增「好友的跑圖紀錄」分頁，可隨時查看所有好友上傳的跑圖摘要（包含日期、里程、耗時及獲得積分）。
- **唯讀保護機制**：本人的詳細 GPS 軌跡與敏感檔案儲存在手機本機（不上傳雲端），好友只能查看 Firestore 上的統計與任務摘要，且無法修改或刪除他人的跑圖紀錄，符合 Security Rules 規範。

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
