import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../utils/constants.dart';
import '../models/book_card.dart';
import '../providers/library_provider.dart';

class BookDetailsScreen extends ConsumerStatefulWidget {
  final BookCard book;
  final int index;
  final bool isEditing;
  final String? documentId; // Add document ID parameter

  const BookDetailsScreen({
    super.key,
    required this.book,
    required this.index,
    this.isEditing = false,
    this.documentId, // Make it optional but should be provided when using Firestore
  });

  @override
  ConsumerState<BookDetailsScreen> createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends ConsumerState<BookDetailsScreen> {
  late TextEditingController _titleController;
  late TextEditingController _ownerController;
  late TextEditingController _ageController;
  late TextEditingController _locationController;

  bool _isEditing = false;
  bool _isLoading = false;
  File? _imageFile;
  String? _newImageUrl;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.book.title);
    _ownerController = TextEditingController(text: widget.book.ownerName);
    _ageController = TextEditingController(text: widget.book.age.toString());
    _locationController = TextEditingController(text: widget.book.location);
    _isEditing = widget.isEditing;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _ownerController.dispose();
    _ageController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  Future<void> _pickImage() async {
    final imagePicker = ImagePicker();

    // Show a dialog to choose camera or gallery
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) return;

    final pickedImage = await imagePicker.pickImage(
      source: source,
      imageQuality: 80, // Compress image to reduce file size
    );

    if (pickedImage != null) {
      setState(() {
        _imageFile = File(pickedImage.path);
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_imageFile == null) return;

    try {
      setState(() {
        _isLoading = true;
      });

      // Get current user ID
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User not authenticated");
      }

      // Refresh token to ensure latest authentication
      await user.getIdToken(true);

      // Generate a unique filename using timestamp and user ID
      final fileName = '${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Create a better path structure with user-specific folder
      final storageRef = FirebaseStorage.instance.ref()
          .child('books')
          .child(user.uid)
          .child(fileName);

      print("Uploading book image to: ${storageRef.fullPath}");

      // Add metadata
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'userId': user.uid},
      );

      // Upload the file
      final uploadTask = storageRef.putFile(_imageFile!, metadata);

      // Monitor progress for debugging
      uploadTask.snapshotEvents.listen((snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        print('Book image upload progress: ${(progress * 100).toStringAsFixed(2)}%');
      }, onError: (error) {
        print("Upload error: $error");
      });

      // Wait for the upload to complete
      final snapshot = await uploadTask.whenComplete(() {});

      // Get the download URL
      _newImageUrl = await snapshot.ref.getDownloadURL();
      print("Book image uploaded successfully: $_newImageUrl");

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print("Error uploading book image: $e");
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e')),
        );
      }
    }
  }

  Future<void> _saveChanges() async {
    // Validate inputs
    if (_titleController.text.isEmpty ||
        _ownerController.text.isEmpty ||
        _ageController.text.isEmpty ||
        _locationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All fields are required')),
      );
      return;
    }

    // Parse age
    int? age = int.tryParse(_ageController.text);
    if (age == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Age must be a valid number')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Upload image if a new one was selected
      if (_imageFile != null) {
        await _uploadImage();
      }

      // Get the document ID to update
      final String docId = widget.documentId ?? widget.book.id ?? '';
      if (docId.isEmpty) {
        throw Exception('Book ID is missing - cannot update book');
      }

      // Create updated book
      final updatedBook = BookCard(
          title: _titleController.text,
          ownerName: _ownerController.text,
          age: age,
          location: _locationController.text,
          imageUrl: _newImageUrl ?? widget.book.imageUrl,
          // Ensure any other fields from original book are preserved
          id: docId,
          userId: widget.book.userId,
          ownerId: widget.book.userId!,
          createdAt: widget.book.createdAt,
          category: widget.book.category // Make sure to include category
      );

      // Update in provider and Firestore
      await ref.read(bookLibraryProvider.notifier).updateBookById(
        docId,
        updatedBook,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isEditing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Book updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating book: $e')),
        );
      }
    }
  }

  Future<void> _deleteBook() async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Book'),
        content: const Text('Are you sure you want to delete this book?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Get the document ID to delete
      final String docId = widget.documentId ?? widget.book.id ?? '';
      if (docId.isEmpty) {
        throw Exception('Book ID is missing - cannot delete book');
      }

      // Get current user
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Delete the book from Firestore
      await ref.read(bookLibraryProvider.notifier).deleteBookById(docId);

      // Update user's uploadedBooks array to remove this book ID
      final userRef = FirebaseFirestore.instance.collection('users').doc(currentUser.uid);

      // Use arrayRemove to remove the book ID from user's uploadedBooks array
      await userRef.update({
        'uploadedBooks': FieldValue.arrayRemove([docId])
      });

      print("Book ID removed from user's uploadedBooks array");

      if (mounted) {
        Navigator.pop(context); // Go back to gallery

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Book deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting book: $e')),
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

    final fieldBorderColor = isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          _isEditing ? "Edit Book" : "Book Details",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: _toggleEdit,
            )
          else
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.white),
              onPressed: _deleteBook,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book image with edit capability
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    height: 240,
                    width: 180,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _imageFile != null
                        ? Image.file(
                      _imageFile!,
                      fit: BoxFit.cover,
                    )
                        : (widget.book.imageUrl != null && widget.book.imageUrl!.isNotEmpty
                        ? Image.network(
                      widget.book.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.broken_image, size: 64),
                        );
                      },
                    )
                        : Container(
                      color: Colors.grey.shade300,
                      child: Icon(
                        Icons.book,
                        size: 64,
                        color: Colors.grey.shade700,
                      ),
                    )),
                  ),
                  if (_isEditing)
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.photo_camera,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                ],
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
            TextField(
              controller: _titleController,
              style: TextStyle(color: textColor),
              enabled: _isEditing,
              decoration: InputDecoration(
                labelText: "Title",
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
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: fieldBorderColor),
                ),
                filled: true,
                fillColor: _isEditing ? null : (isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100),
              ),
            ),
            const SizedBox(height: 16),

            // Owner field
            TextField(
              controller: _ownerController,
              style: TextStyle(color: textColor),
              enabled: _isEditing,
              decoration: InputDecoration(
                labelText: "Owner",
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
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: fieldBorderColor),
                ),
                filled: true,
                fillColor: _isEditing ? null : (isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100),
              ),
            ),
            const SizedBox(height: 16),

            // Age field
            TextField(
              controller: _ageController,
              style: TextStyle(color: textColor),
              enabled: _isEditing,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Age (years)",
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
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: fieldBorderColor),
                ),
                filled: true,
                fillColor: _isEditing ? null : (isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100),
              ),
            ),
            const SizedBox(height: 16),

            // Location field
            TextField(
              controller: _locationController,
              style: TextStyle(color: textColor),
              enabled: _isEditing,
              decoration: InputDecoration(
                labelText: "Location",
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
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: fieldBorderColor),
                ),
                filled: true,
                fillColor: _isEditing ? null : (isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100),
              ),
            ),

            const SizedBox(height: 40),

            // Save button (only in edit mode)
            if (_isEditing)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveChanges,
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
                    "Save Changes",
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
    );
  }
}