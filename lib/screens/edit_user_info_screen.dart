/*import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../services/auth_service.dart';
import '../models/userModel.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:async';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class EditUserInfoScreen extends ConsumerStatefulWidget {
  const EditUserInfoScreen({super.key});

  @override
  ConsumerState<EditUserInfoScreen> createState() => _EditUserInfoScreenState();
}

class _EditUserInfoScreenState extends ConsumerState<EditUserInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  File? _selectedImage;
  final _imagePicker = ImagePicker();
  final _storage = FirebaseStorage.instance;
  bool _isUploadingImage = false;

  bool _isLoading = true;
  bool _isGettingLocation = false;
  String? _photoUrl;
  String? _originalPhoneNum; // To track if phone number was changed

  // Form fields
  String name = "";
  String email = "";
  String phoneNum = "";
  DateTime? birthDate;
  String gender = "Other";
  String bio = "";
  String location = "";
  List<String> interests = [];
  String otherInterest = "";
  bool showOtherInterestField = false;

  // Pre-defined interest options
  final List<String> interestOptions = [
    "Reading",
    "Music",
    "Travel",
    "Sports",
    "Movies",
    "Art",
    "Cooking",
    "Technology",
    "Fashion",
    "Gaming",
    "Photography",
    "Other"
  ];

  // Controllers
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _otherInterestController = TextEditingController();

  final List<String> genderOptions = ["Male", "Female", "Other"];

  // Updated initState method with proper provider refresh
  @override
  void initState() {
    super.initState();

    // Check if user is authenticated first
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      print("No authenticated user in initState - redirecting to login");
      // Redirect to login after the widget is built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/login');
      });
      return;
    }

    // Ensure provider is refreshed at startup - PROPERLY DELAYED
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        ref.read(userRefresherProvider.notifier).refresh();
        print("Refreshed user provider in initState (delayed)");
      } catch (e) {
        print("Error refreshing provider in initState: $e");
      }
    });

    // Load user data
    _loadUserData();
  }

  // Safe provider refresh method
  void _safeRefreshProvider() {
    // Always delay provider updates to avoid build conflicts
    Future.microtask(() {
      try {
        ref.read(userRefresherProvider.notifier).refresh();
        print("Safely refreshed user provider");
      } catch (e) {
        print("Error refreshing provider: $e");
      }
    });
  }

  @override
  void dispose() {
    _dateController.dispose();
    _locationController.dispose();
    _otherInterestController.dispose();
    super.dispose();
  }


  // Add this method to upload the image to Firebase Storage
  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception("User not authenticated");
      }

      setState(() => _isUploadingImage = true);

      print("Starting image upload for user ID: ${user.uid}");

      // Create a simpler reference path
      final storageRef = FirebaseStorage.instance.ref().child('profile_images/${user.uid}.jpg');

      print("Attempting to upload to: ${storageRef.fullPath}");

      // Convert the file to bytes
      final bytes = await _selectedImage!.readAsBytes();

      // Set metadata with content type
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
      );

      // Start the upload task
      final uploadTask = storageRef.putData(bytes, metadata);

      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        print('Upload progress: ${(progress * 100).toStringAsFixed(2)}%');
      }, onError: (error) {
        print("Upload error during streaming: $error");
      });

      // Wait for upload to complete
      await uploadTask;
      print('Upload complete');

      // Get download URL - wrapped in try-catch for better error handling
      String downloadUrl;
      try {
        downloadUrl = await storageRef.getDownloadURL();
        print("Download URL obtained: $downloadUrl");
      } catch (urlError) {
        print("Error getting download URL: $urlError");
        throw urlError;
      }

      // Update photoUrl in Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'photoUrl': downloadUrl,
      });

      // Update local state to show the new profile picture immediately
      setState(() {
        _photoUrl = downloadUrl;
        _selectedImage = null; // Clear selected image
      });

      // Safe way to refresh the provider
      _safeRefreshProvider();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile picture updated successfully!")),
      );

    } catch (e) {
      print("Error uploading image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error uploading image: $e")),
      );
    } finally {
      setState(() => _isUploadingImage = false);
    }
  }

  // Add this method to show image source selection dialog
  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt, color: AppColors.primary),
              title: Text('Take a photo'),
              onTap: () {
                Navigator.pop(context);
                _selectImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: AppColors.primary),
              title: Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                _selectImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Future<void> _selectImage(ImageSource source) async {
    try {
      final pickedImage = await _imagePicker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedImage == null) return;

      setState(() {
        _selectedImage = File(pickedImage.path);
        _isUploadingImage = true;
      });

      // Upload image to Firebase Storage
      await _uploadImage();

    } catch (e) {
      print("Error selecting image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error selecting image: $e")),
      );
    } finally {
      setState(() => _isUploadingImage = false);
    }
  }

  // Enhanced _loadUserData method to handle missing auth provider data
  void _loadUserData() {
    setState(() => _isLoading = true);

    try {
      // Get current user from Firebase Auth directly
      final user = _auth.currentUser;
      if (user == null) {
        print("No authenticated user found");
        setState(() => _isLoading = false);
        return;
      }

      print("Current user ID: ${user.uid}");

      // Always load data directly from Firestore first
      _firestore.collection('users').doc(user.uid).get().then((userData) {
        if (userData.exists) {
          final data = userData.data()!;
          print("User data found in Firestore: ${data.keys}");

          setState(() {
            name = data['name'] ?? '';
            email = data['email'] ?? '';
            phoneNum = data['phoneNum'] ?? '';
            _originalPhoneNum = phoneNum;

            if (data['birthDate'] != null) {
              try {
                birthDate = DateTime.parse(data['birthDate']);
                _dateController.text = DateFormat('yyyy-MM-dd').format(birthDate!);
              } catch (e) {
                print("Error parsing birth date: $e");
              }
            }

            gender = data['gender'] ?? 'Other';
            bio = data['bio'] ?? '';
            location = data['location'] ?? '';
            _locationController.text = location;

            // Load the photoUrl directly from Firestore
            _photoUrl = data['photoUrl'];
            print("Photo URL from Firestore: $_photoUrl");

            // Load interests
            if (data['interests'] != null) {
              interests = List<String>.from(data['interests']);

              // Setup other interests
              final otherInterests = interests.where(
                      (interest) => !interestOptions.contains(interest)
              ).toList();

              if (otherInterests.isNotEmpty) {
                if (!interests.contains("Other")) {
                  interests.add("Other"); // Make sure "Other" is selected
                }
                showOtherInterestField = true;
                otherInterest = otherInterests.join(', ');
                _otherInterestController.text = otherInterest;
              }
            }
          });

          // Now also try to get data from the provider as a backup
          try {
            final authState = ref.read(authProvider);
            final userModel = authState.value;

            if (userModel != null) {
              print("User model found in provider");

              // Only update fields that might be missing
              if (name.isEmpty) name = userModel.name;
              if (email.isEmpty) email = userModel.email;
              if (phoneNum.isEmpty) {
                phoneNum = userModel.phoneNum;
                _originalPhoneNum = userModel.phoneNum;
              }

              // Only update photoUrl if it's not already set from Firestore
              if ((_photoUrl == null || _photoUrl!.isEmpty) && userModel.photoUrl != null) {
                _photoUrl = userModel.photoUrl;
                print("Photo URL from provider: $_photoUrl");
              }
            } else {
              print("User model is null in provider");
              // Force provider refresh
              ref.read(userRefresherProvider.notifier).refresh();
            }
          } catch (providerError) {
            print("Error accessing provider: $providerError");
          }
        } else {
          print("No user document found in Firestore");
        }

        setState(() => _isLoading = false);
      }).catchError((error) {
        print("Error loading Firestore data: $error");
        setState(() => _isLoading = false);
      });
    } catch (e) {
      print("Error in _loadUserData: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAdditionalData(String uid) async {
    try {
      final userData = await _firestore.collection('users').doc(uid).get();

      if (userData.exists) {
        final data = userData.data()!;
        setState(() {
          bio = data['bio'] ?? '';

          // If photoUrl is not in UserModel but is in Firestore, use it
          if (_photoUrl == null || _photoUrl!.isEmpty) {
            _photoUrl = data['photoUrl'];
          }

          // If interests are missing in UserModel but present in Firestore
          if (data['interests'] != null && interests.isEmpty) {
            interests = List<String>.from(data['interests']);

            // Check for "Other" interests
            final otherInterests = interests.where(
                    (interest) => !interestOptions.contains(interest)
            ).toList();

            if (otherInterests.isNotEmpty) {
              if (!interests.contains("Other")) {
                interests.add("Other"); // Make sure "Other" is selected
              }
              showOtherInterestField = true;
              otherInterest = otherInterests.join(', ');
              _otherInterestController.text = otherInterest;
            }
          }
        });
      }
    } catch (e) {
      print("Error loading additional user data: $e");
    } finally {
      // Always make sure to set _isLoading to false when done
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: birthDate ?? DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != birthDate) {
      setState(() {
        birthDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  // Toggle interest selection
  void _toggleInterest(String interest) {
    setState(() {
      if (interests.contains(interest)) {
        interests.remove(interest);
        if (interest == "Other") {
          showOtherInterestField = false;
          otherInterest = "";
          _otherInterestController.clear();
        }
      } else {
        interests.add(interest);
        if (interest == "Other") {
          showOtherInterestField = true;
        }
      }
    });
  }

  // Handle "Other" interests
  void _updateOtherInterests(String value) {
    setState(() {
      otherInterest = value;
    });
  }

  // Get user's current location
  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);

    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Location permission denied")),
          );
          setState(() => _isGettingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Location permissions permanently denied, please enable in settings"),
            duration: Duration(seconds: 3),
          ),
        );
        setState(() => _isGettingLocation = false);
        return;
      }

      // Get position
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high
      );

      // Get address from position
      List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        final formattedLocation = '${place.locality}, ${place.administrativeArea}, ${place.country}';

        setState(() {
          location = formattedLocation;
          _locationController.text = formattedLocation;
        });
      }
    } catch (e) {
      print("Error getting location: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error getting location: $e")),
      );
    } finally {
      setState(() => _isGettingLocation = false);
    }
  }

  void _validateAndProceed() async {
    if (!_formKey.currentState!.validate()) return;

    // Save form values to variables
    _formKey.currentState?.save();

    // Check if phone number was actually changed
    if (phoneNum != _originalPhoneNum && phoneNum.isNotEmpty) {
      // Make sure the phone number is in the correct format (add + if missing)
      String formattedPhone = phoneNum;
      if (!formattedPhone.startsWith('+')) {
        formattedPhone = '+$formattedPhone';
      }

      // Navigate to OTP screen with callback
      final result = await Navigator.pushNamed(
          context,
          '/otpVerification',
          arguments: {
            'phoneNumber': formattedPhone,
            'fromEdit': true,
          }
      );

      // If verification was successful
      if (result == true) {
        // Update original phone
        _originalPhoneNum = formattedPhone;
        // Save the rest of the data
        _saveUserData();
      }
    } else {
      // If phone wasn't changed, just save without verification
      _saveUserData();
    }
  }

  // Replace your existing _saveUserData method with this updated version
  Future<void> _saveUserData() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState?.save();
    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error: Not authenticated")),
        );
        setState(() => _isLoading = false);
        return;
      }

      print("Saving user data for user ID: ${user.uid}");

      // Process "Other" interests if needed
      final finalInterests = List<String>.from(interests.where((i) => i != "Other"));

      if (showOtherInterestField && otherInterest.isNotEmpty) {
        // Split the "Other" interests by comma
        final customInterests = otherInterest
            .split(',')
            .map((i) => i.trim())
            .where((i) => i.isNotEmpty)
            .toList();

        // Add these interests to the list
        finalInterests.addAll(customInterests);
      }

      // Prepare data to update
      final userData = {
        'name': name,
        'email': email,
        'phoneNum': phoneNum,
        'birthDate': birthDate?.toIso8601String(),
        'gender': gender,
        'bio': bio,
        'location': location,
        'interests': finalInterests,
        'updatedAt': FieldValue.serverTimestamp(),
        // Include photoUrl if it exists
        if (_photoUrl != null) 'photoUrl': _photoUrl,
      };

      print("Saving user data: ${userData.keys}");

      // Update in Firestore
      await _firestore.collection('users').doc(user.uid).update(userData);
      print("Firestore update successful");

      // Use the safe provider refresh
      _safeRefreshProvider();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully!")),
      );

      // DO NOT CLEAR THE FORM - we want to keep the data displayed
      // but we should refresh the data from Firestore to ensure we're showing what was saved
      _loadUserData();
    } catch (e) {
      print("Error updating user data: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving changes: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Edit Info',
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w400
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(  // Ensures scrollability
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Profile picture with camera icon
              // Update your CircleAvatar widget in the build method
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    if (_isUploadingImage)
                    // Show loading indicator during upload
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey[200],
                        ),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    else
                    // Show the profile image
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              spreadRadius: 2,
                              blurRadius: 5,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: _selectedImage != null
                              ? Image.file(
                            _selectedImage!,
                            fit: BoxFit.cover,
                            width: 120,
                            height: 120,
                          )
                              : (_photoUrl != null && _photoUrl!.isNotEmpty
                              ? Image.network(
                            _photoUrl!,
                            fit: BoxFit.cover,
                            width: 120,
                            height: 120,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primary,
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              print("Error loading image: $error");
                              return Center(
                                child: Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.grey[400],
                                ),
                              );
                            },
                          )
                              : Center(
                            child: Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.grey[400],
                            ),
                          )),
                        ),
                      ),
                    // Camera icon for photo selection
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 18,
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, size: 18),
                        onPressed: _isUploadingImage ? null : _showImageSourceDialog,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Form Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 8),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Basic Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Name
                      TextFormField(
                        initialValue: name,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                        onSaved: (val) => name = val ?? '',
                      ),
                      const SizedBox(height: 20),

                      // Email
                      TextFormField(
                        initialValue: email,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        readOnly: true, // Email shouldn't be changed
                        onSaved: (val) => email = val ?? '',
                      ),
                      const SizedBox(height: 20),

                      // Phone Number
                      TextFormField(
                        initialValue: phoneNum,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          prefixIcon: Icon(Icons.phone),
                          border: OutlineInputBorder(),
                          hintText: '+1 234 567 8900',
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            // Simple phone validation
                            if (value.length < 8) {
                              return 'Please enter a valid phone number';
                            }
                          }
                          return null;
                        },
                        onSaved: (val) => phoneNum = val ?? '',
                      ),
                      if (phoneNum != _originalPhoneNum)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Phone number will be verified before saving!',
                            style: TextStyle(
                                color: AppColors.primary.shade700,
                                fontSize: 13,
                                fontWeight: FontWeight.w500
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),

                      // Birth Date
                      TextFormField(
                        controller: _dateController,
                        decoration: InputDecoration(
                          labelText: 'Birth Date',
                          prefixIcon: const Icon(Icons.calendar_today),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.date_range),
                            onPressed: () => _selectDate(context),
                          ),
                        ),
                        readOnly: true,
                        onTap: () => _selectDate(context),
                      ),
                      const SizedBox(height: 20),

                      // Gender
                      DropdownButtonFormField<String>(
                        value: gender,
                        items: genderOptions
                            .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                            .toList(),
                        onChanged: (val) => setState(() => gender = val!),
                        decoration: const InputDecoration(
                          labelText: 'Gender',
                          prefixIcon: Icon(Icons.wc),
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 30),
                      const Text(
                        'Additional Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Location with auto-detect
                      TextFormField(
                        controller: _locationController,
                        decoration: InputDecoration(
                          labelText: 'Location',
                          prefixIcon: const Icon(Icons.location_on),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: _isGettingLocation
                                ? const SizedBox(
                                width: 15,
                                height: 15,
                                child: CircularProgressIndicator(strokeWidth: 2)
                            )
                                : const Icon(Icons.my_location),
                            onPressed: _isGettingLocation ? null : _getCurrentLocation,
                          ),
                        ),
                        onSaved: (val) {
                          location = val ?? '';
                          _locationController.text = location;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Interests (Chip Selection)
                      const Text('Interests',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Wrap for interest chips
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: interestOptions.map((interest) {
                          final isSelected = interests.contains(interest);
                          return FilterChip(
                            label: Text(interest),
                            selected: isSelected,
                            onSelected: (_) => _toggleInterest(interest),
                            backgroundColor: Colors.grey[200],
                            selectedColor: AppColors.primary.withOpacity(0.2),
                            checkmarkColor: AppColors.primary,
                            labelStyle: TextStyle(
                              color: isSelected ? AppColors.primary : Colors.black87,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          );
                        }).toList(),
                      ),

                      // "Other" interest field that appears when "Other" is selected
                      if (showOtherInterestField) ...[
                        const SizedBox(height: 15),
                        TextFormField(
                          controller: _otherInterestController,
                          decoration: const InputDecoration(
                            labelText: 'Other Interests (comma separated)',
                            border: OutlineInputBorder(),
                            hintText: 'Hiking, Painting, Chess',
                          ),
                          onChanged: _updateOtherInterests,
                          onSaved: (val) {
                            if (val != null) {
                              _updateOtherInterests(val);
                            }
                          },
                        ),
                      ],

                      const SizedBox(height: 20),

                      // Bio
                      TextFormField(
                        initialValue: bio,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Bio',
                          prefixIcon: Icon(Icons.edit_note),
                          border: OutlineInputBorder(),
                          hintText: 'Tell us about yourself...',
                        ),
                        onSaved: (val) => bio = val ?? '',
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Save Button
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _validateAndProceed,
                icon: _isLoading
                    ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                )
                    : const Icon(Icons.check_circle_outline),
                label: Text(_isLoading ? 'Saving...' : 'Save Changes'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 30), // Extra space at bottom for scrolling
            ],
          ),
        ),
      ),
    );
  }}*/


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../services/auth_service.dart';
import '../models/userModel.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:async';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class EditUserInfoScreen extends ConsumerStatefulWidget {
  const EditUserInfoScreen({super.key});

  @override
  ConsumerState<EditUserInfoScreen> createState() => _EditUserInfoScreenState();
}

