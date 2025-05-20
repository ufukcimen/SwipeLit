import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'chat_screen.dart'; // ✅ Import the working Chat screen

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final List<Map<String, String>> chats = [
    {
      'name': 'Yağız',
      'message': 'Ok let me check!',
      'avatar': 'https://i.pravatar.cc/150?img=3'
    },
    {
      'name': 'Emir',
      'message': 'I like that book!',
      'avatar': 'https://i.pravatar.cc/150?img=5'
    },
    {
      'name': 'Damla',
      'message': 'Can you meet me on Saturday to give the book?',
      'avatar': 'https://i.pravatar.cc/150?img=6'
    },
    {
      'name': 'Ufuk',
      'message': 'Thanks a lot.',
      'avatar': 'https://i.pravatar.cc/150?img=9'
    },
  ];

  void _navigateTo(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/bookDiscovery');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/messages');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get theme-aware colors
    final backgroundColor = AppColors.getBackground(context);
    final textColor = AppColors.getTextPrimary(context);
    final textSecondaryColor = AppColors.getTextSecondary(context);
    final cardColor = AppColors.getCardBackground(context);
    final dividerColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.grey[800]
        : Colors.black12;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: backgroundColor,
        elevation: 0,
        title: Text(
          'Chats',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: chats.length,
        separatorBuilder: (context, index) => Divider(
          color: dividerColor,
          indent: 20,
          endIndent: 20,
        ),
        itemBuilder: (context, index) {
          final chat = chats[index];
          return Dismissible(
            key: Key(chat['name']!),
            direction: DismissDirection.endToStart,
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (_) {
              setState(() => chats.removeAt(index));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Chat deleted'),
                  backgroundColor: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[800]
                      : null,
                ),
              );
            },
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
                  backgroundImage: NetworkImage(chat['avatar']!),
                ),
                title: Text(
                  chat['name']!,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                subtitle: Text(
                  chat['message']!,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(color: textSecondaryColor),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Chat(
                        name: chat['name']!,
                        avatarUrl: chat['avatar']!,
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.black
            : Colors.white,
        onTap: _navigateTo,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}