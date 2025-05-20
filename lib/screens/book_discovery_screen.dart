import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import '../models/book_card.dart';
import 'package:pain/utils/constants.dart';

class BookDiscoveryScreen extends StatefulWidget {
  const BookDiscoveryScreen({super.key});

  @override
  State<BookDiscoveryScreen> createState() => _BookDiscoveryScreenState();
}

class _BookDiscoveryScreenState extends State<BookDiscoveryScreen> {
  final CardSwiperController controller = CardSwiperController();

  final List<BookCard> cards = [
    BookCard(title: "1984", ownerName: "Ufuk", age: 23, location: "Tuzla • 2 KMS AWAY", imageUrl: null),
    BookCard(title: "The Alchemist", ownerName: "Ayşe", age: 21, location: "Kadıköy • 5 KMS AWAY", imageUrl: null),
    BookCard(title: "Brave New World", ownerName: "Ali", age: 25, location: "Beşiktaş • 3 KMS AWAY", imageUrl: null),
  ];

  final List<Map<String, dynamic>> categories = [
    {"name": "Fiction", "selected": false},
    {"name": "History", "selected": false},
    {"name": "Science", "selected": false},
    {"name": "Philosophy", "selected": false},
  ];

  int _currentIndex = 0;

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
                      onTap: () {
                        setSheetState(() => cat["selected"] = !isSelected);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : AppColors.getCardBackground(context),
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
                          for (var cat in categories) {
                            cat["selected"] = false;
                          }
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
                      onPressed: () {
                        Navigator.pop(context);
                      },
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

  @override
  Widget build(BuildContext context) {
    // Get theme-aware colors
    final backgroundColor = AppColors.getBackground(context);
    final textColor = AppColors.getTextPrimary(context);
    final cardColor = AppColors.getCardBackground(context);

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
            Text(
              "SwipeLit",
              style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_alt, color: AppColors.primary),
            onPressed: _openFilterBottomSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: CardSwiper(
              controller: controller,
              cardsCount: cards.length,
              numberOfCardsDisplayed: 1,
              isLoop: false,
              backCardOffset: const Offset(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              onSwipe: (prev, current, direction) {
                final book = cards[prev];
                if (direction == CardSwiperDirection.left) {
                  debugPrint("❌ Disliked: ${book.title}");
                } else if (direction == CardSwiperDirection.right) {
                  debugPrint("❤️ Liked: ${book.title}");
                } else if (direction == CardSwiperDirection.top) {
                  debugPrint("⭐️ Super Liked: ${book.title}");
                }
                return true;
              },
              cardBuilder: (context, index, realIndex, count) {
                final book = cards[index];
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
                          Container(
                            decoration: BoxDecoration(
                              image: book.imageUrl != null
                                  ? DecorationImage(
                                image: NetworkImage(book.imageUrl!),
                                fit: BoxFit.cover,
                              )
                                  : null,
                              color: book.imageUrl == null ? Colors.redAccent : null,
                            ),
                            alignment: Alignment.center,
                            child: book.imageUrl == null
                                ? Text(
                              book.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                                : null,
                          ),
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
                                    "${book.ownerName}, ${book.age}",
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
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
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