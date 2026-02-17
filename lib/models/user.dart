enum UserRole { patient, doctor }

class UserModel {
  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final String? phone;
  final int? age;
  final String? bloodGroup;
  final String? photoUrl;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.age,
    this.bloodGroup,
    this.photoUrl,
  });

  UserModel copyWith({
    String? name,
    String? phone,
    int? age,
    String? bloodGroup,
    String? photoUrl,
  }) {
    return UserModel(
      uid: this.uid,
      name: name ?? this.name,
      email: this.email,
      role: this.role,
      phone: phone ?? this.phone,
      age: age ?? this.age,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}
