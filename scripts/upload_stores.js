/**
 * upload_stores.js
 * 批次上傳商家資料到 Firestore
 *
 * 使用方式:
 *   node upload_stores.js
 */

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// 若尚未初始化才初始化
if (!admin.apps.length) {
  const serviceAccount = require('./serviceAccountKey.json');
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

const db = admin.firestore();

const storesPath = path.join(__dirname, '../data/stores_chiayi.json');
const stores = JSON.parse(fs.readFileSync(storesPath, 'utf8'));

async function uploadStores() {
  console.log(`📦 準備上傳 ${stores.length} 筆商家資料...`);

  const batch = db.batch();
  const now = admin.firestore.FieldValue.serverTimestamp();

  stores.forEach((store, index) => {
    const docRef = db.collection('stores').doc();
    batch.set(docRef, {
      ...store,
      createdAt: now,
      createdBy: 'admin_script',
    });
    console.log(`  [${index + 1}/${stores.length}] 準備寫入: ${store.name}`);
  });

  await batch.commit();
  console.log('\n✅ 全部商家上傳成功！');
}

uploadStores().catch((err) => {
  console.error('❌ 上傳失敗:', err);
  process.exit(1);
});
