class BookCard {
  final String title;
  final String ownerName;
  final int age;
  final String location;
  final String? imageUrl;

  BookCard({
    required this.title,
    required this.ownerName,
    required this.age,
    required this.location,
    this.imageUrl,
  });
}
