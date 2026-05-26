# 探索諸羅：三國爭霸 - 資料庫與資料處理架構說明

## 1. 雲端資料儲存 (Firebase Schema)
本專案採用 Firebase Firestore 作為核心雲端資料庫，屬於 NoSQL 文件型資料庫。以下為核心資料集的 Schema 定義與欄位詳細用途：

### 核心實體關聯 (Entity-Relationship) 概念
* **User (使用者)** 1 對多 **Point_Logs (積分流水帳)**
* **User (使用者)** 1 對多 **Route_Sessions (跑圖摘要)**
* **User (使用者)** 1 對多 **Vouchers (優惠券)**
* **User (使用者)** 1 對多 **User_Achievements (玩家已解鎖成就)**
* **User (使用者)** 1 對多 **User_Bookmarks (使用者書籤)**
* **User (使用者)** 多 對 多 **Friendships (好友關係)**
* **Store (商家)** 1 對多 **Vouchers (優惠券)**
* **Chat (聊天室)** 1 對多 **Messages (聊天訊息)**

---

### 詳細 Schema 定義

#### A. 地點與任務資訊 (missions)
作為陣營爭奪的標的，支援透過 JSON 腳本批次上傳更新。
* `missionId` (Document ID): 自動產生的文件 ID。
* `name` (String): 任務地點名稱（如：嘉義舊監獄）。
* `description` (String): 景點/任務的歷史與特色描述。
* `address` (String): 地理位置地址。
* `lat` / `lng` (Number): 經緯度座標，用於地圖渲染與 GPS 距離計算。
* `radiusMeters` (Number): 判定簽到成功的 GPS 容許誤差半徑（單位：公尺）。
* `category` (String): 景點分類（`"heritage"` 歷史古蹟, `"food"` 特色美食, `"cafe"` 文青咖啡）。
* `factionBonus` (String): 該地點所屬的加成陣營（`"red"`, `"green"`, `"blue"`）。
* `basePoints` (Number): 基礎簽到積分（例如：50 點）。
* `bonusPoints` (Number): 同陣營玩家簽到時的加成積分（例如：20 點）。
* `imageUrl` (String): 任務景點的圖片 URL。
* `status` (String): 狀態控管，供系統決定是否顯示（`"draft"` 草稿, `"active"` 啟用）。
* `aiPublishConditions` (String): AI 導覽觸發的特殊隱藏條件。
* `totalCheckIns` (Number): 該地點的累計簽到次數。
* `createdAt` (Timestamp): 建立時間。
* `createdBy` (String): 建立人員或腳本名稱。

#### B. 合作商家資訊 (stores)
合作兌換優惠的店家清單。
* `storeId` (Document ID)
* `name` / `description` (String): 店家名稱與介紹。
* `address` (String): 店家地址。
* `lat` / `lng` (Number): 店家位置經緯度。
* `imageUrl` (String): 店家封面圖片 URL。
* `redeemCode` (String): 店家專用核銷代碼（實體店員輸入此代碼以確認核銷）。
* `requiredPoints` (Number): 兌換該店家優惠券所需的積分。
* `faction` (String): 該優惠所屬陣營（或 `"all"` 通用）。
* `createdAt` (Timestamp): 建立時間。
* `createdBy` (String): 建立人員。

#### C. 商店道具資訊 (shop_items)
陣營商店內供玩家以積分購買的道具。
* `itemId` (Document ID)
* `name` / `description` (String): 道具名稱與功能描述。
* `cost` (Number): 兌換所需積分。
* `imageUrl` (String): 道具圖示連結。
* `requiredFaction` (String): 購買限制陣營（`"red"`, `"green"`, `"blue"` 或 `"all"`）。
* `effect` (String): 道具效果識別碼。

