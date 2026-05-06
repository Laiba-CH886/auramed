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

  // ✅ NEW FIELDS
  final bool isApproved;
  final bool isBlocked;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.age,
    this.bloodGroup,
    this.photoUrl,
    required this.isApproved,
    required this.isBlocked,
  });

  // ───────────────── COPY WITH ─────────────────
  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    UserRole? role,
    String? phone,
    int? age,
    String? bloodGroup,
    String? photoUrl,
    bool? isApproved,
    bool? isBlocked,
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
      isApproved: isApproved ?? this.isApproved,
      isBlocked: isBlocked ?? this.isBlocked,
    );
  }

  // ───────────────── FIRESTORE → APP ─────────────────
  factory UserModel.fromFirestore(Map<String, dynamic> data, String uid) {
    final roleStr = (data['role'] as String? ?? 'patient').toLowerCase();

    UserRole role;
    switch (roleStr) {
      case 'doctor':
        role = UserRole.doctor;
        break;
      case 'admin':
        role = UserRole.admin;
        break;
      default:
        role = UserRole.patient;
    }

    return UserModel(
      uid: uid,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      role: role,
      phone: data['phone'] as String?,
      age: data['age'] as int?,
      bloodGroup: data['bloodGroup'] as String?,
      photoUrl: data['photoUrl'] as String?,

      // ✅ IMPORTANT DEFAULT LOGIC
      isApproved: data['isApproved'] as bool? ?? (role != UserRole.doctor),
      isBlocked: data['isBlocked'] as bool? ?? false,
    );
  }

  // ───────────────── APP → FIRESTORE ─────────────────
  Map<String, dynamic> toFirestore() {
    String roleStr;

    switch (role) {
      case UserRole.doctor:
        roleStr = 'doctor';
        break;
      case UserRole.admin:
        roleStr = 'admin';
        break;
      default:
        roleStr = 'patient';
    }

    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': roleStr,

      // ✅ NEW FIELDS
      'isApproved': isApproved,
      'isBlocked': isBlocked,

      if (phone != null) 'phone': phone,
      if (age != null) 'age': age,
      if (bloodGroup != null) 'bloodGroup': bloodGroup,
      if (photoUrl != null) 'photoUrl': photoUrl,
    };
  }
}