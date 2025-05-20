import 'package:cloud_firestore/cloud_firestore.dart';

class BookCard {
  final String? id; // Firestore document ID
  final String title;
  final String ownerName;
  final int age;
  final String location;
  final String? imageUrl;
  final String? userId; // User who owns this book
  final DateTime? createdAt;
  final String category;

  BookCard({
    this.id,
    required this.title,
    required this.ownerName,
    required this.age,
    required this.location,
    this.imageUrl,
    this.userId,
    this.createdAt,
    this.category = 'Uncategorized',
  });

  // Create a copy of this book with some updated values
  BookCard copyWith({
    String? id,
    String? title,
    String? ownerName,
    int? age,
    String? location,
    String? imageUrl,
    String? userId,
    DateTime? createdAt,
    String? category,
  }) {
    return BookCard(
      id: id ?? this.id,
      title: title ?? this.title,
      ownerName: ownerName ?? this.ownerName,
      age: age ?? this.age,
      location: location ?? this.location,
      imageUrl: imageUrl ?? this.imageUrl,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      category: category ?? this.category,
    );
  }

  // Convert BookCard to Map for storing in Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'ownerName': ownerName,
      'age': age,
      'location': location,
      'imageUrl': imageUrl,
      'userId': userId,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'category': category,
      // Don't include 'id' in the map as it's the document ID
    };
  }

  // For compatibility with LibraryService
  Map<String, dynamic> toJson() => toMap();

  // Create BookCard from Map (from Firestore)
  factory BookCard.fromMap(Map<String, dynamic> map) {
    return BookCard(
      id: map['id'],
      title: map['title'] ?? '',
      ownerName: map['ownerName'] ?? '',
      age: map['age'] ?? 0,
      location: map['location'] ?? '',
      imageUrl: map['imageUrl'],
      userId: map['userId'],
      category: map['category'] ?? 'Uncategorized',
      createdAt: (map['createdAt'] != null && map['createdAt'] is Timestamp)
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  // For compatibility with LibraryService
  factory BookCard.fromJson(Map<String, dynamic> json) => BookCard.fromMap(json);
}