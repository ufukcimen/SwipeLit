import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/book_card.dart';
import 'package:pain/utils/constants.dart';

class BookDiscoveryScreen extends StatefulWidget {
  const BookDiscoveryScreen({super.key});

  @override
  State<BookDiscoveryScreen> createState() => _BookDiscoveryScreenState();
}

class _BookDiscoveryScreenState extends State<BookDiscoveryScreen> {
  final CardSwiperController controller = CardSwiperController();
  final FirebaseAuth _auth      = FirebaseAuth.instance;
  final FirebaseFirestore _db   = FirebaseFirestore.instance;

  final List<Map<String, dynamic>> categories = [
    {"name": "Fiction",   "selected": false},
    {"name": "History",   "selected": false},
    {"name": "Science",   "selected": false},
    {"name": "Philosophy","selected": false},
  ];

  int _currentIndex = 0;
  bool _isBlocking    = false;

  void _onNavTapped(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
    if (index == 1) {
      Navigator.pushReplacementNamed(context, '/messages');
    } else if (index == 2) {
      Navigator.pushReplacementNamed(context, '/profile');
    }
  }

  void _openFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.getCardBackground(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setSheetState) {
          final textColor = AppColors.getTextPrimary(context);
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Filter by Category",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: categories.map((cat) {
                    final isSelected = cat["selected"] as bool;
                    return GestureDetector(
                      onTap: () => setSheetState(() => cat["selected"] = !isSelected),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.getCardBackground(context),
                          borderRadius: BorderRadius.circular(36),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey[700]!
                                    : Colors.grey[300]!,
                          ),
                        ),
                        child: Text(
                          cat["name"],
                          style: TextStyle(
                            color: isSelected ? Colors.white : textColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      onPressed: () {
                        setState(() {
                          for (var cat in categories) cat["selected"] = false;
                        });
                        Navigator.pop(context);
                      },
                      child: const Text("Reset", style: TextStyle(color: Colors.white)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Apply", style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _recordSwipe(BookCard book, CardSwiperDirection direction) async {
    if (_isBlocking) return;
    _isBlocking = true;
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final userRef = _db.collection('users').doc(uid);

    String field;
    if (direction == CardSwiperDirection.left) {
      field = 'dislikes';
    } else if (direction == CardSwiperDirection.right) {
      field = 'likes';
    } else {
      field = 'superlikes';
    }

    await userRef.update({
      field: FieldValue.arrayUnion([book.id]),
    });
    _isBlocking = false;
  }

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Center(child: Text('Please sign in.'));

    final backgroundColor = AppColors.getBackground(context);
    final textColor       = AppColors.getTextPrimary(context);
    final cardColor       = AppColors.getCardBackground(context);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: const SizedBox(),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book_rounded, color: AppColors.primary),
            const SizedBox(width: 6),
            Text("SwipeLit",
                style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_alt, color: AppColors.primary),
            onPressed: _openFilterBottomSheet,
          ),
        ],
      ),

      body: StreamBuilder<DocumentSnapshot>(
        stream: _db.collection('users').doc(uid).snapshots(),
        builder: (ctx, userSnap) {
          if (!userSnap.hasData) return const Center(child: CircularProgressIndicator());
          final data = userSnap.data!.data() as Map<String, dynamic>;
          final swipedIds = <String>{
            ...(data['likes']      as List<dynamic>? ?? []).cast<String>(),
            ...(data['dislikes']   as List<dynamic>? ?? []).cast<String>(),
            ...(data['superlikes'] as List<dynamic>? ?? []).cast<String>(),
          };

          return StreamBuilder<QuerySnapshot>(
            stream: _db.collection('books').snapshots(),
            builder: (ctx2, booksSnap) {
              if (!booksSnap.hasData) return const Center(child: CircularProgressIndicator());

              final allBooks = booksSnap.data!.docs.map((doc) {
                final d = doc.data()! as Map<String, dynamic>;
                return BookCard(
                  id:        doc.id,
                  title:     d['title']     as String,
                  ownerName: d['ownerName'] as String,
                  age:       d['age']       as int,
                  location:  d['location']  as String,
                  imageUrl:  d['imageUrl']  as String?,
                  ownerId:   d['userId']    as String,
                );
              }).toList();

              final available = allBooks.where((b) => !swipedIds.contains(b.id)).toList();

              if (available.isEmpty) {
                return Center(
                  child: Text(
                    'You have swiped all the books!',
                    style: TextStyle(color: textColor),
                  ),
                );
              }

              return Column(
                children: [
                  Expanded(
                    child: CardSwiper(
                      controller: controller,
                      cardsCount: available.length,
                      numberOfCardsDisplayed: 1,
                      isLoop: false,
                      backCardOffset: const Offset(0, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                      onSwipe: (prev, current, direction) {
                        final book = available[prev];
                        _recordSwipe(book, direction);
                        return true;
                      },
                      cardBuilder: (context, index, realIndex, count) {
                        final book = available[index];
                        return Align(
                          alignment: Alignment.center,
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.85,
                            height: MediaQuery.of(context).size.height * 0.65,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(30),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  if (book.imageUrl != null)
                                    Image.network(book.imageUrl!, fit: BoxFit.cover)
                                  else
                                    Container(color: Colors.redAccent),
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [Colors.black54, Colors.transparent],
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${book.ownerName}, ${book.age}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            book.location,
                                            style: const TextStyle(color: Colors.white70),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: cardColor,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.red, size: 28),
                          onPressed: () => controller.swipe(CardSwiperDirection.left),
                        ),
                      ),
                      CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.pinkAccent,
                        child: IconButton(
                          icon: const Icon(Icons.favorite, color: Colors.white, size: 30),
                          onPressed: () => controller.swipe(CardSwiperDirection.right),
                        ),
                      ),
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.amber,
                        child: IconButton(
                          icon: const Icon(Icons.star, color: Colors.white, size: 28),
                          onPressed: () => controller.swipe(CardSwiperDirection.top),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              );
            },
          );
        },
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.black
            : Colors.white,
        onTap: _onNavTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: ''),
        ],
      ),
    );
  }
}
