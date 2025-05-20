/*// lib/services/firebase_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pain/models/userModel.dart';
import 'package:pain/providers/sign_up_provider.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();


  // Add this method to your FirebaseService class if it doesn't exist
  static Future<bool> updateUserData(String uid, Map<String, dynamic> userData) async {
    try {
      await _firestore.collection('users').doc(uid).update(userData);
      return true;
    } catch (e) {
      print("Error updating user data: $e");
      return false;
    }
  }

  // Add this sign out method
  static Future<void> signOut() async {
    try {
      print("Signing out from Firebase and Google...");

      // Sign out from Firebase
      await _auth.signOut();

      // Sign out from Google
      await _googleSignIn.signOut();

      print("User signed out successfully");
    } catch (e) {
      print("Error during sign out: $e");
    }
  }


  // Sign in with Google
  static Future<UserModel?> signInWithGoogle() async {
    try {
      print("Starting Google sign-in process...");

      // Sign out first to force account picker to appear
      try {
        await _googleSignIn.signOut();
        print("Signed out from previous Google session");
      } catch (e) {
        print("No previous Google session to sign out from: $e");
      }

      // Begin the Google sign-in process with forceCodeForRefreshToken
      final GoogleSignIn forceSelectAccount = GoogleSignIn(
        scopes: ['email', 'profile'],
        signInOption: SignInOption.standard,
        forceCodeForRefreshToken: true,
      );

      final GoogleSignInAccount? googleUser = await forceSelectAccount.signIn();

      if (googleUser == null) {
        print("Google sign-in was cancelled by user");
        return null;
      }

      print("Google sign-in successful for: ${googleUser.email}");

      // Get authentication details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      if (googleAuth.idToken == null) {
        print("Failed to get Google Auth idToken");
        return null;
      }

      // Create credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print("Signing in to Firebase with Google credential...");

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      print("Firebase sign-in successful. UID: ${userCredential.user?.uid}");

      // Check if it's a new user
      final bool isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;
      print("Is new user? $isNewUser");

      if (isNewUser) {
        print("Creating new user profile in Firestore...");
        // Create new user profile in Firestore
        final userData = {
          'uid': userCredential.user!.uid,
          'name': userCredential.user!.displayName ?? 'User',
          'email': userCredential.user!.email ?? '',
          'phoneNum': userCredential.user!.phoneNumber ?? '',
          'photoUrl': userCredential.user!.photoURL,
          'createdAt': FieldValue.serverTimestamp(),
          'provider': 'google',
          // Add minimum required fields
          'interests': [],
          'uploadedBooks': [],
        };

        // Store in Firestore
        await _firestore.collection('users').doc(userCredential.user!.uid).set(userData);
        print("User profile created successfully");
      } else {
        print("User already exists, checking if profile is complete...");
        // Check if user needs to complete their profile
        final hasProfile = await hasCompleteProfile(userCredential.user!.uid);
        print("Profile complete: $hasProfile");

        if (!hasProfile) {
          // Update user document with any missing fields
          await _firestore.collection('users').doc(userCredential.user!.uid).set({
            'provider': 'google',
            'lastLogin': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      }

      // Get user data (either existing or newly created)
      return await getUserData(userCredential.user!.uid);

    } catch (e) {
      print("Error during Google sign in: $e");
      print("Stack trace: ${StackTrace.current}");
      return null;
    }
  }

  // Create user with email and password
  static Future<UserCredential?> createUserWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print("Error creating user: $e");
      return null;
    }
  }

  // Add this method to your FirebaseService class

// Sign in with email and password
  static Future<UserModel?> signIn(String email, String password) async {
    try {
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password
      );

      // If authentication is successful
      if (credential.user != null) {
        // Get the user data from Firestore
        final userData = await getUserData(credential.user!.uid);

        // If there's user data in Firestore, return it
        if (userData != null) {
          return userData;
        }

        // Otherwise, create a minimal user model from auth data
        return UserModel(
          uid: credential.user!.uid,
          name: credential.user!.displayName ?? "User", // Default if not available
          email: credential.user!.email!,
          phoneNum: credential.user!.phoneNumber ?? "", // Default if not available
        );
      }
      return null;
    } catch (e) {
      print("Error during sign in: $e");
      return null;
    }
  }

  // Store user data in Firestore
  static Future<bool> storeUserData(String uid, Map<String, dynamic> userData) async {
    try {
      await _firestore.collection('users').doc(uid).set(userData);
      return true;
    } catch (e) {
      print("Error storing user data: $e");
      return false;
    }
  }

  // Complete sign-up process
  static Future<UserModel?> completeSignup(SignupState signupData) async {
    if (signupData.email == null || signupData.password == null) {
      print("Email and password are required");
      return null;
    }

    try {
      // Create auth user
      final credential = await createUserWithEmailAndPassword(
        signupData.email!,
        signupData.password!,
      );

      if (credential?.user == null) {
        return null;
      }

      final uid = credential!.user!.uid;

      // Store user data
      final userData = signupData.toMap();
      userData['uid'] = uid;
      userData['createdAt'] = FieldValue.serverTimestamp();

      final success = await storeUserData(uid, userData);

      if (!success) {
        // If storing data fails, delete the auth user
        await credential.user!.delete();
        return null;
      }

      // Return user model
      return UserModel(
        uid: uid,
        name: signupData.name!,
        email: signupData.email!,
        phoneNum: signupData.phoneNum ?? "",
        birthDate: signupData.birthDate,
        gender: signupData.gender,
        interests: signupData.interests,
        uploadedBooks: signupData.uploadedBooks,
        location: signupData.location,
      );
    } catch (e) {
      print("Error in sign-up process: $e");
      return null;
    }
  }

  // In your FirebaseService, add this method to check if a user has a complete profile

  static Future<bool> hasCompleteProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();

      if (!doc.exists) return false;

      final data = doc.data()!;

      // Define what constitutes a "complete" profile
      return data.containsKey('interests') &&
          (data['interests'] as List).isNotEmpty &&
          data.containsKey('birthDate') &&
          data.containsKey('gender');
    } catch (e) {
      print("Error checking profile completeness: $e");
      return false;
    }
  }


  // Add this function to your FirebaseService class
  static Future<Map<String, dynamic>> debugGoogleSignIn() async {
    final results = <String, dynamic>{};

    try {
      results['isSignedIn'] = await _googleSignIn.isSignedIn();

      try {
        results['canSignOut'] = await _googleSignIn.signOut() != null;
      } catch (e) {
        results['signOutError'] = e.toString();
      }

      try {
        // Test if we can get a silentSignIn or at least initialize
        final silentUser = await _googleSignIn.signInSilently();
        results['silentSignInWorks'] = silentUser != null;
      } catch (e) {
        results['silentSignInError'] = e.toString();
        results['silentSignInWorks'] = false;
      }

      results['success'] = true;
    } catch (e) {
      results['success'] = false;
      results['error'] = e.toString();
      results['stackTrace'] = StackTrace.current.toString();
    }

    print("Google Sign-In Debug Results: $results");
    return results;
  }

  // Fetch user data from Firestore
  static Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data()!;

      return UserModel(
        uid: uid,
        name: data['name'],
        email: data['email'],
        phoneNum: data['phoneNum'] ?? "",
        birthDate: data['birthDate'] != null ? DateTime.parse(data['birthDate']) : null,
        gender: data['gender'],
        interests: List<String>.from(data['interests'] ?? []),
        uploadedBooks: List<String>.from(data['uploadedBooks'] ?? []),
        location: data['location'],
      );
    } catch (e) {
      print("Error fetching user data: $e");
      return null;
    }
  }
}*/

