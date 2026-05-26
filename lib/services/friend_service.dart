import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FriendService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  // 取得好友文件 ID (以兩個人 UID 排序組合，確保唯一)
  String _getFriendshipDocId(String uid1, String uid2) {
    return uid1.compareTo(uid2) < 0 ? '${uid1}_$uid2' : '${uid2}_$uid1';
  }

  // 搜尋用戶 (依據 email, uid 或 displayName)
  Future<List<Map<String, dynamic>>> searchUsers(String query, String type) async {
    final currentUid = currentUser?.uid;
    if (currentUid == null || query.isEmpty) return [];

    List<Map<String, dynamic>> results = [];
    try {
      if (type == 'email') {
        final doc = await _firestore.collection('users_public').where('searchableEmail', isEqualTo: query).limit(1).get();
        if (doc.docs.isNotEmpty) {
          final targetUid = doc.docs.first.id;
          results.add(_formatPublicUserData(targetUid, doc.docs.first.data()));
        }
      } else if (type == 'uid') {
        final publicDoc = await _firestore.collection('users_public').doc(query).get();
        if (publicDoc.exists) {
          results.add(_formatPublicUserData(publicDoc.id, publicDoc.data()!));
        }
      } else if (type == 'name') {
        final querySnapshot = await _firestore.collection('users_public')
            .where('displayName', isGreaterThanOrEqualTo: query)
            .where('displayName', isLessThan: '$query\uf8ff')
            .limit(10)
            .get();
        for (var doc in querySnapshot.docs) {
          results.add(_formatPublicUserData(doc.id, doc.data()));
        }
      }
    } catch (e) {
      debugPrint("搜尋失敗: $e");
    }
    
    // 過濾掉自己
    return results.where((user) => user['uid'] != currentUid).toList();
  }

  Map<String, dynamic> _formatPublicUserData(String uid, Map<String, dynamic> data) {
    return {
      'uid': uid,
      'displayName': data['displayName'] ?? '探索者_${uid.substring(0, 4)}',
      'avatarUrl': data['avatarUrl'] ?? '',
      'faction': data['faction'] ?? '',
      'totalScore': data['totalScore'] ?? 0,
      'redScore': data['redScore'] ?? 0,
      'greenScore': data['greenScore'] ?? 0,
      'blueScore': data['blueScore'] ?? 0,
      'email': data['searchableEmail'] ?? '',
    };
  }

  // 透過 UID 發送好友申請
  Future<String> sendFriendRequestByUid(String targetUid) async {
    final currentUid = currentUser?.uid;
    if (currentUid == null) return "請先登入";
    if (targetUid == currentUid) return "不能加自己為好友";

    try {
      final docId = _getFriendshipDocId(currentUid, targetUid);
      final docRef = _firestore.collection('friendships').doc(docId);
      final docSnap = await docRef.get();

      if (docSnap.exists) {
        final data = docSnap.data()!;
        final status = data['status'];
        final requesterId = data['requesterId'];

        if (status == 'accepted') return "已是好友關係";
        if (status == 'pending') {
          if (requesterId == currentUid) return "已發送過申請，等待對方確認中";
          
          await docRef.update({'status': 'accepted'});
          return "互相發送申請，已自動成為好友！";
        }
      }

      await docRef.set({
        'users': [currentUid, targetUid],
        'requesterId': currentUid,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return "好友申請已送出";
    } catch (e) {
      debugPrint("發送好友申請失敗: $e");
      return "發生錯誤: $e";
    }
  }

  // 取得附近活躍的用戶 (排除自己與現有好友)
  Future<List<Map<String, dynamic>>> getNearbyUsers() async {
    final currentUid = currentUser?.uid;
    if (currentUid == null) return [];

    try {
      // 10 分鐘內有更新位置的活躍玩家
      final tenMinsAgo = DateTime.now().subtract(const Duration(minutes: 10));
      final querySnapshot = await _firestore.collection('users_public')
          .where('lastSeenAt', isGreaterThan: Timestamp.fromDate(tenMinsAgo))
          .get();

      List<Map<String, dynamic>> results = [];
      for (var doc in querySnapshot.docs) {
        if (doc.id == currentUid) continue; // 排除自己
        final data = doc.data();
        if (data['lastLat'] != null && data['lastLng'] != null) {
           results.add({
             ..._formatPublicUserData(doc.id, data),
             'lastLat': data['lastLat'],
             'lastLng': data['lastLng'],
           });
        }
      }

      // 抓取好友名單過濾掉已是好友的用戶
      final friendsSnap = await _firestore.collection('friendships')
          .where('users', arrayContains: currentUid)
          .where('status', isEqualTo: 'accepted')
          .get();
      
      final friendUids = friendsSnap.docs.map((d) {
        final users = List<dynamic>.from(d.data()['users'] ?? []);
        return users.firstWhere((u) => u != currentUid, orElse: () => '');
      }).toSet();

      return results.where((u) => !friendUids.contains(u['uid'])).toList();
    } catch (e) {
      debugPrint("獲取附近的人失敗: $e");
      return [];
    }
  }

  // 同意好友申請
  Future<bool> acceptFriendRequest(String docId) async {
    try {
      await _firestore.collection('friendships').doc(docId).update({
        'status': 'accepted',
      });
      return true;
    } catch (e) {
      debugPrint("同意好友申請失敗: $e");
      return false;
    }
  }

  // 拒絕/取消好友申請/刪除好友
  Future<bool> deleteFriendship(String docId) async {
    try {
      await _firestore.collection('friendships').doc(docId).delete();
      return true;
    } catch (e) {
      debugPrint("刪除/拒絕好友失敗: $e");
      return false;
    }
  }

  // 取得好友名單 Stream
  Stream<List<Map<String, dynamic>>> getMyFriendsStream() {
    final currentUid = currentUser?.uid;
    if (currentUid == null) return Stream.value([]);

    return _firestore
        .collection('friendships')
        .where('users', arrayContains: currentUid)
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .asyncMap((snapshot) async {
          List<Map<String, dynamic>> friends = [];
          for (var doc in snapshot.docs) {
            final data = doc.data();
            final List<dynamic> users = data['users'];
            final friendUid = users.firstWhere((uid) => uid != currentUid);

            final publicDoc = await _firestore.collection('users_public').doc(friendUid).get();
            if (publicDoc.exists) {
              final publicData = publicDoc.data() ?? {};
              friends.add({
                'docId': doc.id,
                'uid': friendUid,
                'displayName': publicData['displayName'] ?? '探索者_${friendUid.substring(0, 4)}',
                'avatarUrl': publicData['avatarUrl'] ?? '',
                'faction': publicData['faction'] ?? '',
                'totalScore': publicData['totalScore'] ?? 0,
                'redScore': publicData['redScore'] ?? 0,
                'greenScore': publicData['greenScore'] ?? 0,
                'blueScore': publicData['blueScore'] ?? 0,
              });
            }
          }
          // 依據積分排序
          friends.sort((a, b) => (b['totalScore'] as int).compareTo(a['totalScore'] as int));
          return friends;
        });
  }

  // 取得好友申請名單 Stream (發給我的)
  Stream<List<Map<String, dynamic>>> getPendingRequestsStream() {
    final currentUid = currentUser?.uid;
    if (currentUid == null) return Stream.value([]);

    return _firestore
        .collection('friendships')
        .where('users', arrayContains: currentUid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .asyncMap((snapshot) async {
          List<Map<String, dynamic>> requests = [];
          for (var doc in snapshot.docs) {
            final data = doc.data();
            final requesterId = data['requesterId'];
            if (requesterId != currentUid) {
              final publicDoc = await _firestore.collection('users_public').doc(requesterId).get();
              if (publicDoc.exists) {
                final publicData = publicDoc.data() ?? {};
                requests.add({
                  'docId': doc.id,
                  'uid': requesterId,
                  'displayName': publicData['displayName'] ?? '探索者_${requesterId.substring(0, 4)}',
                  'avatarUrl': publicData['avatarUrl'] ?? '',
                  'faction': publicData['faction'] ?? '',
                });
              }
            }
          }
          return requests;
        });
  }
}
