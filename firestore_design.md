# 🗄️ 探索諸羅：三國爭霸 — 完整 Firestore 資料庫設計

---

## 一、資料庫架構總覽

```
Firestore
├── users_public/{userId}         ← 公開的玩家資料（任何人可讀）
├── users_private/{userId}        ← 私人資料（只有本人可讀寫）
├── missions/{missionId}          ← 任務地點資料（唯讀，後台維護）
├── stores/{storeId}              ← 合作商家資料（唯讀，後台維護）
├── point_logs/{logId}            ← 積分流水帳（只能新增，不能修改）
├── vouchers/{voucherId}          ← 優惠券（玩家擁有，店家核銷）
└── route_sessions/{sessionId}    ← 跑圖摘要（本機存 GPS 點，雲端存摘要）
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
| `faction` | string | 陣營：`"red"` / `"green"` / `"blue"` |
| `factionJoinedAt` | timestamp | 加入陣營時間 |
| `totalScore` | number | 三系積分總和（快取值，用於排行榜） |
| `redScore` | number | 美食紅軍積分 |
| `greenScore` | number | 古蹟綠軍積分 |
| `blueScore` | number | 咖啡藍軍積分 |
| `totalRouteDistance` | number | 累計跑圖距離（公尺） |
| `createdAt` | timestamp | 帳號建立時間 |

---

### 📁 `users_private/{userId}`
私人資料，只有本人可讀寫

| 欄位 | 類型 | 說明 |
|---|---|---|
| `email` | string | 登入信箱 |
| `encryptedApiKey` | string | 建議存在手機本機 (flutter_secure_storage)，若需跨裝置才存這裡 |
| `notificationEnabled` | boolean | 是否開啟通知 |
| `lastLoginAt` | timestamp | 最後登入時間 |
| `isAdmin` | boolean | 是否為管理員（決定能否開啟 App 管理員模式） |

---

### 📁 `missions/{missionId}`
任務地點資料，由管理員建立，玩家唯讀

| 欄位 | 類型 | 說明 |
|---|---|---|
| `name` | string | 任務名稱（如：嘉義舊監獄） |
| `description` | string | 任務描述 |
| `lat` | number | 緯度 |
| `lng` | number | 經度 |
| `radiusMeters` | number | 打卡有效半徑（建議 100） |
| `category` | string | `"food"` / `"heritage"` / `"cafe"` |
| `factionBonus` | string | 對應陣營（red/green/blue），任務完成額外加分 |
| `basePoints` | number | 完成任務的基礎積分 |
| `bonusPoints` | number | 對應陣營的額外加分 |
| `imageUrl` | string | 地點圖片 URL |
| `status` | string | `"draft"` (草稿/等待AI發布) / `"active"` (已發布) |
| `aiPublishConditions` | string | 給 AI 的發布條件提示（例如：「假日發布」）|

---

### 📁 `stores/{storeId}`
合作商家，由管理員建立，玩家唯讀

| 欄位 | 類型 | 說明 |
|---|---|---|
| `name` | string | 店家名稱 |
| `description` | string | 店家介紹 |
| `lat` | number | 緯度 |
| `lng` | number | 經度 |
| `redeemCode` | string | 核銷代碼（店家輸入用） |
| `discountDescription` | string | 優惠說明（如：消費 9 折） |
| `faction` | string | 對應陣營（或 `"all"` 全陣營可用） |
| `requiredPoints` | number | 兌換所需積分 |
| `isActive` | boolean | 是否啟用 |
| `imageUrl` | string | 店家圖片 |

---

### 📁 `point_logs/{logId}`
積分流水帳，只能新增，不能修改或刪除（防止作弊）

| 欄位 | 類型 | 說明 |
|---|---|---|
| `userId` | string | 玩家 UID |
| `missionId` | string | 關聯任務 ID（可空，如核銷時無任務） |
| `type` | string | `"earn"` 賺取 / `"spend"` 消費 |
| `faction` | string | 積分歸屬陣營 (red/green/blue) |
| `points` | number | 本次變動積分（賺取為正、消費為負） |
| `reason` | string | 說明（如：完成任務、兌換優惠券） |
| `timestamp` | timestamp | 發生時間 |

---

### 📁 `vouchers/{voucherId}`
玩家已兌換的優惠券

| 欄位 | 類型 | 說明 |
|---|---|---|
| `userId` | string | 持有者 UID |
| `storeId` | string | 商家 ID |
| `storeName` | string | 商家名稱（快取） |
| `discountDescription` | string | 優惠說明（快取） |
| `isRedeemed` | boolean | 是否已核銷 |
| `redeemedAt` | timestamp | 核銷時間（可空） |
| `createdAt` | timestamp | 兌換時間 |
| `expiresAt` | timestamp | 有效期限 |

---

### 📁 `route_sessions/{sessionId}` ← 新增（跑圖功能）
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

### 📱 本機 GPS 檔案格式（存在手機本地，不上雲端）

檔案路徑：`{AppDocumentsDir}/routes/route_{sessionId}.json`

```json
{
  "sessionId": "abc123",
  "recordedAt": "2026-05-18T11:00:00Z",
  "points": [
    { "lat": 23.4789, "lng": 120.4418, "timestamp": 1716026400000, "accuracy": 5.2 },
    { "lat": 23.4791, "lng": 120.4420, "timestamp": 1716026405000, "accuracy": 4.8 },
    ...
  ]
}
```

**Flutter 套件推薦：`path_provider` + `dart:io`（直接讀寫 JSON）**

---

## 三、完整 Security Rules（正式版）

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // ── 公開玩家資料 ──────────────────────────────────────────────
    match /users_public/{userId} {
      // 任何已登入用戶可讀（排行榜、地圖顯示需要）
      allow read: if request.auth != null;
      // 只有本人可以寫自己的資料
      allow write: if request.auth.uid == userId;
    }

    // ── 私人玩家資料 ──────────────────────────────────────────────
    match /users_private/{userId} {
      // 只有本人可讀寫
      allow read, write: if request.auth.uid == userId;
    }

    // ── 任務資料（唯讀，只有後台能建立）─────────────────────────
    match /missions/{missionId} {
      allow read: if request.auth != null;
      allow write: if false; // 前端禁止寫入，只有 Admin SDK 可以
    }

    // ── 商家資料（唯讀）──────────────────────────────────────────
    match /stores/{storeId} {
      allow read: if request.auth != null;
      allow write: if false;
    }

    // ── 積分流水帳 ────────────────────────────────────────────────
    match /point_logs/{logId} {
      // 只能讀自己的記錄
      allow read: if request.auth.uid == resource.data.userId;
      // 只能新增，不能修改或刪除（防作弊）
      allow create: if request.auth.uid == request.resource.data.userId
                    && request.resource.data.timestamp == request.time;
      allow update, delete: if false;
    }

    // ── 優惠券 ────────────────────────────────────────────────────
    match /vouchers/{voucherId} {
      // 只能讀自己的優惠券
      allow read: if request.auth.uid == resource.data.userId;
      // 只能建立自己名下的優惠券
      allow create: if request.auth.uid == request.resource.data.userId;
      // 只允許更新 isRedeemed 和 redeemedAt 欄位（核銷）
      allow update: if request.auth.uid == resource.data.userId
                    && request.resource.data.diff(resource.data).affectedKeys()
                       .hasOnly(['isRedeemed', 'redeemedAt']);
      allow delete: if false;
    }

    // ── 跑圖摘要 ─────────────────────────────────────────────────
    match /route_sessions/{sessionId} {
      // 只能讀自己的跑圖記錄
      allow read: if request.auth.uid == resource.data.userId;
      // 只能建立自己名下的記錄
      allow create: if request.auth.uid == request.resource.data.userId;
      // 只允許更新 hasLocalFile（本機刪除後同步狀態）
      allow update: if request.auth.uid == resource.data.userId
                    && request.resource.data.diff(resource.data).affectedKeys()
                       .hasOnly(['hasLocalFile']);
      allow delete: if request.auth.uid == resource.data.userId;
    }
  }
}
```

---


## 五、Firebase 免費額度估算

| 操作 | 免費額度 | 預估用量（本設計）|
|---|---|---|
| Firestore 讀取 | 50,000 次/天 | 輕鬆達標（route_session 只讀摘要）|
| Firestore 寫入 | 20,000 次/天 | 每次打卡寫 1 point_log，很安全 |
| Firestore 儲存 | 1 GB | GPS 不上雲，幾乎不消耗 |
| Storage（圖片）| 5 GB | 地點圖片放 imageUrl 連外部即可 |

**結論：你的「本機存 GPS、雲端存摘要」設計是最省額度的正確方案。**

---

## 六、部署指令

```bash
# 1. 在專案根目錄建立 firestore.rules 檔案（貼上上方 Rules）

# 2. 部署 Security Rules 到 Firebase
firebase deploy --only firestore:rules

# 3. 確認部署成功
firebase firestore:rules:get
```
