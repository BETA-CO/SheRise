class AppUser {
  final String uid;
  final String email;
  final DateTime? creationTime;
  final bool isNewUser;

  AppUser({
    required this.uid,
    required this.email,
    this.creationTime,
    this.isNewUser = false,
  });

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'email': email,
    'creationTime': creationTime?.toIso8601String(),
    'isNewUser': isNewUser,
  };

  factory AppUser.fromJson(Map<String, dynamic> jsonUser) {
    return AppUser(
      uid: jsonUser['uid'],
      email: jsonUser['email'],
      creationTime: jsonUser['creationTime'] != null
          ? DateTime.parse(jsonUser['creationTime'])
          : null,
      isNewUser: jsonUser['isNewUser'] ?? false,
    );
  }
}
