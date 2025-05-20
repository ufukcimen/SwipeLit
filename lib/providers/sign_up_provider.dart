// lib/providers/signup_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SignupState {
  final String? name;
  final String? email;
  final String? password;
  final String? phoneNum;
  final DateTime? birthDate;
  final String? gender;
  final List<String> interests;
  final List<String> uploadedBooks;
  final String? location;

  SignupState({
    this.name,
    this.email,
    this.password,
    this.phoneNum,
    this.birthDate,
    this.gender,
    this.interests = const [],
    this.uploadedBooks = const [],
    this.location,
  });

  SignupState copyWith({
    String? name,
    String? email,
    String? password,
    String? phoneNum,
    DateTime? birthDate,
    String? gender,
    List<String>? interests,
    List<String>? uploadedBooks,
    String? location,
  }) {
    return SignupState(
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      phoneNum: phoneNum ?? this.phoneNum,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      interests: interests ?? this.interests,
      uploadedBooks: uploadedBooks ?? this.uploadedBooks,
      location: location ?? this.location,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phoneNum': phoneNum,
      'birthDate': birthDate?.toIso8601String(),
      'gender': gender,
      'interests': interests,
      'uploadedBooks': uploadedBooks,
      'location': location,
    };
  }
}

class SignupNotifier extends StateNotifier<SignupState> {
  SignupNotifier() : super(SignupState());

  void setName(String name) {
    state = state.copyWith(name: name);
  }

  void setEmail(String email) {
    state = state.copyWith(email: email);
  }

  void setPassword(String password) {
    state = state.copyWith(password: password);
  }

  void setPhoneNum(String phoneNum) {
    state = state.copyWith(phoneNum: phoneNum);
  }

  void setBirthDate(DateTime birthDate) {
    state = state.copyWith(birthDate: birthDate);
  }

  void setGender(String gender) {
    state = state.copyWith(gender: gender);
  }

  void setInterests(List<String> interests) {
    state = state.copyWith(interests: interests);
  }

  void addBookImage(String imagePath) {
    final updatedBooks = [...state.uploadedBooks, imagePath];
    state = state.copyWith(uploadedBooks: updatedBooks);
  }

  void setLocation(String location) {
    state = state.copyWith(location: location);
  }

  void clear() {
    state = SignupState();
  }
}

final signupProvider = StateNotifierProvider<SignupNotifier, SignupState>((ref) {
  return SignupNotifier();
});