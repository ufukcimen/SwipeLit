import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:image_picker/image_picker.dart';
import '../models/book_card.dart';

/// Service class to handle Firebase operations for book library
class LibraryService {
  // Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get userId => _auth.currentUser?.uid;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Collection references
  CollectionReference get booksCollection => _firestore.collection('books');

  /// Upload a book image to Firebase Storage
  /// Returns download URL
  Future<String?> uploadBookImage(File imageFile) async {
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Create a sanitized filename
      final String fileExtension = path.extension(imageFile.path);
      final String sanitizedFileName = 'book_${DateTime.now().millisecondsSinceEpoch}$fileExtension';

      // Create storage reference
      final Reference storageRef = _storage
          .ref()
          .child('book_images')
          .child(userId!)
          .child(sanitizedFileName);

      // Upload file
      final UploadTask uploadTask = storageRef.putFile(imageFile);
      final TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() {});

      // Get download URL
      final String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading book image: $e');
      throw Exception('Failed to upload book image: $e');
    }
  }

  /// Add a new book to Firestore
  Future<DocumentReference> addBook(BookCard book) async {
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final bookData = {
        ...book.toMap(),
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
      };

      return await booksCollection.add(bookData);
    } catch (e) {
      print('Error adding book: $e');
      throw Exception('Failed to add book: $e');
    }
  }

  /// Fetch books for the current user
  Future<List<BookCard>> fetchBooks() async {
    try {
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final querySnapshot = await booksCollection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return BookCard.fromMap({
          ...data,
          'id': doc.id,
        });
      }).toList();
    } catch (e) {
      print('Error fetching books from Firestore: $e');
      return []; // Return empty list on error
    }
  }

  /// Get a book by ID
  Future<BookCard?> getBookById(String bookId) async {
    try {
      final docSnapshot = await booksCollection.doc(bookId).get();

      if (!docSnapshot.exists) {
        return null;
      }

      final data = docSnapshot.data() as Map<String, dynamic>;
      return BookCard.fromMap({
        ...data,
        'id': docSnapshot.id,
      });
    } catch (e) {
      print('Error getting book by ID: $e');
      return null;
    }
  }

  /// Update a book
  Future<void> updateBook(String bookId, BookCard updatedBook) async {
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    if (bookId.isEmpty) {
      throw Exception('Book ID is required for update');
    }

    try {
      // Ensure we're not trying to update another user's book
      final existingBook = await getBookById(bookId);
      if (existingBook == null) {
        throw Exception('Book not found');
      }

      if (existingBook.userId != userId) {
        throw Exception('You can only update your own books');
      }

      // Update book data
      final bookData = {
        ...updatedBook.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Update in Firestore
      await booksCollection.doc(bookId).update(bookData);
    } catch (e) {
      print('Error updating book in Firestore: $e');
      throw Exception('Failed to update book: $e');
    }
  }

  /// Delete a book
  Future<void> deleteBook(String bookId) async {
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    if (bookId.isEmpty) {
      throw Exception('Book ID is required for deletion');
    }

    try {
      // Ensure we're not trying to delete another user's book
      final existingBook = await getBookById(bookId);
      if (existingBook == null) {
        throw Exception('Book not found');
      }

      if (existingBook.userId != userId) {
        throw Exception('You can only delete your own books');
      }

      // Get the book to check image URL
      final docSnapshot = await booksCollection.doc(bookId).get();
      final data = docSnapshot.data() as Map<String, dynamic>;

      // Delete the image if it exists
      if (data.containsKey('imageUrl') && data['imageUrl'] != null) {
        final String imageUrl = data['imageUrl'];
        if (imageUrl.contains('firebase')) {
          try {
            // Extract the storage path from the URL
            final Uri uri = Uri.parse(imageUrl);
            final String imagePath = uri.path;
            // Try to clean the path to get a valid storage reference
            final String cleanPath = imagePath.startsWith('/o/')
                ? Uri.decodeComponent(imagePath.substring(3))
                : Uri.decodeComponent(imagePath);

            final storageRef = _storage.ref(cleanPath);
            await storageRef.delete();
          } catch (e) {
            print('Error deleting image from storage: $e');
            // Continue with book deletion even if image deletion fails
          }
        }
      }

      // Delete from Firestore
      await booksCollection.doc(bookId).delete();
    } catch (e) {
      print('Error deleting book from Firestore: $e');
      throw Exception('Failed to delete book: $e');
    }
  }

  /// Pick an image from gallery or camera
  Future<File?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }

      return null;
    } catch (e) {
      print('Error picking image: $e');
      throw Exception('Failed to pick image: $e');
    }
  }

  /// Show image source selector dialog
  Future<ImageSource?> showImageSourceDialog(BuildContext context) async {
    return showDialog<ImageSource>(
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
  }

  /// Pick and upload an image
  Future<String?> pickAndUploadImage(BuildContext context) async {
    // Show image source dialog
    final source = await showImageSourceDialog(context);
    if (source == null) return null;

    // Pick image
    final imageFile = await pickImage(source: source);
    if (imageFile == null) return null;

    // Upload image
    return await uploadBookImage(imageFile);
  }

  /// Get books by category
  Future<List<BookCard>> getBooksByCategory(String category) async {
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final querySnapshot = await booksCollection
          .where('userId', isEqualTo: userId)
          .where('category', isEqualTo: category)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return BookCard.fromMap({
          ...data,
          'id': doc.id,
        });
      }).toList();
    } catch (e) {
      print('Error getting books by category: $e');
      return [];
    }
  }

  /// Search books by query
  Future<List<BookCard>> searchBooks(String query) async {
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Get all user's books first
      final querySnapshot = await booksCollection
          .where('userId', isEqualTo: userId)
          .get();

      // If query is empty, return all books
      if (query.isEmpty) {
        return querySnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return BookCard.fromMap({
            ...data,
            'id': doc.id,
          });
        }).toList();
      }

      // Filter books by query
      final lowerQuery = query.toLowerCase();
      return querySnapshot.docs
          .map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return BookCard.fromMap({
          ...data,
          'id': doc.id,
        });
      })
          .where((book) {
        final title = book.title.toLowerCase();
        final owner = book.ownerName.toLowerCase();
        final location = book.location.toLowerCase();
        final category = book.category.toLowerCase();

        return title.contains(lowerQuery) ||
            owner.contains(lowerQuery) ||
            location.contains(lowerQuery) ||
            category.contains(lowerQuery);
      })
          .toList();
    } catch (e) {
      print('Error searching books: $e');
      return [];
    }
  }

  /// Get a stream of books for real-time updates
  Stream<List<BookCard>> getBooksStream() {
    if (userId == null) {
      return Stream.value([]);
    }

    return booksCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return BookCard.fromMap({
          ...data,
          'id': doc.id,
        });
      }).toList();
    });
  }
}