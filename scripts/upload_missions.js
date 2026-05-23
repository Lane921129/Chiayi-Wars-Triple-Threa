/**
 * upload_missions.js
 * 批次上傳任務資料到 Firestore
 *
 * 使用方式:
 *   cd scripts
 *   npm install
 *   node upload_missions.js
 *
 * 需要:
 *   - serviceAccountKey.json (從 Firebase Console > 專案設定 > 服務帳戶 下載)
 *   - ../data/missions_chiayi.json
 */

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// ── 初始化 Firebase Admin ──────────────────────────────
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

// ── 讀取任務資料 ────────────────────────────────────────
const missionsPath = path.join(__dirname, '../data/missions_chiayi.json');
const missions = JSON.parse(fs.readFileSync(missionsPath, 'utf8'));

// ── 批次寫入 ────────────────────────────────────────────
async function uploadMissions() {
  console.log(`📦 準備上傳 ${missions.length} 筆任務資料...`);

  const batch = db.batch();
  const now = admin.firestore.FieldValue.serverTimestamp();

  missions.forEach((mission, index) => {
    const docRef = db.collection('missions').doc(); // 自動產生 ID
    batch.set(docRef, {
      ...mission,
      createdAt: now,
      createdBy: 'admin_script',
    });
    console.log(`  [${index + 1}/${missions.length}] 準備寫入: ${mission.name}`);
  });

  await batch.commit();
  console.log('\n✅ 全部任務上傳成功！');
  console.log('📊 請到 Firebase Console > Firestore > missions 確認資料。');
}

uploadMissions().catch((err) => {
  console.error('❌ 上傳失敗:', err);
  process.exit(1);
});
