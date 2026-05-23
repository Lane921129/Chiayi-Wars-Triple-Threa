# 🗄️ 探索諸羅：三國爭霸 — 完整 Firestore 資料庫設計

---

## 一、資料庫架構總覽

```
Firestore
├── users_public/{userId}           ← 公開的玩家資料（任何已登入用戶可讀）
├── users_private/{userId}          ← 私人資料（只有本人可讀寫）
├── missions/{missionId}            ← 任務地點資料（管理員維護）
├── stores/{storeId}                ← 合作商家資料（管理員維護）
├── point_logs/{logId}              ← 積分流水帳（只能新增，不能修改）
├── vouchers/{voucherId}            ← 優惠券（玩家擁有，店家核銷）
├── route_sessions/{sessionId}      ← 跑圖摘要（本機存 GPS 點，雲端存摘要）
├── achievements/{achievementId}    ← 成就定義（管理員維護）【新增】
├── user_achievements/{docId}       ← 玩家已解鎖成就（玩家讀寫）【新增】
└── app_config/{configId}           ← App 全域設定（管理員維護）【新增】
```

> ✅ GPS 原始座標全部存在手機本機（JSON 檔），Firestore 只存摘要，不消耗免費額度。

---

## 二、各 Collection 欄位設計

### 📁 `users_public/{userId}`
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

### 📁 `users_private/{userId}`
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

### 📁 `missions/{missionId}`
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

### 📁 `stores/{storeId}`
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

### 📁 `point_logs/{logId}`
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

### 📁 `vouchers/{voucherId}`
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

### 📁 `route_sessions/{sessionId}`
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

### 📁 `achievements/{achievementId}` 【新增】
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

### 📁 `user_achievements/{docId}` 【新增】
玩家已解鎖的成就（docId = `{userId}_{achievementId}`）

| 欄位 | 類型 | 說明 |
|---|---|---|
| `userId` | string | 玩家 UID |
| `achievementId` | string | 成就 ID |
| `unlockedAt` | timestamp | 解鎖時間 |

---

### 📁 `app_config/{configId}` 【新增】
App 全域設定，由管理員維護

| 欄位 | 類型 | 說明 |
|---|---|---|
| `aiSchedulerEnabled` | boolean | 是否啟用 AI 自動發布任務排程 |
| `aiSchedulerPrompt` | string | AI 排程使用的系統 Prompt 範本 |
| `maintenanceMode` | boolean | 維護模式（true 時 App 顯示維護中） |
| `maintenanceMessage` | string | 維護公告文字 |
| `version` | string | 目前 App 最低支援版本（可做強制更新）【預備】 |

---

## 三、📱 本機 GPS 檔案格式（存在手機本地，不上雲端）

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

## 四、📊 手機端儲存方式總覽

| 儲存方式 | Flutter 套件 | 儲存的資料 | 安全等級 |
|---|---|---|---|
| Secure Storage | `flutter_secure_storage` | Gemini API Key | 🔒 最高（系統 Keychain/Keystore 加密） |
| 本地 JSON 檔 | `path_provider` + `dart:io` | GPS 跑圖軌跡 | 🔓 一般（存於 App 沙盒目錄） |
| SharedPreferences | `shared_preferences` | 通知開關、UI 偏好、暗色模式 | 🔓 一般（純文字鍵值） |

---

## 五、🔐 完整 Security Rules（最終版，含管理員支援）

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // 判斷是否為管理員
    function isAdmin() {
      return request.auth != null &&
        get(/databases/$(database)/documents/users_private/$(request.auth.uid)).data.isAdmin == true;
    }

    match /users_public/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }

    match /users_private/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    match /missions/{missionId} {
      allow read: if request.auth != null;
      allow write: if isAdmin();
    }

    match /stores/{storeId} {
      allow read: if request.auth != null;
      allow write: if isAdmin();
    }

    match /point_logs/{logId} {
      allow read: if request.auth != null && request.auth.uid == resource.data.userId;
      allow create: if request.auth != null
                    && request.auth.uid == request.resource.data.userId
                    && request.resource.data.points <= 100
                    && request.resource.data.timestamp == request.time
                    && request.resource.data.faction in ['red', 'green', 'blue'];
      allow update, delete: if false;
    }

    match /vouchers/{voucherId} {
      allow read: if request.auth != null && request.auth.uid == resource.data.userId;
      allow create: if request.auth != null && request.auth.uid == request.resource.data.userId;
      allow update: if request.auth != null
                    && request.auth.uid == resource.data.userId
                    && request.resource.data.diff(resource.data).affectedKeys()
                       .hasOnly(['isRedeemed', 'redeemedAt']);
      allow delete: if false;
    }

    match /route_sessions/{sessionId} {
      allow read: if request.auth != null && request.auth.uid == resource.data.userId;
      allow create: if request.auth != null && request.auth.uid == request.resource.data.userId;
      allow update: if request.auth != null
                    && request.auth.uid == resource.data.userId
                    && request.resource.data.diff(resource.data).affectedKeys()
                       .hasOnly(['hasLocalFile']);
      allow delete: if request.auth != null && request.auth.uid == resource.data.userId;
    }

    match /achievements/{achievementId} {
      allow read: if request.auth != null;
      allow write: if isAdmin();
    }

    match /user_achievements/{docId} {
      allow read: if request.auth != null && request.auth.uid == resource.data.userId;
      allow create: if request.auth != null && request.auth.uid == request.resource.data.userId;
      allow update, delete: if false;
    }

    match /app_config/{configId} {
      allow read: if request.auth != null;
      allow write: if isAdmin();
    }
  }
}
```

---

## 六、💰 Firebase 免費額度估算

| 操作 | 免費額度 | 預估用量（本設計）|
|---|---|---|
| Firestore 讀取 | 50,000 次/天 | 輕鬆達標（route_session 只讀摘要）|
| Firestore 寫入 | 20,000 次/天 | 每次打卡寫 1 point_log，很安全 |
| Firestore 儲存 | 1 GB | GPS 不上雲，幾乎不消耗 |
| Storage（圖片）| 5 GB | 地點圖片放 imageUrl 連外部即可 |

**結論：「本機存 GPS、雲端存摘要」設計是最省額度的正確方案。**

---

## 七、🔄 資料重建與備份流程

### 批次上傳（新增 / 更新任務資料）
```bash
# 安裝依賴
cd scripts && npm install

# 上傳任務資料
node upload_missions.js

# 上傳商家資料
node upload_stores.js
```

### 備份所有資料到本地
```bash
node scripts/backup_firestore.js
# 輸出到 data/backup_YYYYMMDD/
```

### 從備份還原（重建雲端資料）
```bash
node scripts/restore_firestore.js --from data/backup_20260523/
```

---

## 八、🚀 部署指令

```bash
# 部署 Security Rules 到 Firebase
firebase deploy --only firestore:rules

# 確認部署成功
firebase firestore:rules:get
```
