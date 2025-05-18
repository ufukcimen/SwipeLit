class UserModel {
  String name;
  String email;
  DateTime birthDate;
  String gender;
  List<String> interests;
  List<String> uploadedBooks;
  String location;

  UserModel({
    required this.name,
    required this.email,
    required this.birthDate,
    required this.gender,
    required this.interests,
    required this.uploadedBooks,
    required this.location,
  });
}
