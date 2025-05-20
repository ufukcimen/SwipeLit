// Create a new file: lib/services/settings_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/userModel.dart';

class SettingsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Load location preferences
  Future<double> getLocationRadius() async {
    try {
      if (currentUserId == null) return 10.0; // Default

      // Try to get from SharedPreferences first (faster)
      final prefs = await SharedPreferences.getInstance();
      final cachedRadius = prefs.getDouble('locationRadius');

      if (cachedRadius != null) {
        return cachedRadius;
      }

      // Fall back to Firestore
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();

      if (doc.exists && doc.data() != null) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return data['locationRadius'] ?? 10.0;
      }

      return 10.0; // Default
    } catch (e) {
      print('Error loading location radius: $e');
      return 10.0; // Default on error
    }
  }

  // Save location radius
  Future<bool> saveLocationRadius(double radius) async {
    try {
      if (currentUserId == null) return false;

      // Save to Firestore
      await _firestore.collection('users').doc(currentUserId).update({
        'locationRadius': radius,
      });

      // Save to SharedPreferences for faster access
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('locationRadius', radius);

      return true;
    } catch (e) {
      print('Error saving location radius: $e');
      return false;
    }
  }

  // Load privacy settings
  Future<Map<String, bool>> getPrivacySettings() async {
    try {
      if (currentUserId == null) {
        return {
          'profileVisible': true,
          'locationVisible': true,
          'booksVisible': true,
        };
      }

      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();

      if (doc.exists && doc.data() != null) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        Map<String, dynamic> privacySettings =
            data['privacySettings'] as Map<String, dynamic>? ?? {};

        return {
          'profileVisible': privacySettings['profileVisible'] ?? true,
          'locationVisible': privacySettings['locationVisible'] ?? true,
          'booksVisible': privacySettings['booksVisible'] ?? true,
        };
      }

      return {
        'profileVisible': true,
        'locationVisible': true,
        'booksVisible': true,
      };
    } catch (e) {
      print('Error loading privacy settings: $e');
      return {
        'profileVisible': true,
        'locationVisible': true,
        'booksVisible': true,
      };
    }
  }

  // Save privacy settings
  Future<bool> savePrivacySettings(Map<String, bool> settings) async {
    try {
      if (currentUserId == null) return false;

      await _firestore.collection('users').doc(currentUserId).update({
        'privacySettings': settings,
      });

      return true;
    } catch (e) {
      print('Error saving privacy settings: $e');
      return false;
    }
  }

  // Load notification preferences
  Future<Map<String, bool>> getNotificationPreferences() async {
    try {
      if (currentUserId == null) {
        return {
          'enabled': true,
          'matches': true,
          'messages': true,
        };
      }

      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();

      if (doc.exists && doc.data() != null) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        Map<String, dynamic> notificationPrefs =
            data['notificationPreferences'] as Map<String, dynamic>? ?? {};

        return {
          'enabled': notificationPrefs['enabled'] ?? true,
          'matches': notificationPrefs['matches'] ?? true,
          'messages': notificationPrefs['messages'] ?? true,
        };
      }

      return {
        'enabled': true,
        'matches': true,
        'messages': true,
      };
    } catch (e) {
      print('Error loading notification preferences: $e');
      return {
        'enabled': true,
        'matches': true,
        'messages': true,
      };
    }
  }

  // Save notification preferences
  Future<bool> saveNotificationPreferences(Map<String, bool> preferences) async {
    try {
      if (currentUserId == null) return false;

      await _firestore.collection('users').doc(currentUserId).update({
        'notificationPreferences': preferences,
      });

      return true;
    } catch (e) {
      print('Error saving notification preferences: $e');
      return false;
    }
  }

  // Get dark mode setting
  Future<bool> getDarkMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('darkMode') ?? false;
    } catch (e) {
      print('Error loading dark mode setting: $e');
      return false;
    }
  }

  // Save dark mode setting
  Future<bool> saveDarkMode(bool isDarkMode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('darkMode', isDarkMode);
      return true;
    } catch (e) {
      print('Error saving dark mode setting: $e');
      return false;
    }
  }

  // Get app usage statistics
  Future<Map<String, int>> getAppUsageStatistics() async {
    try {
      if (currentUserId == null) {
        return {
          'booksAdded': 0,
          'totalMatches': 0,
          'activeChats': 0,
        };
      }

      // Count user's books
      QuerySnapshot booksSnapshot = await _firestore
          .collection('books')
          .where('userId', isEqualTo: currentUserId)
          .get();

      // Count total matches
      QuerySnapshot matchesSnapshot = await _firestore
          .collection('matches')
          .where('participants', arrayContains: currentUserId)
          .get();

      // Count active chats (matches with messages)
      int activeChats = 0;
      for (var doc in matchesSnapshot.docs) {
        QuerySnapshot messagesSnapshot = await _firestore
            .collection('matches')
            .doc(doc.id)
            .collection('messages')
            .limit(1)
            .get();

        if (messagesSnapshot.docs.isNotEmpty) {
          activeChats++;
        }
      }

      return {
        'booksAdded': booksSnapshot.docs.length,
        'totalMatches': matchesSnapshot.docs.length,
        'activeChats': activeChats,
      };
    } catch (e) {
      print('Error loading app usage statistics: $e');
      return {
        'booksAdded': 0,
        'totalMatches': 0,
        'activeChats': 0,
      };
    }
  }
}

// Provider for the settings service
final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SettingsService();
});