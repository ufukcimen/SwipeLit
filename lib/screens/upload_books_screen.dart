import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../utils/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path/path.dart' as path;
import '../providers/library_provider.dart'; // Import the provider

class UploadBookScreen extends ConsumerStatefulWidget {
  const UploadBookScreen({super.key});

  @override
  ConsumerState<UploadBookScreen> createState() => _UploadBookScreenState();
}

class _UploadBookScreenState extends ConsumerState<UploadBookScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _titleController = TextEditingController();
  final _ageController = TextEditingController();
  final _locationController = TextEditingController();

  // Predefined book categories
  final List<String> _categories = [
    'Fiction',
    'Non-Fiction',
    'Science Fiction',
    'Fantasy',
    'Mystery',
    'Romance',
    'Biography',
    'History',
    'Science',
    'Philosophy',
    'Self-Help',
    'Children',
    'Comics',
    'Poetry',
    'Other'
  ];

  String _selectedCategory = 'Fiction';
  bool _isLoading = false;
  bool _isGettingLocation = false;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    // Try to get user's location when screen loads
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _ageController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // Get the user's current location
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
    });

    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permission permanently denied');
      }

      // Get current position
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Convert coordinates to address
      final List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final Placemark place = placemarks.first;
        final String address = _formatAddress(place);

        setState(() {
          _locationController.text = address;
          _isGettingLocation = false;
        });
      } else {
        throw Exception('Could not get address from coordinates');
      }
    } catch (e) {
      print('Error getting location: $e');
      setState(() {
        _isGettingLocation = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not get location: ${e.toString()}'),
            action: SnackBarAction(
              label: 'Try Again',
              onPressed: _getCurrentLocation,
            ),
          ),
        );
      }
    }
  }

  // Format address from Placemark
  String _formatAddress(Placemark place) {
    final List<String> addressParts = [];

    if (place.locality != null && place.locality!.isNotEmpty) {
      addressParts.add(place.locality!);
    }

    if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
      addressParts.add(place.administrativeArea!);
    }

    if (place.country != null && place.country!.isNotEmpty) {
      addressParts.add(place.country!);
    }

    return addressParts.join(', ');
  }

  Future<void> _pickImage() async {
    var status = await Permission.photos.request();

    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permission to access photos was denied')),
        );
      }
      return;
    }

    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200, // Optimize image size
      maxHeight: 1200,
      imageQuality: 85, // Reduce quality slightly for better upload
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    } else {
      print("No image selected.");
    }
  }

  Future<void> _uploadBook() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a book cover image')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get current user and refresh token
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Refresh token for better authentication
      await currentUser.getIdToken(true);

      // Get owner name
      final ownerName = currentUser.displayName ?? 'Me';

      // Create a properly organized filename
      final String fileName = '${currentUser.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Create a properly structured reference path
      final Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('books')
          .child(currentUser.uid)
          .child(fileName);

      print("Uploading book to path: ${storageRef.fullPath}");

      // Add metadata for content type
      final SettableMetadata metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'userId': currentUser.uid},
      );

      // Create the upload task and monitor progress
      final UploadTask uploadTask = storageRef.putFile(_selectedImage!, metadata);

      // Monitor progress for debugging
      uploadTask.snapshotEvents.listen((snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        print('Book upload progress: ${(progress * 100).toStringAsFixed(2)}%');
      }, onError: (error) {
        print("Upload error: $error");
      });

      // Wait for the upload to complete
      final TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() {});

      // Get download URL
      final String imageUrl = await taskSnapshot.ref.getDownloadURL();
      print("Book image uploaded: $imageUrl");

      // Create the book object
      final book = {
        'title': _titleController.text.trim(),
        'ownerName': ownerName,
        'age': int.tryParse(_ageController.text) ?? 0,
        'location': _locationController.text,
        'category': _selectedCategory,
        'imageUrl': imageUrl,
        'userId': currentUser.uid,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Add book to Firestore
      final docRef = await FirebaseFirestore.instance.collection('books').add(book);
      final bookId = docRef.id;
      print("Book added with ID: $bookId");

      // Update user's uploadedBooks array in Firestore
      final userRef = FirebaseFirestore.instance.collection('users').doc(currentUser.uid);

      // Get current user data to check if uploadedBooks exists
      final userData = await userRef.get();

      if (userData.exists) {
        // Use arrayUnion to add the book ID to the user's uploadedBooks array
        await userRef.update({
          'uploadedBooks': FieldValue.arrayUnion([bookId])
        });

        print("User's uploadedBooks array updated with new book ID");
      } else {
        print("User document not found - cannot update uploadedBooks");
      }

      // Refresh the book library in the provider
      await ref.read(bookLibraryProvider.notifier).loadBooks();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Book uploaded successfully!')),
        );

        setState(() {
          _isLoading = false;
          _selectedImage = null;
          _titleController.clear();
          _ageController.clear();
        });

        // Navigate back to gallery with refresh signal
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('Upload error: $e');

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading book: ${e.toString()}'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get theme-aware colors
    final backgroundColor = AppColors.getBackground(context);
    final textColor = AppColors.getTextPrimary(context);
    final textSecondaryColor = AppColors.getTextSecondary(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Field border color
    final fieldBorderColor = isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          "Add New Book",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              "Uploading book...",
              style: TextStyle(color: textColor),
            ),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Book image selector
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 240,
                    width: 180,
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _selectedImage != null
                            ? Colors.transparent
                            : (isDarkMode ? Colors.grey.shade700 : Colors.grey.shade400),
                        width: 2,
                      ),
                      boxShadow: _selectedImage != null
                          ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ]
                          : null,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _selectedImage != null
                        ? Image.file(
                      _selectedImage!,
                      fit: BoxFit.cover,
                    )
                        : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 48,
                          color: isDarkMode
                              ? Colors.grey.shade500
                              : Colors.grey.shade600,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Add Book Cover",
                          style: TextStyle(
                            fontSize: 16,
                            color: isDarkMode
                                ? Colors.grey.shade400
                                : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Book info fields
              Text(
                "Book Information",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 16),

              // Title field
              TextFormField(
                controller: _titleController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: "Title *",
                  labelStyle: TextStyle(color: textSecondaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: fieldBorderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: fieldBorderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Age field
              TextFormField(
                controller: _ageController,
                style: TextStyle(color: textColor),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Age (years) *",
                  labelStyle: TextStyle(color: textSecondaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: fieldBorderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: fieldBorderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the age of the book';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Location field with auto-detect button
              TextFormField(
                controller: _locationController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: "Location *",
                  labelStyle: TextStyle(color: textSecondaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: fieldBorderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: fieldBorderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                  suffixIcon: _isGettingLocation
                      ? Container(
                    margin: const EdgeInsets.all(8),
                    width: 20,
                    height: 20,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                      : IconButton(
                    icon: const Icon(Icons.my_location),
                    onPressed: _getCurrentLocation,
                    tooltip: 'Get current location',
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a location';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Text(
                "Location is detected automatically. You can change it if needed.",
                style: TextStyle(
                  fontSize: 12,
                  color: textSecondaryColor,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 24),

              // Category dropdown
              Text(
                "Category *",
                style: TextStyle(
                  fontSize: 16,
                  color: textSecondaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: fieldBorderColor),
                  color: isDarkMode ? Colors.grey.shade800.withOpacity(0.5) : Colors.grey.shade50,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                    ),
                    hint: Text(
                      'Select a category',
                      style: TextStyle(color: textSecondaryColor),
                    ),
                    items: _categories.map((String category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedCategory = newValue;
                        });
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Upload button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _uploadBook,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(36),
                    ),
                    elevation: 2,
                    shadowColor: isDarkMode ? Colors.black38 : Colors.black12,
                  ),
                  child: const Text(
                    "Add to Library",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}