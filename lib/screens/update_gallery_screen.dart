import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/constants.dart';
import '../models/book_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/library_services.dart';
import 'book_details_screen.dart';

class UpdateGalleryScreen extends ConsumerStatefulWidget {
  const UpdateGalleryScreen({super.key});

  @override
  ConsumerState<UpdateGalleryScreen> createState() => _UpdateGalleryScreenState();
}

class _UpdateGalleryScreenState extends ConsumerState<UpdateGalleryScreen> {
  List<BookCard> _books = [];
  bool _isLoading = true;
  final _libraryService = LibraryService();

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  // Load books using LibraryService
  Future<void> _loadBooks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final books = await _libraryService.fetchBooks();

      setState(() {
        _books = books;
        _isLoading = false;
      });

      print("Loaded ${_books.length} books");
    } catch (e) {
      print('Error loading books: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading books: $e')),
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
    final cardColor = AppColors.getCardBackground(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          "My Library",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        actions: [
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadBooks,
            tooltip: 'Refresh books',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadBooks,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "My Books",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),

            // Books grid view
            Expanded(
              child: _books.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.library_books_outlined,
                      size: 80,
                      color: isDarkMode
                          ? Colors.grey.shade700
                          : Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Your library is empty",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Add some books to get started",
                      style: TextStyle(
                        color: textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              )
                  : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75, // Adjusted for simpler cards with just the title
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _books.length,
                  itemBuilder: (context, index) {
                    final book = _books[index];
                    return GestureDetector(
                      onTap: () {
                        _navigateToBookDetails(book, index);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Book image
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  topRight: Radius.circular(16),
                                ),
                                child: book.imageUrl != null &&
                                    book.imageUrl!.isNotEmpty
                                    ? Image.network(
                                  book.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey.shade300,
                                      child: const Icon(
                                          Icons.broken_image,
                                          size: 48),
                                    );
                                  },
                                )
                                    : Container(
                                  color: Colors.grey.shade300,
                                  child: Icon(
                                    Icons.book,
                                    size: 48,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ),

                            // Book details
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    book.title,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.pushNamed(context, '/uploadBook').then((_) => _loadBooks());
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  // Navigate to book details
  Future<void> _navigateToBookDetails(BookCard book, int index) async {
    // Navigate directly to BookDetailsScreen with documentId
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookDetailsScreen(
          book: book,
          index: index,
          documentId: book.id, // Pass document ID for proper updates
        ),
      ),
    ).then((_) {
      // Refresh the book list when returning
      _loadBooks();
    });
  }
}