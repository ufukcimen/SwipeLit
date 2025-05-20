class UserModel {
  final String uid;
  final String name;
  final String email;
  final DateTime? birthDate;
  final String? gender;
  final List<String>? interests;
  final List<String>? uploadedBooks;
  final String? location;
  final double locationRadius; // Add this field for match distance preference
  final String phoneNum;
  final String? photoUrl;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.birthDate,
    this.gender,
    this.interests,
    this.uploadedBooks,
    this.location,
    this.locationRadius = 10.0, // Default 10km
    required this.phoneNum,
    this.photoUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'birthDate': birthDate?.toIso8601String(),
      'gender': gender,
      'interests': interests,
      'uploadedBooks': uploadedBooks,
      'phoneNum': phoneNum,
      'location': location,
      'locationRadius': locationRadius, // Add this to the map
      'photoUrl': photoUrl,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      uid: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      birthDate: map['birthDate'] != null ? DateTime.parse(map['birthDate']) : null,
      gender: map['gender'],
      interests: map['interests'] != null ? List<String>.from(map['interests']) : null,
      uploadedBooks: map['uploadedBooks'] != null ? List<String>.from(map['uploadedBooks']) : null,
      location: map['location'],
      locationRadius: map['locationRadius'] ?? 10.0, // Parse from map with default
      phoneNum: map['phoneNum'] ?? '',
      photoUrl: map['photoUrl'],
    );
  }
}