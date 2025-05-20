import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';      // For FirebaseException
import '../utils/constants.dart';                      // Your AppColors
import 'chat_screen.dart';                             // Your Chat widget

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    if (_currentUser == null) {
      print("ChatListScreen: Current user is null. Chat functionality will be limited.");
    }
  }

  void _navigateTo(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/bookDiscovery');
        break;
      case 1:
        // already here
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _getChatRoomsStream() {
    if (_currentUser == null) return Stream.empty();
    return FirebaseFirestore.instance
        .collection('chatRooms')
        .where('participants', arrayContains: _currentUser!.uid)
        .orderBy('lastMessageTimestamp', descending: true)
        .snapshots();
  }

  Future<void> _deleteChatRoom(String chatRoomId) async {
    if (_currentUser == null) return;
    try {
      final messagesSnapshot = await FirebaseFirestore.instance
          .collection('chatRooms')
          .doc(chatRoomId)
          .collection('messages')
          .get();
      for (var msg in messagesSnapshot.docs) {
        await msg.reference.delete();
      }
      await FirebaseFirestore.instance
          .collection('chatRooms')
          .doc(chatRoomId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Chat deleted'),
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[800]
              : null,
        ),
      );
    } catch (e) {
      print("Error deleting chat: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting chat: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor   = AppColors.getBackground(context);
    final textColor         = AppColors.getTextPrimary(context);
    final textSecondaryColor= AppColors.getTextSecondary(context);
    final cardColor         = AppColors.getCardBackground(context);
    final dividerColor      = Theme.of(context).brightness == Brightness.dark
        ? Colors.grey[800]!
        : Colors.black12;

    if (_currentUser == null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: backgroundColor,
          elevation: 0,
          centerTitle: true,
          automaticallyImplyLeading: false,
          title: Text(
            'Chats',
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          ),
        ),
        body: Center(
          child: Text(
            'Please log in to view your chats.',
            style: TextStyle(color: textColor, fontSize: 16),
          ),
        ),
        bottomNavigationBar: _buildBottomNavigationBar(),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Chats',
          style: TextStyle(
            color: textColor,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _getChatRoomsStream(),
        builder: (context, snapshot) {
          // 1) Handle Firestore index-error as "no chats"
          if (snapshot.hasError) {
            final err = snapshot.error;
            if (err is FirebaseException && err.code == 'failed-precondition') {
              return Center(
                child: Text(
                  'No chats yet. Start a conversation!',
                  style: TextStyle(color: textSecondaryColor, fontSize: 16),
                ),
              );
            }
            // real error
            print("Firestore Stream Error: $err");
            return Center(
              child: Text(
                'Something went wrong: $err',
                style: TextStyle(color: textColor),
              ),
            );
          }

          // 2) Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 3) Empty
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No chats yet. Start a conversation!',
                style: TextStyle(color: textSecondaryColor, fontSize: 16),
              ),
            );
          }

          // 4) Show chat list
          final chatRoomDocs = snapshot.data!.docs;
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: chatRoomDocs.length,
            separatorBuilder: (_, __) => Divider(
              color: dividerColor,
              indent: 20,
              endIndent: 20,
            ),
            itemBuilder: (context, index) {
              final doc      = chatRoomDocs[index];
              final data     = doc.data();
              final chatRoomId = doc.id;

              // find the “other” user in participants
              final participants      = List<String>.from(data['participants'] ?? []);
              final infoMap           = Map<String, dynamic>.from(data['participantInfo'] ?? {});
              String otherId          = '';
              Map<String, dynamic> otherInfo = {};

              for (var id in participants) {
                if (id != _currentUser!.uid) {
                  otherId = id;
                  otherInfo = infoMap[id] != null
                      ? Map<String, dynamic>.from(infoMap[id])
                      : {};
                  break;
                }
              }

              final name      = otherInfo['name']   ?? 'Unknown User';
              final avatarUrl = otherInfo['avatar'] ?? 'https://i.pravatar.cc/150?img=1';
              final lastMsg   = data['lastMessage'] ?? 'No messages yet.';

              return Dismissible(
                key: Key(chatRoomId),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) => _deleteChatRoom(chatRoomId),
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 2,
                  color: cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      radius: 25,
                      backgroundImage: NetworkImage(avatarUrl),
                      onBackgroundImageError: (_, __) => null,
                      child: (avatarUrl.isEmpty || avatarUrl.startsWith('https://i.pravatar.cc'))
                          ? const Icon(Icons.person, size: 25)
                          : null,
                    ),
                    title: Text(name, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                    subtitle: Text(lastMsg,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(color: textSecondaryColor)),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => Chat(
                            chatRoomId:   chatRoomId,
                            recipientId:  otherId,
                            name:         name,
                            avatarUrl:    avatarUrl,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  BottomNavigationBar _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: 1,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Colors.grey,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      backgroundColor:
          Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
      onTap: _navigateTo,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Messages'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}
