enum UserRole { patient, doctor, admin }

class UserModel {
  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final String? phone;
  final int? age;
  final String? bloodGroup;
  final String? photoUrl;

  const UserModel({
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
    String? uid,
    String? name,
    String? email,
    UserRole? role,
    String? phone,
    int? age,
    String? bloodGroup,
    String? photoUrl,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      age: age ?? this.age,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  factory UserModel.fromFirestore(Map<String, dynamic> data, String uid) {
    final roleStr = data['role'] as String? ?? 'patient';
    return UserModel(
      uid: uid,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      role: roleStr == 'doctor' ? UserRole.doctor : UserRole.patient,
      phone: data['phone'] as String?,
      age: data['age'] as int?,
      bloodGroup: data['bloodGroup'] as String?,
      photoUrl: data['photoUrl'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role == UserRole.doctor ? 'doctor' : 'patient',
      if (phone != null) 'phone': phone,
      if (age != null) 'age': age,
      if (bloodGroup != null) 'bloodGroup': bloodGroup,
      if (photoUrl != null) 'photoUrl': photoUrl,
    };
  }
}