#### D. 積分流水帳 (point_logs)
為確保資料安全與防作弊，此資料集在 Security Rules 中設定為僅能新增 (Append-only)，禁止修改與刪除。
* `logId` (Document ID)
* `userId` (String): 關聯的玩家 UID。
* `type` (String): 變動類型（`"earn"` 賺取, `"spend"` 消費）。
* `points` (Number): 積分變動值。
* `faction` (String): 獲得此積分時玩家所属的陣營。
* `timestamp` (Timestamp): 異動發生的伺服器時間。

#### E. 優惠券 (vouchers)
玩家兌換的商家優惠。
* `voucherId` (Document ID)
* `userId` (String): 持有優惠券的玩家 UID。
* `storeId` (String): 關聯的合作商家 ID。
* `name` / `description` (String): 優惠名稱與使用限制說明。
* `isRedeemed` (Boolean): 是否已核銷。
* `redeemedAt` (Timestamp): 實際核銷時間（若未核銷則為 null）。
* `createdAt` (Timestamp): 兌換時間。

#### F. 跑圖摘要 (route_sessions)
使用者跑圖軌跡的統計資料。
* `sessionId` (Document ID): 與本地軌跡 JSON 檔案同名的 ID。
* `userId` (String): 跑圖玩家的 UID。
* `distanceMeters` (Number): 本次跑圖總距離（公尺）。
* `durationSeconds` (Number): 本次跑圖總耗時（秒）。
* `pointsEarned` (Number): 本次跑圖獲得的總積分。
* `hasLocalFile` (Boolean): 手機端是否留有完整的詳細軌跡檔。
* `createdAt` (Timestamp): 跑圖記錄上傳時間。

#### G. 成就定義 (achievements)
全域系統成就項目。
* `achievementId` (Document ID)
* `title` / `description` (String): 成就標題與取得條件說明。
* `pointsRequired` (Number): 解鎖此成就所需的總累計積分。
* `imageUrl` (String): 成就徽章的圖示網址。

#### H. 玩家已解鎖成就 (user_achievements)
記錄玩家所解鎖的成就。
* `docId` (Document ID): 通常為 `userId_achievementId` 組合鍵。
* `userId` (String): 玩家 UID。
* `achievementId` (String): 已解鎖的成就 ID。
* `unlockedAt` (Timestamp): 解鎖時間。

#### I. 社群好友關係 (friendships)
管理玩家之間的好友連結與申請狀態。
* `docId` (Document ID): 通常為 `uid1_uid2` 排序組合，確保唯一性。
* `users` (Array of Strings): 包含兩個參與者 UID 的陣列 `[uid1, uid2]`。
* `requesterId` (String): 發起好友申請的玩家 UID。
* `status` (String): 好友關係狀態（`"pending"` 申請中, `"accepted"` 已確認）。
* `createdAt` (Timestamp): 申請發起時間。

#### J. 聊天頻道與訊息 (chats / chats/messages)
玩家或好友間即時通訊管道。
* `chats/{chatId}` (Document ID): 聊天室 ID。
* `participants` (Array of Strings): 聊天室成員 UID 陣列。
* `lastMessageAt` (Timestamp): 最後一筆訊息發送時間。
  * **子資料集 `messages/{messageId}`**:
    * `senderId` (String): 發送者 UID。
    * `content` (String): 訊息內容。
    * `timestamp` (Timestamp): 發送時間。

#### K. 任務互動記錄 (mission_interactions)
記錄玩家對任務景點的簽到與收藏歷史。
* `docId` (Document ID)
* `userId` (String): 玩家 UID。
* `missionId` (String): 任務景點 ID。
* `type` (String): 互動類型（`"check_in"` 簽到, `"bookmark"` 收藏）。
* `timestamp` (Timestamp): 互動時間。

#### L. 使用者收藏書籤 (user_bookmarks)
玩家收藏的景點。
* `docId` (Document ID)
* `userId` (String): 玩家 UID。
* `missionId` (String): 景點 ID。
* `createdAt` (Timestamp): 收藏時間。

#### M. App 全域設定 (app_config)
全域參數控制。
* `configId` (Document ID)
* `apiVersion` (String): 目前支援的最高 API 版本號。
* `maintenanceMode` (Boolean): 系統維護狀態開關。

