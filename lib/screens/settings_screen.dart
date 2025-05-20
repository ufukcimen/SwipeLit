// Update your settings_screen.dart file

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/constants.dart';
import '../services/settings_service.dart';
import '../services/auth_service.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  // Settings variables
  double _locationRadius = 10.0;
  bool _isLoading = true;

  // Privacy settings
  bool _profileVisible = true;
  bool _locationVisible = true;
  bool _booksVisible = true;

  // Notification settings
  bool _notificationsEnabled = true;
  bool _newMatchNotifications = true;
  bool _messageNotifications = true;

  // Theme settings
  bool _isDarkMode = false;

  // App statistics
  int _booksAdded = 0;
  int _totalMatches = 0;
  int _activeChats = 0;

  @override
  void initState() {
    super.initState();

    // Load the current theme setting first
    _loadThemeSetting();

    // Then load all other settings
    _loadAllSettings();
  }

// Add this method to load just the theme setting
  Future<void> _loadThemeSetting() async {
    final isDarkMode = ref.read(themeProvider);
    setState(() {
      _isDarkMode = isDarkMode;
    });
  }

  // Called after saving location radius
  void _notifyLocationRadiusChanged() {
    // Refresh the user provider
    ref.read(userRefresherProvider.notifier).refresh();
  }

