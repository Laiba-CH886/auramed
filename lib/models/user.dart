enum UserRole { patient, doctor }

class UserModel {
  final String uid;
  final String name;
  final String email;
  final UserRole role;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
  });
}
