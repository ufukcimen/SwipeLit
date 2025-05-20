import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/book_card.dart';

// Assuming you have a BookLibraryNotifier class that handles your state
class BookLibraryNotifier extends StateNotifier<List<BookCard>> {
  final FirebaseFirestore _firestore;
  final String? _userId;

  BookLibraryNotifier(this._firestore, this._userId) : super([]);

  // Load books from Firestore
  Future<void> loadBooks() async {
    try {
      final snapshot = await _firestore
          .collection('books')
          .where('userId', isEqualTo: _userId)
          .orderBy('createdAt', descending: true)
          .get();

      state = snapshot.docs.map((doc) {
        final data = doc.data();
        return BookCard.fromMap({
          ...data,
          'id': doc.id, // Store the document ID in the model
        });
      }).toList();
    } catch (e) {
      throw Exception('Error loading books: $e');
    }
  }

  // Add a new book
  Future<void> addBook(BookCard book) async {
    try {
      final docRef = await _firestore.collection('books').add(book.toMap());

      // Update state with the new book, including its document ID
      state = [
        BookCard.fromMap({
          ...book.toMap(),
          'id': docRef.id,
        }),
        ...state,
      ];
    } catch (e) {
      throw Exception('Error adding book: $e');
    }
  }

  // Update book by index - this is causing the error
  // This method should be avoided when using Firestore
  Future<void> updateBook(int index, BookCard updatedBook) async {
    // Validate index
    if (index < 0 || index >= state.length) {
      throw Exception('Invalid book index');
    }

    try {
      // Get the document ID from the state
      final docId = state[index].id;
      if (docId == null) {
        throw Exception('Book has no document ID');
      }

      // Update in Firestore
      await _firestore.collection('books').doc(docId).update(updatedBook.toMap());

      // Update state
      final newState = [...state];
      newState[index] = updatedBook.copyWith(id: docId);
      state = newState;
    } catch (e) {
      throw Exception('Error updating book: $e');
    }
  }

  // Update book by document ID - this is the preferred method for Firestore
  Future<void> updateBookById(String docId, BookCard updatedBook) async {
    try {
      // Update in Firestore
      await _firestore.collection('books').doc(docId).update(updatedBook.toMap());

      // Update state
      state = state.map((book) {
        return book.id == docId ? updatedBook.copyWith(id: docId) : book;
      }).toList();
    } catch (e) {
      throw Exception('Error updating book: $e');
    }
  }

  // Delete book by index - this is causing the error
  // This method should be avoided when using Firestore
  Future<void> deleteBook(int index) async {
    // Validate index
    if (index < 0 || index >= state.length) {
      throw Exception('Invalid book index');
    }

    try {
      // Get the document ID from the state
      final docId = state[index].id;
      if (docId == null) {
        throw Exception('Book has no document ID');
      }

      // Delete from Firestore
      await _firestore.collection('books').doc(docId).delete();

      // Update state
      final newState = [...state];
      newState.removeAt(index);
      state = newState;
    } catch (e) {
      throw Exception('Error deleting book: $e');
    }
  }

  // Delete book by document ID - this is the preferred method for Firestore
  Future<void> deleteBookById(String docId) async {
    try {
      // Delete from Firestore
      await _firestore.collection('books').doc(docId).delete();

      // Update state
      state = state.where((book) => book.id != docId).toList();
    } catch (e) {
      throw Exception('Error deleting book: $e');
    }
  }
}

// Provider definition
final bookLibraryProvider = StateNotifierProvider<BookLibraryNotifier, List<BookCard>>((ref) {
  final firestore = FirebaseFirestore.instance;
  final userId = FirebaseAuth.instance.currentUser?.uid;

  if (userId == null) {
    print("Warning: No authenticated user found when initializing bookLibraryProvider");
  } else {
    print("Initializing bookLibraryProvider with user ID: $userId");
  }

  return BookLibraryNotifier(firestore, userId);
});