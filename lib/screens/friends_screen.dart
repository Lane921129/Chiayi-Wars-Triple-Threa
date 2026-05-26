import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/friend_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'route_detail_screen.dart';
import 'friend_profile_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FriendService _friendService = FriendService();
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchType = 'email'; // 'email', 'uid', 'name'
  List<Map<String, dynamic>> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? FactionColors.darkBg : Colors.grey[100],
      appBar: AppBar(
        backgroundColor: isDarkMode ? FactionColors.darkBg : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: isDarkMode ? Colors.white : Colors.black87),
        title: Text(
          '社群好友',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: FactionColors.gold,
          labelColor: isDarkMode ? FactionColors.gold : Colors.orange.shade800,
          unselectedLabelColor: isDarkMode ? Colors.white70 : Colors.black87,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          tabs: const [
            Tab(text: '我的好友'),
            Tab(text: '跑圖動態'),
            Tab(text: '待處理申請'),
            Tab(text: '新增好友'),
            Tab(text: '附近的人'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyFriendsTab(isDarkMode),
          _buildRecordsTab(isDarkMode),
          _buildPendingRequestsTab(isDarkMode),
          _buildAddFriendTab(isDarkMode),
          _buildNearbyTab(isDarkMode),
        ],
      ),
    );
  }

  // ── 我的好友 Tab ──────────────────────────────────────────────────────────
  Widget _buildMyFriendsTab(bool isDarkMode) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _friendService.getMyFriendsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              '資料載入出錯',
              style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
            ),
          );
        }
        final friends = snapshot.data ?? [];
        if (friends.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 64,
                  color: isDarkMode ? Colors.white30 : Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  '目前尚未添加任何好友',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDarkMode ? Colors.white54 : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => _tabController.animateTo(2),
                  child: const Text('去新增好友'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: friends.length,
          itemBuilder: (context, index) {
            final friend = friends[index];
            final faction = friend['faction'] ?? '';
            final score = friend['totalScore'] ?? 0;
            final avatarUrl = friend['avatarUrl'] ?? '';
            final displayName = friend['displayName'] ?? '';
            final docId = friend['docId'] ?? '';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              color: isDarkMode ? FactionColors.cardBg : Colors.white,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => FriendProfileScreen(friendData: friend)));
                },
                child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: FactionColors.forFaction(faction).withValues(alpha: 0.2),
                  backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl.isEmpty
                      ? Text(
                          FactionColors.emojiForFaction(faction),
                          style: const TextStyle(fontSize: 20),
                        )
                      : null,
                ),
                title: Row(
                  children: [
                    Text(
                      displayName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? FactionColors.textPrimary : Colors.black87,
                      ),
                    ),
                    if (faction.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: FactionColors.forFaction(faction).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: FactionColors.forFaction(faction).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          FactionColors.nameForFaction(faction),
                          style: TextStyle(
                            fontSize: 10,
                            color: FactionColors.forFaction(faction),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                subtitle: Text(
                  '戰力積分: $score 分',
                  style: TextStyle(
                    color: isDarkMode ? FactionColors.textSecondary : Colors.black54,
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.person_remove, color: Colors.redAccent),
                  onPressed: () => _confirmRemoveFriend(displayName, docId),
                ),
              ),
              ),
            );
          },
        );
      },
    );
  }

  // 確認刪除好友對話框
  void _confirmRemoveFriend(String name, String docId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('刪除好友'),
          content: Text('確定要解除與「$name」的好友關係嗎？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final messenger = ScaffoldMessenger.of(context);
                final success = await _friendService.deleteFriendship(docId);
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(success ? '已解除好友關係' : '解除好友關係失敗'),
                  ),
                );
              },
              child: const Text('確定', style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        );
      },
    );
  }

  // ── 跑圖動態 Tab ──────────────────────────────────────────────────────────
  Widget _buildRecordsTab(bool isDarkMode) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: isDarkMode ? FactionColors.darkBg : Colors.white,
            child: TabBar(
              indicatorColor: FactionColors.gold,
              labelColor: isDarkMode ? FactionColors.gold : Colors.orange.shade800,
              unselectedLabelColor: isDarkMode ? Colors.white70 : Colors.black87,
              tabs: const [
                Tab(text: '好友動態'),
                Tab(text: '我的跑圖'),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchFeed(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('載入失敗: ${snapshot.error}', style: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black54)));
                }

                final feed = snapshot.data ?? [];
                final myFeed = feed.where((r) => r['isMe'] == true).toList();
                final friendsFeed = feed.where((r) => r['isMe'] == false).toList();

                return TabBarView(
                  children: [
                    _buildFeedList(friendsFeed, isDarkMode, '目前沒有好友的跑圖紀錄'),
                    _buildFeedList(myFeed, isDarkMode, '您目前還沒有跑圖紀錄'),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedList(List<Map<String, dynamic>> feed, bool isDarkMode, String emptyMessage) {
    if (feed.isEmpty) {
      return Center(child: Text(emptyMessage, style: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black54)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: feed.length,
      itemBuilder: (context, index) {
        final record = feed[index];
        final isMe = record['isMe'] == true;
        final distance = record['distanceMeters'] ?? 0;
        final duration = record['durationSeconds'] ?? 0;
        final weather = record['weather'] ?? '未知天氣';
        final timestamp = record['timestamp'] as Timestamp?;
        final dateStr = timestamp != null
            ? '${timestamp.toDate().month}/${timestamp.toDate().day} ${timestamp.toDate().hour.toString().padLeft(2, '0')}:${timestamp.toDate().minute.toString().padLeft(2, '0')}'
            : '未知時間';
        
        final displayName = record['displayName'] ?? (isMe ? '我' : '好友');
        final faction = record['faction'] ?? 'red';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: isDarkMode ? FactionColors.cardBg : Colors.white,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => RouteDetailScreen(record: record)));
            },
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: FactionColors.forFaction(faction).withValues(alpha: 0.2),
                child: Text(
                  FactionColors.emojiForFaction(faction),
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              title: Row(
                children: [
                  Text(
                    displayName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isMe ? FactionColors.gold : (isDarkMode ? FactionColors.textPrimary : Colors.black87),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '完成了一趟跑圖',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? FactionColors.textSecondary : Colors.black54,
                    ),
                  ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('距離: ${(distance/1000).toStringAsFixed(2)}km   耗時: ${duration ~/ 60}分${duration % 60}秒', style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87)),
                    Text(dateStr, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            ),
          ),
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _fetchFeed() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];
    
    List<Map<String, dynamic>> allRoutes = [];
    
    // 1. 取得自己的紀錄
    final myRoutes = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('routes')
        .orderBy('timestamp', descending: true)
        .limit(10)
        .get();
    
    var myDataResponse = await FirebaseFirestore.instance.collection('users_public').doc(user.uid).get();
    var myData = myDataResponse.data() ?? {};
        
    for (var doc in myRoutes.docs) {
      var data = doc.data();
      data['uid'] = user.uid;
      data['isMe'] = true;
      data['displayName'] = myData['displayName'] ?? '我';
      data['faction'] = myData['faction'] ?? 'red';
      allRoutes.add(data);
    }
    
    // 2. 取得好友名單並讀取紀錄
    final snapshot = await FirebaseFirestore.instance
        .collection('friendships')
        .where('users', arrayContains: user.uid)
        .where('status', isEqualTo: 'accepted')
        .get();
        
    for (var doc in snapshot.docs) {
      List<dynamic> users = doc.data()['users'] ?? [];
      String friendId = users.firstWhere((id) => id != user.uid, orElse: () => '');
      if (friendId.isNotEmpty) {
        var fDataResponse = await FirebaseFirestore.instance.collection('users_public').doc(friendId).get();
        var fData = fDataResponse.data() ?? {};
        try {
          final fRoutes = await FirebaseFirestore.instance
              .collection('users')
              .doc(friendId)
              .collection('routes')
              .orderBy('timestamp', descending: true)
              .limit(5)
              .get();
              
          for (var r in fRoutes.docs) {
            var data = r.data();
            data['uid'] = friendId;
            data['isMe'] = false;
            data['displayName'] = fData['displayName'] ?? '好友';
            data['faction'] = fData['faction'] ?? 'red';
            allRoutes.add(data);
          }
        } catch (e) {
          debugPrint('Failed to fetch friend routes: $e');
        }
      }
    }
    
    // 排序
    allRoutes.sort((a, b) {
      final aTime = a['timestamp'] as Timestamp?;
      final bTime = b['timestamp'] as Timestamp?;
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return bTime.compareTo(aTime);
    });
    
    return allRoutes;
  }

  // ── 好友申請 Tab ──────────────────────────────────────────────────────────
  Widget _buildPendingRequestsTab(bool isDarkMode) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _friendService.getPendingRequestsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              '資料載入出錯',
              style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
            ),
          );
        }
        final requests = snapshot.data ?? [];
        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.mark_email_unread_outlined,
                  size: 64,
                  color: isDarkMode ? Colors.white30 : Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  '目前沒有收到任何好友申請',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDarkMode ? Colors.white54 : Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final req = requests[index];
            final faction = req['faction'] ?? '';
            final displayName = req['displayName'] ?? '';
            final avatarUrl = req['avatarUrl'] ?? '';
            final docId = req['docId'] ?? '';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              color: isDarkMode ? FactionColors.cardBg : Colors.white,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: FactionColors.forFaction(faction).withValues(alpha: 0.2),
                  backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl.isEmpty
                      ? Text(
                          FactionColors.emojiForFaction(faction),
                          style: const TextStyle(fontSize: 20),
                        )
                      : null,
                ),
                title: Text(
                  displayName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? FactionColors.textPrimary : Colors.black87,
                  ),
                ),
                subtitle: Text(
                  '想加你為好友',
                  style: TextStyle(
                    color: isDarkMode ? FactionColors.textSecondary : Colors.black54,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check_circle, color: Colors.green),
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final success = await _friendService.acceptFriendRequest(docId);
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(success ? '已接受好友申請' : '操作失敗'),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.redAccent),
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final success = await _friendService.deleteFriendship(docId);
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(success ? '已拒絕好友申請' : '操作失敗'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── 新增好友 Tab ──────────────────────────────────────────────────────────
  Widget _buildAddFriendTab(bool isDarkMode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '搜尋社群好友',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? FactionColors.gold : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'email', label: Text('Email')),
              ButtonSegment(value: 'uid', label: Text('UID')),
              ButtonSegment(value: 'name', label: Text('名稱')),
            ],
            selected: {_searchType},
            onSelectionChanged: (Set<String> newSelection) {
              setState(() {
                _searchType = newSelection.first;
                _searchResults.clear();
                _searchController.clear();
              });
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              prefixIcon: Icon(
                Icons.search,
                color: isDarkMode ? FactionColors.gold : Colors.grey,
              ),
              labelText: _searchType == 'email' ? '好友的 Email' : (_searchType == 'uid' ? '好友的 UID' : '好友的顯示名稱'),
            ),
            style: TextStyle(
              color: isDarkMode ? FactionColors.textPrimary : Colors.black87,
            ),
            onSubmitted: (_) => _performSearch(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isSearching ? null : _performSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: FactionColors.gold,
                foregroundColor: FactionColors.darkBg,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSearching
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5))
                  : const Text('搜尋', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 24),
          if (_searchResults.isNotEmpty) ...[
            Text('搜尋結果', style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ..._searchResults.map((user) => _buildUserCard(user, isDarkMode)),
          ],
        ],
      ),
    );
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    
    setState(() => _isSearching = true);
    final results = await _friendService.searchUsers(query, _searchType);
    setState(() {
      _searchResults = results;
      _isSearching = false;
    });

    if (results.isEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('找不到符合的玩家')));
    }
  }

  // ── 附近的人 Tab ──────────────────────────────────────────────────────────
  Widget _buildNearbyTab(bool isDarkMode) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _friendService.getNearbyUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final users = snapshot.data ?? [];
        if (users.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_off, size: 64, color: isDarkMode ? Colors.white30 : Colors.grey[400]),
                const SizedBox(height: 16),
                Text('附近沒有活躍的玩家', style: TextStyle(color: isDarkMode ? Colors.white54 : Colors.grey[600])),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            return _buildUserCard(users[index], isDarkMode);
          },
        );
      },
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user, bool isDarkMode) {
    final faction = user['faction'] ?? '';
    final displayName = user['displayName'] ?? '';
    final avatarUrl = user['avatarUrl'] ?? '';
    final uid = user['uid'] ?? '';
    final email = user['email'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isDarkMode ? FactionColors.cardBg : Colors.white,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: FactionColors.forFaction(faction).withValues(alpha: 0.2),
          backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
          child: avatarUrl.isEmpty ? Text(FactionColors.emojiForFaction(faction)) : null,
        ),
        title: Text(displayName, style: TextStyle(fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (email.isNotEmpty)
              Text(email, style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
            Text('UID: $uid', style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: FactionColors.forFaction(faction)),
          onPressed: () => _sendRequestTo(uid),
          child: const Text('加好友', style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  Future<void> _sendRequestTo(String uid) async {
    final result = await _friendService.sendFriendRequestByUid(uid);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
    }
  }
}