// lib/services/firebase_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pain/models/userModel.dart';
import 'package:pain/providers/sign_up_provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:async';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();


// Check if a user exists with this email
  static Future<bool> checkEmailExists(String email) async {
    try {
      // Use Firebase Auth's fetchSignInMethodsForEmail method
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      // If methods list is not empty, email exists
      return methods.isNotEmpty;
    } catch (e) {
      print("Error checking email existence: $e");
      throw e;
    }
  }

// Update password directly (this requires a specialized implementation)
  static Future<void> updatePassword(String email, String newPassword) async {
    try {
      // Note: Firebase doesn't directly let you update another user's password
      // This is a simplified approach that will need admin SDK or custom auth

      // Method 1 (if possible): Use a custom Firebase Function to update password
      // This needs to be implemented on your Firebase backend

      // Method 2 (temporary workaround until you implement a proper solution):
      // Send a password reset email and explain to user they need to check email
      await _auth.sendPasswordResetEmail(email: email);

      // In an actual implementation, you'd have a Firebase Function that uses
      // the Admin SDK to update the user's password directly
    } catch (e) {
      print("Error updating password: $e");
      throw e;
    }
  }


  // Phone verification
  static Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(PhoneAuthCredential) verificationCompleted,
    required Function(FirebaseAuthException) verificationFailed,
    required Function(String, int?) codeSent,
    required Function(String) codeAutoRetrievalTimeout,
    int? resendToken,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
      timeout: const Duration(seconds: 60),
      forceResendingToken: resendToken,
    );
  }

  // Verify OTP
  static Future<UserCredential> signInWithPhoneAuthCredential(
      PhoneAuthCredential credential) async {
    return await _auth.signInWithCredential(credential);
  }

  // Link phone number to existing user account
  static Future<bool> linkPhoneNumberToCurrentUser(String verificationId, String smsCode) async {
    try {
      // Get current user
      final user = _auth.currentUser;
      if (user == null) return false;

      // Create phone auth credential
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      // Link the credential to the user
      await user.linkWithCredential(credential);

      // Update Firestore with the new phone number
      final idTokenResult = await user.getIdTokenResult();
      final phone = idTokenResult.claims?['phone_number'] as String?;

      if (phone != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'phoneNum': phone,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      return true;
    } catch (e) {
      print("Error linking phone number: $e");
      return false;
    }
  }

  // Update user data in Firestore
  static Future<bool> updateUserData(String uid, Map<String, dynamic> userData) async {
    try {
      await _firestore.collection('users').doc(uid).update(userData);
      return true;
    } catch (e) {
      print("Error updating user data: $e");
      return false;
    }
  }

  // Sign out method
  static Future<void> signOut() async {
    try {
      print("Signing out from Firebase and Google...");

      // Sign out from Firebase
      await _auth.signOut();

      // Sign out from Google
      await _googleSignIn.signOut();

      print("User signed out successfully");
    } catch (e) {
      print("Error during sign out: $e");
    }
  }

  // Sign in with Google
  static Future<UserModel?> signInWithGoogle() async {
    try {
      print("Starting Google sign-in process...");

      // Sign out first to force account picker to appear
      try {
        await _googleSignIn.signOut();
        print("Signed out from previous Google session");
      } catch (e) {
        print("No previous Google session to sign out from: $e");
      }

      // Begin the Google sign-in process with forceCodeForRefreshToken
      final GoogleSignIn forceSelectAccount = GoogleSignIn(
        scopes: ['email', 'profile'],
        signInOption: SignInOption.standard,
        forceCodeForRefreshToken: true,
      );

      final GoogleSignInAccount? googleUser = await forceSelectAccount.signIn();

      if (googleUser == null) {
        print("Google sign-in was cancelled by user");
        return null;
      }

      print("Google sign-in successful for: ${googleUser.email}");

      // Get authentication details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      if (googleAuth.idToken == null) {
        print("Failed to get Google Auth idToken");
        return null;
      }

      // Create credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print("Signing in to Firebase with Google credential...");

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      print("Firebase sign-in successful. UID: ${userCredential.user?.uid}");

      // Check if it's a new user
      final bool isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;
      print("Is new user? $isNewUser");

      if (isNewUser) {
        print("Creating new user profile in Firestore...");
        // Create new user profile in Firestore
        final userData = {
          'uid': userCredential.user!.uid,
          'name': userCredential.user!.displayName ?? 'User',
          'email': userCredential.user!.email ?? '',
          'phoneNum': userCredential.user!.phoneNumber ?? '',
          'photoUrl': userCredential.user!.photoURL,
          'createdAt': FieldValue.serverTimestamp(),
          'provider': 'google',
          // Add minimum required fields
          'interests': [],
          'uploadedBooks': [],
        };

        // Store in Firestore
        await _firestore.collection('users').doc(userCredential.user!.uid).set(userData);
        print("User profile created successfully");
      } else {
        print("User already exists, checking if profile is complete...");
        // Check if user needs to complete their profile
        final hasProfile = await hasCompleteProfile(userCredential.user!.uid);
        print("Profile complete: $hasProfile");

        if (!hasProfile) {
          // Update user document with any missing fields
          await _firestore.collection('users').doc(userCredential.user!.uid).set({
            'provider': 'google',
            'lastLogin': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      }

      // Get user data (either existing or newly created)
      return await getUserData(userCredential.user!.uid);

    } catch (e) {
      print("Error during Google sign in: $e");
      print("Stack trace: ${StackTrace.current}");
      return null;
    }
  }

  // Create user with email and password
  static Future<UserCredential?> createUserWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print("Error creating user: $e");
      return null;
    }
  }

  // Sign in with email and password
  static Future<UserModel?> signIn(String email, String password) async {
    try {
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password
      );

      // If authentication is successful
      if (credential.user != null) {
        // Get the user data from Firestore
        final userData = await getUserData(credential.user!.uid);

        // If there's user data in Firestore, return it
        if (userData != null) {
          return userData;
        }

        // Otherwise, create a minimal user model from auth data
        return UserModel(
          uid: credential.user!.uid,
          name: credential.user!.displayName ?? "User", // Default if not available
          email: credential.user!.email!,
          phoneNum: credential.user!.phoneNumber ?? "", // Default if not available
        );
      }
      return null;
    } catch (e) {
      print("Error during sign in: $e");
      return null;
    }
  }

  // Store user data in Firestore
  static Future<bool> storeUserData(String uid, Map<String, dynamic> userData) async {
    try {
      await _firestore.collection('users').doc(uid).set(userData);
      return true;
    } catch (e) {
      print("Error storing user data: $e");
      return false;
    }
  }

  // Complete sign-up process
  static Future<UserModel?> completeSignup(SignupState signupData) async {
    if (signupData.email == null || signupData.password == null) {
      print("Email and password are required");
      return null;
    }

    try {
      // Create auth user
      final credential = await createUserWithEmailAndPassword(
        signupData.email!,
        signupData.password!,
      );

      if (credential?.user == null) {
        return null;
      }

      final uid = credential!.user!.uid;

      // Store user data
      final userData = signupData.toMap();
      userData['uid'] = uid;
      userData['createdAt'] = FieldValue.serverTimestamp();

      final success = await storeUserData(uid, userData);

      if (!success) {
        // If storing data fails, delete the auth user
        await credential.user!.delete();
        return null;
      }

      // Return user model
      return UserModel(
        uid: uid,
        name: signupData.name!,
        email: signupData.email!,
        phoneNum: signupData.phoneNum ?? "",
        birthDate: signupData.birthDate,
        gender: signupData.gender,
        interests: signupData.interests,
        uploadedBooks: signupData.uploadedBooks,
        location: signupData.location,
      );
    } catch (e) {
      print("Error in sign-up process: $e");
      return null;
    }
  }

  // Check if a user has a complete profile
  static Future<bool> hasCompleteProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();

      if (!doc.exists) return false;

      final data = doc.data()!;

      // Define what constitutes a "complete" profile
      return data.containsKey('interests') &&
          (data['interests'] as List).isNotEmpty &&
          data.containsKey('birthDate') &&
          data.containsKey('gender');
    } catch (e) {
      print("Error checking profile completeness: $e");
      return false;
    }
  }

  // Debug Google Sign In
  static Future<Map<String, dynamic>> debugGoogleSignIn() async {
    final results = <String, dynamic>{};

    try {
      results['isSignedIn'] = await _googleSignIn.isSignedIn();

      try {
        results['canSignOut'] = await _googleSignIn.signOut() != null;
      } catch (e) {
        results['signOutError'] = e.toString();
      }

      try {
        // Test if we can get a silentSignIn or at least initialize
        final silentUser = await _googleSignIn.signInSilently();
        results['silentSignInWorks'] = silentUser != null;
      } catch (e) {
        results['silentSignInError'] = e.toString();
        results['silentSignInWorks'] = false;
      }

      results['success'] = true;
    } catch (e) {
      results['success'] = false;
      results['error'] = e.toString();
      results['stackTrace'] = StackTrace.current.toString();
    }

    print("Google Sign-In Debug Results: $results");
    return results;
  }

  // Fetch user data from Firestore
  static Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data()!;

      return UserModel(
        uid: uid,
        name: data['name'],
        email: data['email'],
        phoneNum: data['phoneNum'] ?? "",
        birthDate: data['birthDate'] != null ? DateTime.parse(data['birthDate']) : null,
        gender: data['gender'],
        interests: List<String>.from(data['interests'] ?? []),
        uploadedBooks: List<String>.from(data['uploadedBooks'] ?? []),
        location: data['location'],
      );
    } catch (e) {
      print("Error fetching user data: $e");
      return null;
    }
  }
}