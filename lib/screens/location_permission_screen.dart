import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:swipelit/utils/constants.dart';

class LocationPermissionScreen extends StatefulWidget {
  const LocationPermissionScreen({super.key});

  @override
  State<LocationPermissionScreen> createState() => _LocationPermissionScreenState();
}

class _LocationPermissionScreenState extends State<LocationPermissionScreen> with WidgetsBindingObserver {
  bool openedSettings = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Detect when user returns from settings
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed && openedSettings) {
      var status = await Permission.location.status;
      if (status.isGranted && mounted) {
        Navigator.pushReplacementNamed(context, '/bookDiscovery');
      }
      openedSettings = false;
    }
  }

  Future<void> _requestLocationPermission() async {
    var status = await Permission.location.request();

    if (status.isGranted) {
      Navigator.pushReplacementNamed(context, '/bookDiscovery');
    } else if (status.isDenied || status.isPermanentlyDenied) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Location Required"),
          content: const Text("You need to enable location access to use SwipeLit."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Close"),
            ),
            TextButton(
              onPressed: () async {
                openedSettings = true;
                Navigator.of(context).pop();
                await openAppSettings();
              },
              child: const Text("Open Settings"),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),

            Image.asset(
              'assets/icons/location_icon.png',
              height: 150,
              errorBuilder: (_, __, ___) => const Icon(Icons.location_on, size: 120, color: Colors.green),
            ),

            const SizedBox(height: 32),

            const Text(
              "Enable Your Location",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 12),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                "Choose your location to start find people around you",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ),

            const SizedBox(height: 40),

            Padding(
              padding: AppPaddings.screen,
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _requestLocationPermission,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(36),
                    ),
                  ),
                  child: const Text(
                    "Allow Location Access",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            const Spacer(),
          ],
        ),
      ),
    );
  }
}
