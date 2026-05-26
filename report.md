# Chiayi Wars Triple Threat - 系統設計與資料儲存報告

## 1. App UI 階層與用途說明

以下為目前 App 的 UI 頁面階層架構，以及各頁面的固定用途描述：

```text
0. 登入頁 (Landing Page)
   └── 負責處理使用者驗證 (Firebase Auth)，包含登入與註冊。若為已登入狀態，則自動進入主頁面。

1. 主頁面 (Home Screen)
   ├── 提供底部導覽列 (Bottom Navigation Bar) 進行主要功能的切換。
   ├── 包含側邊欄 (Sidebar) 用於全域設定 (深色模式、簡潔模式、地圖下載等)。
   │
   ├── 1.1 地圖頁面 (Map Screen)
   │   ├── 核心遊戲畫面。顯示 OSM 地圖、玩家定位、周邊任務節點、以及勢力網格圖層。
   │   ├── 多功能按鈕 (MapMultiFab)：提供地圖縮放、定位、AI 嚮導、公車動態、切換圖層、開始跑圖錄製等操作。
   │   └── 包含底部滑出的「附近任務列表」與「背包/道具」使用介面。
   │
   ├── 1.2 任務列表頁面 (Missions Screen)
   │   └── 顯示詳細的任務清單、景點打卡狀態、以及進行中的挑戰任務。
   │
   ├── 1.3 排行榜頁面 (Leaderboard Screen)
   │   └── 顯示目前三方勢力 (紅、綠、藍) 的佔領積分與個人排名。
   │
   ├── 1.4 我的主頁 (Profile Screen)
   │   ├── 顯示使用者帳號資訊。
   │   ├── 提供開發人員模式切換、測試資料上傳 (種子) 等進階功能。
   │   └── 包含「績效與跑圖紀錄」查看功能。
   │
   └── 1.5 掃描打卡頁面 (Scanner Page)
       └── 啟動相機掃描景點 QR Code，驗證成功後寫入資料庫並跳出結算畫面 (顯示獲得分數與勢力分佈)。
```

## 2. 雲端資料儲存 (Firebase)

### Firebase 資料格式與 Schema 設計

在 Firestore 中，我們主要透過以下多個 Collection 來管理遊戲狀態與使用者資料：

#### 2.1 `users_public` (使用者公開資料)
紀錄使用者的身分識別與隸屬陣營，透過 Firebase Auth UID 進行綁定，此集合資料對所有玩家公開，用於排行榜與地圖顯示。
- **Document ID**: `uid` (Firebase Auth 產生的唯一識別碼)
- **欄位**:
  - `email` (String): 註冊信箱
  - `faction` (String): 所屬陣營 (red, green, blue)
  - `displayName` (String): 玩家暱稱
  - `totalPoints` (Number): 個人累計積分

#### 2.2 `users_private` (使用者私人資料)
儲存不適合公開的敏感資訊或是私人應用設定。
- **Document ID**: `uid`
- **欄位**:
  - `createdAt` (Timestamp): 帳號建立時間
  - `lastLogin` (Timestamp): 最後登入時間
  - `settings` (Map): 私人偏好設定 (如推播通知等)

#### 2.3 `users/{uid}/*` (使用者子集合 Sub-collections)
依附於個別使用者底下的子集合，用於紀錄個人專屬的詳細歷程與背包資料：
- **`routes`**: 紀錄玩家的跑圖軌跡，包含每次路徑的座標與消耗時間。
- **`history`**: 紀錄歷史打卡與績效，供績效報表查詢。
- **`inventory`**: 紀錄玩家從商店購買或任務獲得的道具 (如能量飲料、掃描器等) 與數量。

#### 2.4 `missions` (景點與任務資訊)
紀錄地圖上的景點、打卡熱度以及各陣營的佔領狀況。
- **Document ID**: 自動生成的 UUID
- **欄位**:
  - `name` (String): 景點名稱 (例如: 林聰明沙鍋魚頭)
  - `category` (String): 分類 (food, heritage, cafe)
  - `lat` (Number): 緯度
  - `lng` (Number): 經度
  - `basePoints` (Number): 基礎打卡分數
  - `status` (String): 狀態 (active/inactive)
  - `totalCheckIns` (Number): 總打卡次數
  - `checkInsByFaction` (Map): 陣營打卡統計
    - `red` (Number): 紅方打卡次數
    - `green` (Number): 綠方打卡次數
    - `blue` (Number): 藍方打卡次數

#### 2.5 `shop_items` (商店道具資訊)
紀錄遊戲內可供玩家使用積分購買的道具與商品列表。
- **Document ID**: 道具唯一 ID
- **欄位**:
  - `name` (String): 道具名稱
  - `description` (String): 道具描述與效果
  - `price` (Number): 購買所需積分
  - `effectType` (String): 效果類型 (例如: multiplier, reveal)

### 資料批次上傳與備份/重建策略 (Script 處理)

假設今天要進行**雲端備份、移機或重建資料**，可以透過撰寫腳本 (Node.js 或 Python) 搭配 Firebase Admin SDK 處理：

1. **資料匯出 (備份)**：
   撰寫腳本遍歷 Firestore 的 `missions` 與 `users_public` 集合，將所有 Document 轉為 JSON 格式並存檔至本地端或 Cloud Storage。
2. **資料批次上傳 (重建/更新)**：
   準備好 JSON 檔案後，透過 Admin SDK 的 `WriteBatch` 進行批次寫入 (Batch Write)。每次最多可包含 500 筆操作，大幅提升重建效率並確保交易完整性。
   *(註：目前 App 內的「開發人員模式」中的「上傳測試資料」按鈕，即是模擬了批次上傳示範資料的概念，實務上可利用此方式在移機時一鍵重建預設景點)*

### 身分識別與安全
系統採用 **Firebase Authentication** 進行使用者驗證。使用者登入後會取得 JWT Token，Firestore Security Rules 會強制驗證 `request.auth.uid != null` 才能進行打卡與分數更新，確保資料不可隨意篡改。

## 3. 手機端資料儲存

手機端 (Local Storage) 主要儲存不需頻繁同步、或為了離線與效能考量的資料：

1. **Shared Preferences / Flutter Secure Storage**：
   - 登入狀態 (Auth Token 緩存)
   - 使用者偏好設定 (例如：是否開啟簡潔模式、深色/淺色模式、介面語言設定等)
2. **離線地圖快取 (SQLite / Cache Directory)**：
   - 使用 `flutter_map_tile_caching` 或自建服務器下載的 OSM 瓦片 (Tiles)。
   - 大幅減少地圖載入時的網路流量，讓玩家在訊號不佳處仍能看見完整地圖。
3. **暫存軌跡紀錄 (Route Recording)**：
   - 當玩家按下「跑圖紀錄」時，即時的 GPS 座標 (List<LatLng>) 會暫存在記憶體或 SQLite 中，待玩家結束紀錄時再結算或上傳。

## 4. 附註：後續開發項目
根據最新回報，TDX (運輸資料流通服務) 目前正處於維護階段，因此關於「公車動態與即時交通資訊傳輸」的串接 (App - Cloud Store - DataSource)，將會延至下週次作業進行實作與測試。
