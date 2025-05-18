import 'package:flutter/material.dart';
import '../utils/constants.dart';

class ProfileScreen extends StatelessWidget {
  final String profileImageUrl = 'https://i.imgur.com/BoN9kdC.png';

  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        onTap: (index) {
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
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.menu_book, color: Colors.green, size: 40),
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 60,
              backgroundImage: NetworkImage(profileImageUrl),
            ),
            const SizedBox(height: 10),
            const Text(
              'Yağız, 21',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ProfileButton(
                  icon: Icons.settings,
                  label: 'SETTINGS',
                  onTap: () => Navigator.pushNamed(context, '/settings'),
                ),
                _ProfileButton(
                  icon: Icons.camera_alt,
                  label: 'UPDATE\nGALLERY',
                  onTap: () => Navigator.pushNamed(context, '/gallery'),
                ),
                _ProfileButton(
                  icon: Icons.edit,
                  label: 'EDIT INFO',
                  onTap: () => Navigator.pushNamed(context, '/edit'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool hasNotificationDot;
  final VoidCallback onTap;

  const _ProfileButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.hasNotificationDot = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 6,
                      color: Colors.black12,
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.grey[800]),
              ),
              if (hasNotificationDot)
                const Positioned(
                  right: 8,
                  top: 8,
                  child: CircleAvatar(
                    radius: 5,
                    backgroundColor: Colors.redAccent,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}