---

## 2. 使用者身分識別在 Firebase 內的紀錄
專案整合了 **Firebase Authentication** 進行身分驗證，並在 Firestore 中將使用者資料依據「隱私級別」拆分為兩個 Collection：

* **身分綁定**：玩家註冊登入後，Firebase Auth 會核發唯一的 `uid`。這個 `uid` 會作為 Firestore 中 Document 的 ID，確保資料與登入身分強綁定。
* **公開資料 (`users_public/{uid}`)**：存放 `displayName`、`avatarUrl`、`faction` (陣營) 與各陣營積分 (`totalScore`, `redScore` 等)。此表允許其他已登入玩家讀取，用於渲染地圖上的玩家位置與排行榜。
* **私密資料 (`users_private/{uid}`)**：存放 `email`、`isAdmin`、`encryptedApiKey` 等敏感資訊。透過 Firestore Security Rules，嚴格限制只有 `request.auth.uid == userId` 的本人才能讀寫（管理員可透過 Admin SDK 查詢，例如根據電子郵件查找使用者 UID 來建立好友關係）。

---

## 3. 手機端資料儲存架構
為了優化效能並大幅降低 Firebase 的免費額度消耗，本專案採用「混合儲存策略」：

1. **機密資料 (Secure Storage)**：
   * 使用 `flutter_secure_storage` 將使用者的 Gemini API Key 加密儲存於手機系統底層 (iOS Keychain / Android Keystore)，確保 AI 導覽功能的密鑰安全。
2. **高頻且大量的軌跡資料 (Local JSON / File System)**：
   * 玩家跑圖時的原始 GPS 座標（每秒紀錄一次），會透過 `path_provider` 直接以 JSON 格式 (`route_{sessionId}.json`) 寫入手機 App 的沙盒目錄 (Documents Directory)。
   * **雲端僅存摘要**：Firestore 的 `route_sessions` 表只儲存該次跑圖的「總距離」、「總時長」等摘要，解決 NoSQL 儲存大量陣列導致的超額讀寫問題。
3. **App 偏好設定 (SharedPreferences)**：
   * 存放深淺色模式、通知開關等輕量化且非機密的鍵值對 (Key-Value) 設定。

---

## 4. 批次上傳與雲端資料重建、備份方案 (Scripts)
專案於 `scripts/` 目錄中，提供了完整的資料維護、重建與備份方案，使用 Firebase Admin SDK 實現。這些腳本可在雲端轉移、移機或資料損毀時快速回復系統。

### 準備工作
在 `scripts/` 目錄下準備好 `serviceAccountKey.json`（可從 Firebase 主控台 > 專案設定 > 服務帳戶 中下載生成並更名），並執行安裝依賴：
```bash
cd scripts
npm install
```

### 備份與還原
1. **全庫備份 (Backup)**
   透過執行備份腳本，可自動輪詢所有核心 Collection，並在專案根目錄的 `data/` 下依據當前時間生成備份檔案：
   ```bash
   node backup_firestore.js
   ```
   * *輸出結果*：生成如 `data/backup_20260526_090000/` 目錄，內含所有資料集的獨立 JSON 檔案以及描述總筆數的 `_metadata.json`。

2. **災後還原 / 移機重建 (Restore)**
   若今天換了新 Firebase 專案，或是需要清空重建，只需執行：
   ```bash
   node restore_firestore.js --from data/backup_20260526_090000
   ```
   * *警告*：此腳本會覆寫同名文件，請務必確認目標專案是否正確。

### 基礎資料批次初始化與更新 (Upload)
當營運單位調整了嘉義市的任務景點或合作商家，可直接修改 `data/missions_chiayi.json` 或 `data/stores_chiayi.json`，並一鍵同步至雲端：
* **批次更新任務地點**：
  ```bash
  node upload_missions.js
  ```
* **批次更新合作商家**：
  ```bash
  node upload_stores.js
  ```