class _EditUserInfoScreenState extends ConsumerState<EditUserInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  File? _selectedImage;
  final _imagePicker = ImagePicker();
  final _storage = FirebaseStorage.instance;
  bool _isUploadingImage = false;

  bool _isLoading = true;
  bool _isGettingLocation = false;
  String? _photoUrl;
  String? _originalPhoneNum; // To track if phone number was changed

  // Form fields
  String name = "";
  String email = "";
  String phoneNum = "";
  DateTime? birthDate;
  String gender = "Other";
  String bio = "";
  String location = "";
  List<String> interests = [];
  String otherInterest = "";
  bool showOtherInterestField = false;

  // Pre-defined interest options
  final List<String> interestOptions = [
    "Reading",
    "Music",
    "Travel",
    "Sports",
    "Movies",
    "Art",
    "Cooking",
    "Technology",
    "Fashion",
    "Gaming",
    "Photography",
    "Other"
  ];

  // Controllers
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _otherInterestController = TextEditingController();

  final List<String> genderOptions = ["Male", "Female", "Other"];
/*
  Future<void> _testStorageAccess() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("Not authenticated");
        return;
      }

      print("Testing Firebase Storage access...");

      // Create a simple text file
      final String testString = 'Test upload ${DateTime.now()}';

      final testRef = FirebaseStorage.instance.ref()
          .child('test_uploads')
          .child('${user.uid}_${DateTime.now().millisecondsSinceEpoch}.txt');

      // Use putString instead of putData
      final uploadTask = testRef.putString(testString);

      // Wait for upload completion
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      print("Test upload successful! URL: $downloadUrl");

      // Clean up - delete the test file
      await testRef.delete();
      print("Test file deleted successfully");

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Storage test successful!"),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      print("Storage test failed: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Storage test failed: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
*/
  // Updated initState method with proper provider refresh
  @override
  void initState() {
    super.initState();


    // Check if user is authenticated first
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      print("No authenticated user in initState - redirecting to login");
      // Redirect to login after the widget is built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/login');
      });
      return;
    }

    // Ensure provider is refreshed at startup - PROPERLY DELAYED
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        ref.read(userRefresherProvider.notifier).refresh();
        print("Refreshed user provider in initState (delayed)");
      } catch (e) {
        print("Error refreshing provider in initState: $e");
      }
    });

    // Load user data
    _loadUserData();
  }

  // Safe provider refresh method
  void _safeRefreshProvider() {
    // Always delay provider updates to avoid build conflicts
    Future.microtask(() {
      try {
        ref.read(userRefresherProvider.notifier).refresh();
        print("Safely refreshed user provider");
      } catch (e) {
        print("Error refreshing provider: $e");
      }
    });
  }

  @override
  void dispose() {
    _dateController.dispose();
    _locationController.dispose();
    _otherInterestController.dispose();
    super.dispose();
  }


  // Add this method to upload the image to Firebase Storage
  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception("User not authenticated");
      }

      setState(() => _isUploadingImage = true);

      // Refresh authentication token
      await user.getIdToken(true);
      print("Authentication refreshed for user: ${user.uid}");

      // Create a structure with a subfolder for each user
      final storageRef = FirebaseStorage.instance.ref()
          .child('profile_images')
          .child(user.uid)  // Create user-specific folder
          .child('profile.jpg');

      print("Uploading to path: ${storageRef.fullPath}");

      // Use putFile directly
      final uploadTask = storageRef.putFile(_selectedImage!);

      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        print('Upload progress: ${(progress * 100).toStringAsFixed(2)}%');
      }, onError: (error) {
        print("Upload streaming error: $error");
      });

      // Wait for upload completion
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      print("Upload successful! Download URL: $downloadUrl");

      // Update Firestore with the URL
      await _firestore.collection('users').doc(user.uid).update({
        'photoUrl': downloadUrl,
      });

      // Update local state
      setState(() {
        _photoUrl = downloadUrl;
        _selectedImage = null;
      });

      // Refresh provider
      _safeRefreshProvider();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile picture updated successfully!")),
      );
    } catch (e) {
      print("Error uploading image: $e");
      if (e is FirebaseException) {
        print("Firebase Error Code: ${e.code}");
        print("Firebase Error Message: ${e.message}");
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error uploading image: $e")),
      );
    } finally {
      setState(() => _isUploadingImage = false);
    }
  }

  // Add this method to show image source selection dialog
  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt, color: AppColors.primary),
              title: Text('Take a photo'),
              onTap: () {
                Navigator.pop(context);
                _selectImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: AppColors.primary),
              title: Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                _selectImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Future<void> _selectImage(ImageSource source) async {
    try {
      final pickedImage = await _imagePicker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedImage == null) return;

      setState(() {
        _selectedImage = File(pickedImage.path);
        _isUploadingImage = true;
      });

      // Upload image to Firebase Storage
      await _uploadImage();

    } catch (e) {
      print("Error selecting image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error selecting image: $e")),
      );
    } finally {
      setState(() => _isUploadingImage = false);
    }
  }

  // Enhanced _loadUserData method to handle missing auth provider data
  void _loadUserData() {
    setState(() => _isLoading = true);

    try {
      // Get current user from Firebase Auth directly
      final user = _auth.currentUser;
      if (user == null) {
        print("No authenticated user found");
        setState(() => _isLoading = false);
        return;
      }

      print("Current user ID: ${user.uid}");

      // Always load data directly from Firestore first
      _firestore.collection('users').doc(user.uid).get().then((userData) {
        if (userData.exists) {
          final data = userData.data()!;
          print("User data found in Firestore: ${data.keys}");

          setState(() {
            name = data['name'] ?? '';
            email = data['email'] ?? '';
            phoneNum = data['phoneNum'] ?? '';
            _originalPhoneNum = phoneNum;

            if (data['birthDate'] != null) {
              try {
                birthDate = DateTime.parse(data['birthDate']);
                _dateController.text = DateFormat('yyyy-MM-dd').format(birthDate!);
              } catch (e) {
                print("Error parsing birth date: $e");
              }
            }

            gender = data['gender'] ?? 'Other';
            bio = data['bio'] ?? '';
            location = data['location'] ?? '';
            _locationController.text = location;

            // Load the photoUrl directly from Firestore
            _photoUrl = data['photoUrl'];
            print("Photo URL from Firestore: $_photoUrl");

            // Load interests - Deduplicate them using a Set
            if (data['interests'] != null) {
              // Get unique interests
              final List<dynamic> rawInterests = data['interests'];
              final Set<String> uniqueInterests = Set<String>.from(rawInterests.cast<String>());
              interests = uniqueInterests.toList();

              // Setup other interests
              final otherInterests = interests.where(
                      (interest) => !interestOptions.contains(interest)
              ).toList();

              if (otherInterests.isNotEmpty) {
                if (!interests.contains("Other")) {
                  interests.add("Other"); // Make sure "Other" is selected
                }
                showOtherInterestField = true;
                otherInterest = otherInterests.join(', ');
                _otherInterestController.text = otherInterest;
              }
            }
          });

          // Now also try to get data from the provider as a backup
          try {
            final authState = ref.read(authProvider);
            final userModel = authState.value;

            if (userModel != null) {
              print("User model found in provider");

              // Only update fields that might be missing
              if (name.isEmpty) name = userModel.name;
              if (email.isEmpty) email = userModel.email;
              if (phoneNum.isEmpty) {
                phoneNum = userModel.phoneNum;
                _originalPhoneNum = userModel.phoneNum;
              }

              // Only update photoUrl if it's not already set from Firestore
              if ((_photoUrl == null || _photoUrl!.isEmpty) && userModel.photoUrl != null) {
                _photoUrl = userModel.photoUrl;
                print("Photo URL from provider: $_photoUrl");
              }
            } else {
              print("User model is null in provider");
              // Force provider refresh
              ref.read(userRefresherProvider.notifier).refresh();
            }
          } catch (providerError) {
            print("Error accessing provider: $providerError");
          }
        } else {
          print("No user document found in Firestore");
        }

        setState(() => _isLoading = false);
      }).catchError((error) {
        print("Error loading Firestore data: $error");
        setState(() => _isLoading = false);
      });
    } catch (e) {
      print("Error in _loadUserData: $e");
      setState(() => _isLoading = false);
    }
  }


  Future<void> _loadAdditionalData(String uid) async {
    try {
      final userData = await _firestore.collection('users').doc(uid).get();

      if (userData.exists) {
        final data = userData.data()!;
        setState(() {
          bio = data['bio'] ?? '';

          // If photoUrl is not in UserModel but is in Firestore, use it
          if (_photoUrl == null || _photoUrl!.isEmpty) {
            _photoUrl = data['photoUrl'];
          }

          // If interests are missing in UserModel but present in Firestore
          if (data['interests'] != null && interests.isEmpty) {
            interests = List<String>.from(data['interests']);

            // Check for "Other" interests
            final otherInterests = interests.where(
                    (interest) => !interestOptions.contains(interest)
            ).toList();

            if (otherInterests.isNotEmpty) {
              if (!interests.contains("Other")) {
                interests.add("Other"); // Make sure "Other" is selected
              }
              showOtherInterestField = true;
              otherInterest = otherInterests.join(', ');
              _otherInterestController.text = otherInterest;
            }
          }
        });
      }
    } catch (e) {
      print("Error loading additional user data: $e");
    } finally {
      // Always make sure to set _isLoading to false when done
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: birthDate ?? DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != birthDate) {
      setState(() {
        birthDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  // Toggle interest selection
  void _toggleInterest(String interest) {
    setState(() {
      if (interests.contains(interest)) {
        interests.remove(interest);
        if (interest == "Other") {
          showOtherInterestField = false;
          otherInterest = "";
          _otherInterestController.clear();
        }
      } else {
        interests.add(interest);
        if (interest == "Other") {
          showOtherInterestField = true;
        }
      }
    });
  }

  // Handle "Other" interests
  void _updateOtherInterests(String value) {
    setState(() {
      otherInterest = value;
    });
  }

  // Get user's current location
  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);

    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Location permission denied")),
          );
          setState(() => _isGettingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Location permissions permanently denied, please enable in settings"),
            duration: Duration(seconds: 3),
          ),
        );
        setState(() => _isGettingLocation = false);
        return;
      }

      // Get position
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high
      );

      // Get address from position
      List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        final formattedLocation = '${place.locality}, ${place.administrativeArea}, ${place.country}';

        setState(() {
          location = formattedLocation;
          _locationController.text = formattedLocation;
        });
      }
    } catch (e) {
      print("Error getting location: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error getting location: $e")),
      );
    } finally {
      setState(() => _isGettingLocation = false);
    }
  }

  void _validateAndProceed() async {
    if (!_formKey.currentState!.validate()) return;

    // Save form values to variables
    _formKey.currentState?.save();

    // Check if phone number was actually changed
    if (phoneNum != _originalPhoneNum && phoneNum.isNotEmpty) {
      // Make sure the phone number is in the correct format (add + if missing)
      String formattedPhone = phoneNum;
      if (!formattedPhone.startsWith('+')) {
        formattedPhone = '+$formattedPhone';
      }

      // Navigate to OTP screen with callback
      final result = await Navigator.pushNamed(
          context,
          '/otpVerification',
          arguments: {
            'phoneNumber': formattedPhone,
            'fromEdit': true,
          }
      );

      // If verification was successful
      if (result == true) {
        // Update original phone
        _originalPhoneNum = formattedPhone;
        // Save the rest of the data
        _saveUserData();
      }
    } else {
      // If phone wasn't changed, just save without verification
      _saveUserData();
    }
  }

  // Replace your existing _saveUserData method with this updated version
  Future<void> _saveUserData() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState?.save();
    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error: Not authenticated")),
        );
        setState(() => _isLoading = false);
        return;
      }

      print("Saving user data for user ID: ${user.uid}");

      // Process interests to remove duplicates
      final Set<String> uniqueInterests = {};

      // Add regular interests (excluding "Other")
      interests.where((i) => i != "Other").forEach((interest) {
        uniqueInterests.add(interest);
      });

      // Process "Other" interests if needed
      if (showOtherInterestField && otherInterest.isNotEmpty) {
        // Split the "Other" interests by comma and add them to the set
        otherInterest
            .split(',')
            .map((i) => i.trim())
            .where((i) => i.isNotEmpty)
            .forEach((customInterest) {
          uniqueInterests.add(customInterest);
        });
      }

      // Convert back to list for Firestore
      final finalInterests = uniqueInterests.toList();

      // Prepare data to update
      final userData = {
        'name': name,
        'email': email,
        'phoneNum': phoneNum,
        'birthDate': birthDate?.toIso8601String(),
        'gender': gender,
        'bio': bio,
        'location': location,
        'interests': finalInterests,
        'updatedAt': FieldValue.serverTimestamp(),
        // Include photoUrl if it exists
        if (_photoUrl != null) 'photoUrl': _photoUrl,
      };

      print("Saving user data: ${userData.keys}");
      print("Unique interests being saved: $finalInterests");

      // Update in Firestore
      await _firestore.collection('users').doc(user.uid).update(userData);
      print("Firestore update successful");

      // Use the safe provider refresh
      _safeRefreshProvider();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully!")),
      );

      // DO NOT CLEAR THE FORM - we want to keep the data displayed
      // but we should refresh the data from Firestore to ensure we're showing what was saved
      _loadUserData();
    } catch (e) {
      print("Error updating user data: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving changes: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    // Get theme-aware colors
    final backgroundColor = AppColors.getBackground(context);
    final textColor = AppColors.getTextPrimary(context);
    final textSecondaryColor = AppColors.getTextSecondary(context);
    final cardColor = AppColors.getCardBackground(context);
    final inputBorderColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.grey[700]
        : Colors.grey[300];

    return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
        title: const Text(
        'Edit Info',
        style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w400
    ),
    ),
    backgroundColor: AppColors.primary,
    elevation: 0,
    ),
    body: _isLoading
    ? Center(child: CircularProgressIndicator(color: AppColors.primary))
        : SingleChildScrollView(  // Ensures scrollability
    child: Padding(
    padding: const EdgeInsets.all(20),
    child: Column(
    children: [
    // Profile picture with camera icon
    Center(
    child: Stack(
    alignment: Alignment.bottomRight,
    children: [
    if (_isUploadingImage)
    Container(
    width: 120,
    height: 120,
    decoration: BoxDecoration(
    shape: BoxShape.circle,
    color: Theme.of(context).brightness == Brightness.dark
    ? Colors.grey[800]
        : Colors.grey[200],
    ),
    child: Center(
    child: CircularProgressIndicator(
    color: AppColors.primary,
    ),
    ),
    )
    else
    Container(
    width: 120,
    height: 120,
    decoration: BoxDecoration(
    shape: BoxShape.circle,
    border: Border.all(color: cardColor, width: 4),
    boxShadow: [
    BoxShadow(
    color: Theme.of(context).brightness == Brightness.dark
    ? Colors.black26
        : Colors.grey.withOpacity(0.3),
    spreadRadius: 2,
    blurRadius: 5,
    ),
    ],
    ),
    child: ClipOval(
    child: _selectedImage != null
    ? Image.file(
    _selectedImage!,
    fit: BoxFit.cover,
    width: 120,
    height: 120,
    )
        : (_photoUrl != null && _photoUrl!.isNotEmpty
    ? Image.network(
    _photoUrl!,
    fit: BoxFit.cover,
    width: 120,
    height: 120,
    loadingBuilder: (context, child, loadingProgress) {
    if (loadingProgress == null) return child;
    return Center(
    child: CircularProgressIndicator(
    color: AppColors.primary,
    value: loadingProgress.expectedTotalBytes != null
    ? loadingProgress.cumulativeBytesLoaded /
    loadingProgress.expectedTotalBytes!
        : null,
    ),
    );
    },
    errorBuilder: (context, error, stackTrace) {
    print("Error loading image: $error");
    return Center(
    child: Icon(
    Icons.person,
    size: 60,
    color: textSecondaryColor,
    ),
    );
    },
    )
        : Center(
    child: Icon(
    Icons.person,
    size: 60,
    color: textSecondaryColor,
    ),
    )),
    ),
    ),
    // Camera icon for photo selection
    CircleAvatar(
    backgroundColor: cardColor,
    radius: 18,
    child: IconButton(
    icon: Icon(Icons.camera_alt, size: 18, color: AppColors.primary),
    onPressed: _isUploadingImage ? null : _showImageSourceDialog,
    ),
    ),
    ],
    ),
    ),
    const SizedBox(height: 30),

    // Form Card
    Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
    BoxShadow(
    color: Theme.of(context).brightness == Brightness.dark
    ? Colors.black12
        : Colors.black12,
    blurRadius: 8,
    ),
    ],
    ),
    child: Form(
    key: _formKey,
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Text(
    'Basic Information',
    style: TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: textColor,
    ),
    ),
    const SizedBox(height: 15),

    // Name
    TextFormField(
    initialValue: name,
    style: TextStyle(color: textColor),
    decoration: InputDecoration(
    labelText: 'Name',
    labelStyle: TextStyle(color: textSecondaryColor),
    prefixIcon: Icon(Icons.person, color: AppColors.primary),
    border: OutlineInputBorder(
    borderSide: BorderSide(color: inputBorderColor!),
    ),
    enabledBorder: OutlineInputBorder(
    borderSide: BorderSide(color: inputBorderColor),
    ),
    focusedBorder: OutlineInputBorder(
    borderSide: BorderSide(color: AppColors.primary, width: 2),
    ),
    ),
    validator: (value) {
    if (value == null || value.isEmpty) {
    return 'Please enter your name';
    }
    return null;
    },
    onSaved: (val) => name = val ?? '',
    ),
    const SizedBox(height: 20),

    // Email
    TextFormField(
    initialValue: email,
    style: TextStyle(color: textColor),
    decoration: InputDecoration(
    labelText: 'Email',
    labelStyle: TextStyle(color: textSecondaryColor),
    prefixIcon: Icon(Icons.email, color: AppColors.primary),
    border: OutlineInputBorder(
    borderSide: BorderSide(color: inputBorderColor),
    ),
    enabledBorder: OutlineInputBorder(
    borderSide: BorderSide(color: inputBorderColor),
    ),
    focusedBorder: OutlineInputBorder(
    borderSide: BorderSide(color: AppColors.primary, width: 2),
    ),
    ),
    keyboardType: TextInputType.emailAddress,
    readOnly: true, // Email shouldn't be changed
    onSaved: (val) => email = val ?? '',
    ),
    const SizedBox(height: 20),

    // Phone Number
    TextFormField(
    initialValue: phoneNum,
    style: TextStyle(color: textColor),
    decoration: InputDecoration(
    labelText: 'Phone Number',
    labelStyle: TextStyle(color: textSecondaryColor),
    hintText: '+1 234 567 8900',
    hintStyle: TextStyle(color: textSecondaryColor.withOpacity(0.7)),
    prefixIcon: Icon(Icons.phone, color: AppColors.primary),
    border: OutlineInputBorder(
    borderSide: BorderSide(color: inputBorderColor),
    ),
    enabledBorder: OutlineInputBorder(
    borderSide: BorderSide(color: inputBorderColor),
    ),
    focusedBorder: OutlineInputBorder(
    borderSide: BorderSide(color: AppColors.primary, width: 2),
    ),
    ),
    keyboardType: TextInputType.phone,
    validator: (value) {
    if (value != null && value.isNotEmpty) {
    // Simple phone validation
    if (value.length < 8) {
    return 'Please enter a valid phone number';
    }
    }
    return null;
    },
    onSaved: (val) => phoneNum = val ?? '',
    ),
    if (phoneNum != _originalPhoneNum)
    Padding(
    padding: const EdgeInsets.only(top: 8.0),
    child: Text(
    'Phone number will be verified before saving!',
    style: TextStyle(
    color: AppColors.primary,
    fontSize: 13,
    fontWeight: FontWeight.w500
    ),
    ),
    ),
    const SizedBox(height: 20),

    // Birth Date
    TextFormField(
    controller: _dateController,
    style: TextStyle(color: textColor),
    decoration: InputDecoration(
    labelText: 'Birth Date',
    labelStyle: TextStyle(color: textSecondaryColor),
    prefixIcon: Icon(Icons.calendar_today, color: AppColors.primary),
    suffixIcon: IconButton(
    icon: Icon(Icons.date_range, color: AppColors.primary),
    onPressed: () => _selectDate(context),
    ),
    border: OutlineInputBorder(
    borderSide: BorderSide(color: inputBorderColor),
    ),
    enabledBorder: OutlineInputBorder(
    borderSide: BorderSide(color: inputBorderColor),
    ),
    focusedBorder: OutlineInputBorder(
    borderSide: BorderSide(color: AppColors.primary, width: 2),
    ),
    ),
    readOnly: true,
    onTap: () => _selectDate(context),
    ),
    const SizedBox(height: 20),

    // Gender
    DropdownButtonFormField<String>(
    value: gender,
    dropdownColor: cardColor,
    style: TextStyle(color: textColor),
    items: genderOptions
        .map((g) => DropdownMenuItem(
    value: g,
        child: Text(g, style: TextStyle(color: textColor))
    ))
        .toList(),
      onChanged: (val) => setState(() => gender = val!),
      decoration: InputDecoration(
        labelText: 'Gender',
        labelStyle: TextStyle(color: textSecondaryColor),
        prefixIcon: Icon(Icons.wc, color: AppColors.primary),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: inputBorderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: inputBorderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    ),

      const SizedBox(height: 30),
      Text(
        'Additional Information',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
      const SizedBox(height: 15),

      // Location with auto-detect
      TextFormField(
        controller: _locationController,
        style: TextStyle(color: textColor),
        decoration: InputDecoration(
          labelText: 'Location',
          labelStyle: TextStyle(color: textSecondaryColor),
          prefixIcon: Icon(Icons.location_on, color: AppColors.primary),
          border: OutlineInputBorder(
            borderSide: BorderSide(color: inputBorderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: inputBorderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.primary, width: 2),
          ),
          suffixIcon: IconButton(
            icon: _isGettingLocation
                ? SizedBox(
              width: 15,
              height: 15,
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2,
              ),
            )
                : Icon(Icons.my_location, color: AppColors.primary),
            onPressed: _isGettingLocation ? null : _getCurrentLocation,
          ),
        ),
        onSaved: (val) {
          location = val ?? '';
          _locationController.text = location;
        },
      ),
      const SizedBox(height: 20),

      // Interests (Chip Selection)
      Text(
        'Interests',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
      const SizedBox(height: 10),

      // Wrap for interest chips
      Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        children: interestOptions.map((interest) {
          final isSelected = interests.contains(interest);
          return FilterChip(
            label: Text(
              interest,
              style: TextStyle(
                color: isSelected
                    ? AppColors.primary
                    : textColor,
                fontWeight: isSelected
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
            selected: isSelected,
            onSelected: (_) => _toggleInterest(interest),
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[800]
                : Colors.grey[200],
            selectedColor: AppColors.primary.withOpacity(0.2),
            checkmarkColor: AppColors.primary,
          );
        }).toList(),
      ),

      // "Other" interest field that appears when "Other" is selected
      if (showOtherInterestField) ...[
        const SizedBox(height: 15),
        TextFormField(
          controller: _otherInterestController,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            labelText: 'Other Interests (comma separated)',
            labelStyle: TextStyle(color: textSecondaryColor),
            hintText: 'Hiking, Painting, Chess',
            hintStyle: TextStyle(color: textSecondaryColor.withOpacity(0.7)),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: inputBorderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: inputBorderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
          onChanged: _updateOtherInterests,
          onSaved: (val) {
            if (val != null) {
              _updateOtherInterests(val);
            }
          },
        ),
      ],

      const SizedBox(height: 20),

      // Bio
      TextFormField(
        initialValue: bio,
        style: TextStyle(color: textColor),
        maxLines: 3,
        decoration: InputDecoration(
          labelText: 'Bio',
          labelStyle: TextStyle(color: textSecondaryColor),
          hintText: 'Tell us about yourself...',
          hintStyle: TextStyle(color: textSecondaryColor.withOpacity(0.7)),
          prefixIcon: Icon(Icons.edit_note, color: AppColors.primary),
          border: OutlineInputBorder(
            borderSide: BorderSide(color: inputBorderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: inputBorderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
        onSaved: (val) => bio = val ?? '',
      ),
    ],
    ),
    ),
    ),

      const SizedBox(height: 40),

      // Save Button
      ElevatedButton.icon(
        onPressed: _isLoading ? null : _validateAndProceed,
        icon: _isLoading
            ? SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        )
            : const Icon(Icons.check_circle_outline),
        label: Text(_isLoading ? 'Saving...' : 'Save Changes'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      const SizedBox(height: 30), // Extra space at bottom for scrolling
    ],
    ),
    ),
    ),
    );
  }
}
