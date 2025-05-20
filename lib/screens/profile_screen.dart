import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import '../models/userModel.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? currentUser;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Get current user ID
      final String? uid = FirebaseAuth.instance.currentUser?.uid;

      if (uid != null) {
        // Fetch user data from Firestore
        final DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            currentUser = UserModel.fromMap(
                userDoc.data() as Map<String, dynamic>,
                uid
            );
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
          });
        }
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Calculate age based on birthDate
  int calculateAge(DateTime? birthDate) {
    if (birthDate == null) return 0;

    final DateTime today = DateTime.now();
    int age = today.year - birthDate.year;

    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }

    return age;
  }

  @override
  Widget build(BuildContext context) {
    // Theme-aware colors
    final backgroundColor = AppColors.getBackground(context);
    final textColor = AppColors.getTextPrimary(context);
    final textSecondaryColor = AppColors.getTextSecondary(context);
    final cardColor = AppColors.getCardBackground(context);

    return Scaffold(
      backgroundColor: backgroundColor,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.black
            : Colors.white,
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
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          children: [
            const SizedBox(height: 20),
            Icon(Icons.menu_book, color: AppColors.primary, size: 40),
            const SizedBox(height: 20),

            // User Profile Photo
            currentUser?.photoUrl != null && currentUser!.photoUrl!.isNotEmpty
                ? CircleAvatar(
              radius: 60,
              backgroundImage: NetworkImage(currentUser!.photoUrl!),
              backgroundColor: Colors.grey[300],
              child: currentUser?.photoUrl == null
                  ? Icon(Icons.person, size: 60, color: Colors.grey[600])
                  : null,
            )
                : CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey[300],
              child: Icon(Icons.person, size: 60, color: Colors.grey[600]),
            ),

            const SizedBox(height: 10),

            // User Name and Age
            Text(
              currentUser != null
                  ? '${currentUser!.name}, ${calculateAge(currentUser!.birthDate)}'
                  : 'User',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
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

            const Spacer(),
            Padding(
              padding: AppPaddings.screen,
              child: GestureDetector(
                onTap: () async {
                  // Call the sign out method
                  await FirebaseService.signOut();
                  // Navigate to login screen
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: Container(
                  height: 64,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(36),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.black26
                            : Colors.black12,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    "Log Out",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
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
    // Theme-aware colors
    final textSecondaryColor = AppColors.getTextSecondary(context);
    final cardColor = AppColors.getCardBackground(context);
    final iconColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.grey[300]
        : Colors.grey[800];

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 6,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.black26
                          : Colors.black12,
                    ),
                  ],
                ),
                child: Icon(icon, color: iconColor),
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
            style: TextStyle(
              fontSize: 12,
              color: textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }
}