// Called after saving privacy settings
  void _notifyPrivacySettingsChanged() {
    // Refresh the user provider
    ref.read(userRefresherProvider.notifier).refresh();
  }

  void _toggleDarkMode(bool value) async {
    setState(() {
      _isDarkMode = value;
    });

    // Use the provider to update the theme
    final themeNotifier = ref.read(themeProvider.notifier);
    await themeNotifier.setDarkMode(value);

    // Show feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Theme updated to ${value ? 'dark' : 'light'} mode'),
          backgroundColor: AppColors.primary,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  // Load all settings
  Future<void> _loadAllSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final settingsService = ref.read(settingsServiceProvider);

      // Load all settings in parallel for better performance
      final results = await Future.wait([
        settingsService.getLocationRadius(),
        settingsService.getPrivacySettings(),
        settingsService.getNotificationPreferences(),
        settingsService.getDarkMode(),
        settingsService.getAppUsageStatistics(),
      ]);

      // Process results
      final radius = results[0] as double;
      final privacySettings = results[1] as Map<String, bool>;
      final notificationPrefs = results[2] as Map<String, bool>;
      final darkMode = results[3] as bool;
      final statistics = results[4] as Map<String, int>;

      // Update state
      setState(() {
        _locationRadius = radius;

        _profileVisible = privacySettings['profileVisible'] ?? true;
        _locationVisible = privacySettings['locationVisible'] ?? true;
        _booksVisible = privacySettings['booksVisible'] ?? true;

        _notificationsEnabled = notificationPrefs['enabled'] ?? true;
        _newMatchNotifications = notificationPrefs['matches'] ?? true;
        _messageNotifications = notificationPrefs['messages'] ?? true;

        _isDarkMode = darkMode;

        _booksAdded = statistics['booksAdded'] ?? 0;
        _totalMatches = statistics['totalMatches'] ?? 0;
        _activeChats = statistics['activeChats'] ?? 0;

        _isLoading = false;
      });
    } catch (e) {
      print('Error loading settings: $e');
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading settings. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Save location radius
  Future<void> _saveLocationRadius(double value) async {
    setState(() {
      _locationRadius = value;
    });

    final settingsService = ref.read(settingsServiceProvider);
    final success = await settingsService.saveLocationRadius(value);

    if (success) {
      // Notify that location radius has changed
      _notifyLocationRadiusChanged();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Location preferences saved successfully'),
          backgroundColor: AppColors.primary,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save settings. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Save privacy settings
  Future<void> _savePrivacySettings() async {
    final settings = {
      'profileVisible': _profileVisible,
      'locationVisible': _locationVisible,
      'booksVisible': _booksVisible,
    };

    final settingsService = ref.read(settingsServiceProvider);
    final success = await settingsService.savePrivacySettings(settings);

    if (mounted) {
      if (success) {
        // Notify that privacy settings have changed
        _notifyPrivacySettingsChanged();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Privacy settings saved'),
            backgroundColor: AppColors.primary,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save settings'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Save notification preferences
  Future<void> _saveNotificationPreferences() async {
    final preferences = {
      'enabled': _notificationsEnabled,
      'matches': _newMatchNotifications,
      'messages': _messageNotifications,
    };

    final settingsService = ref.read(settingsServiceProvider);
    final success = await settingsService.saveNotificationPreferences(preferences);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notification preferences saved'),
            backgroundColor: AppColors.primary,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save preferences'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  // Save theme settings
  Future<void> _saveThemeSettings() async {
    try {
      // Update the theme through the provider
      final themeNotifier = ref.read(themeProvider.notifier);
      await themeNotifier.setDarkMode(_isDarkMode);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Theme setting saved'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      print('Error saving theme settings: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save theme settings'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Delete user account
  Future<void> _deleteAccount() async {
    // Show confirmation dialog
    bool confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Account'),
        content: Text(
          'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently deleted.',
        ),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    ) ?? false;

    if (!confirmed) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    try {
      await FirebaseService.signOut();

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();

        // Navigate to login screen
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();

        print('Error during sign out: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to sign out: ${e.toString()}')),
        );
      }
    }
  }

  // UI for privacy settings
  Widget _buildPrivacySettings() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            SwitchListTile(
              title: Text('Profile Visibility'),
              subtitle: Text('Allow other users to see your profile information'),
              value: _profileVisible,
              activeColor: AppColors.primary,
              onChanged: (value) {
                setState(() {
                  _profileVisible = value;
                });
              },
            ),
            Divider(),
            SwitchListTile(
              title: Text('Location Visibility'),
              subtitle: Text('Show your approximate location to matched users'),
              value: _locationVisible,
              activeColor: AppColors.primary,
              onChanged: (value) {
                setState(() {
                  _locationVisible = value;
                });
              },
            ),
            Divider(),
            SwitchListTile(
              title: Text('Book Collection Visibility'),
              subtitle: Text('Let others browse your uploaded books'),
              value: _booksVisible,
              activeColor: AppColors.primary,
              onChanged: (value) {
                setState(() {
                  _booksVisible = value;
                });
              },
            ),
            SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: _savePrivacySettings,
                child: Text('Save Privacy Settings',
                    style: AppTextStyles.buttonText.copyWith(fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // UI for notification settings
  Widget _buildNotificationSettings() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notification Preferences',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            SwitchListTile(
              title: Text('Enable Notifications'),
              value: _notificationsEnabled,
              activeColor: AppColors.primary,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
              },
            ),
            Divider(),
            SwitchListTile(
              title: Text('New Book Matches'),
              subtitle: Text('Get notified when someone matches with your book'),
              value: _newMatchNotifications && _notificationsEnabled,
              activeColor: AppColors.primary,
              onChanged: _notificationsEnabled
                  ? (value) {
                setState(() {
                  _newMatchNotifications = value;
                });
              }
                  : null,
            ),
            SwitchListTile(
              title: Text('New Messages'),
              subtitle: Text('Get notified when you receive new messages'),
              value: _messageNotifications && _notificationsEnabled,
              activeColor: AppColors.primary,
              onChanged: _notificationsEnabled
                  ? (value) {
                setState(() {
                  _messageNotifications = value;
                });
              }
                  : null,
            ),
            SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: _saveNotificationPreferences,
                child: Text('Save Preferences',
                    style: AppTextStyles.buttonText.copyWith(fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // UI for theme settings
  Widget _buildThemeSettings() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Display Theme',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Choose your preferred app theme',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 16),
            SwitchListTile(
              title: Text('Dark Mode'),
              subtitle: Text('Use darker colors for the app interface'),
              value: _isDarkMode,
              activeColor: AppColors.primary,
              onChanged: _toggleDarkMode, // Use the new helper method
            ),
          ],
        ),
      ),
    );
  }

  // UI for app statistics
  Widget _buildAppStatistics() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: AppColors.primary))
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Activity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            _buildStatItem(Icons.book, 'Books Added', _booksAdded.toString()),
            Divider(),
            _buildStatItem(Icons.people, 'Total Matches', _totalMatches.toString()),
            Divider(),
            _buildStatItem(Icons.chat, 'Active Conversations', _activeChats.toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 28),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text("Settings", style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w400
        ),),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadAllSettings,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Location preference
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Location Preferences',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Set maximum distance for book matches',
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(Icons.location_on, color: AppColors.primary),
                            Expanded(
                              child: Slider(
                                value: _locationRadius,
                                min: 1,
                                max: 50,
                                divisions: 49,
                                label: '${_locationRadius.round()} km',
                                onChanged: (value) {
                                  setState(() {
                                    _locationRadius = value;
                                  });
                                },
                              ),
                            ),
                            Text('${_locationRadius.round()} km'),
                          ],
                        ),
                        SizedBox(height: 16),
                        Center(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                            ),
                            onPressed: () => _saveLocationRadius(_locationRadius),
                            child: Text('Save Location Preference',
                                style: AppTextStyles.buttonText.copyWith(fontSize: 14)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 20),

                // Privacy Settings
                _buildPrivacySettings(),

                SizedBox(height: 20),

                // Notification Settings
                _buildNotificationSettings(),

                SizedBox(height: 20),

                // Theme Settings
                _buildThemeSettings(),

                SizedBox(height: 20),

                // App Statistics
                _buildAppStatistics(),

                SizedBox(height: 32),

                // Delete account
                Card(
                  color: Colors.red[50],
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Delete Account',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Deleting your account will remove all of your data permanently. This action cannot be undone.',
                          style: TextStyle(
                            color: Colors.red[700],
                          ),
                        ),
                        SizedBox(height: 16),
                        Center(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                            onPressed: _deleteAccount,
                            child: Text('Delete'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}