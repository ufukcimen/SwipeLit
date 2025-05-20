import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pain/models/userModel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Create a refresher notifier to trigger refreshes
class UserRefresher extends StateNotifier<int> {
  UserRefresher() : super(0);

  void refresh() {
    state++; // Increment the state to trigger a refresh
  }
}

// Add this provider
final userRefresherProvider = StateNotifierProvider<UserRefresher, int>((ref) {
  return UserRefresher();
});

// Now modify your authProvider to watch the refresher
final authProvider = StreamProvider.autoDispose<UserModel?>((ref) async* {
  // Watch the refresher, so that when it changes, this provider rebuilds
  ref.watch(userRefresherProvider);

  final Stream<User?> authStateChanges = FirebaseAuth.instance.authStateChanges();

  await for (final firebaseUser in authStateChanges) {
    if (firebaseUser == null) {
      yield null;
    } else {
      try {
        // Fetch additional user data from Firestore
        final docSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUser.uid)
            .get();

        if (docSnapshot.exists) {
          // If user data exists in Firestore, use it
          final userData = docSnapshot.data()!;

          yield UserModel(
            uid: firebaseUser.uid,
            name: userData['name'] ?? firebaseUser.displayName ?? 'User',
            email: userData['email'] ?? firebaseUser.email ?? '',
            phoneNum: userData['phoneNum'] ?? firebaseUser.phoneNumber ?? '',
            birthDate: userData['birthDate'] != null
                ? DateTime.parse(userData['birthDate'])
                : null,
            gender: userData['gender'],
            interests: userData['interests'] != null
                ? List<String>.from(userData['interests'])
                : [],
            uploadedBooks: userData['uploadedBooks'] != null
                ? List<String>.from(userData['uploadedBooks'])
                : [],
            location: userData['location'],
            photoUrl: userData['photoUrl'],
          );
        } else {
          // If no Firestore data, create minimal model from auth data
          yield UserModel(
            uid: firebaseUser.uid,
            name: firebaseUser.displayName ?? 'User',
            email: firebaseUser.email ?? '',
            phoneNum: firebaseUser.phoneNumber ?? '',
            photoUrl: null, // Add this to match the updated UserModel
          );
        }
      } catch (e) {
        print("Error fetching user data: $e");
        // Fallback to just auth data if there's an error
        yield UserModel(
          uid: firebaseUser.uid,
          name: firebaseUser.displayName ?? 'User',
          email: firebaseUser.email ?? '',
          phoneNum: firebaseUser.phoneNumber ?? '',
          photoUrl: null, // Add this to match the updated UserModel
        );
      }
    }
  }
});