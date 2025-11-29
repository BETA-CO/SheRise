class AppUser {
  final String uid;
  final String email;
  final DateTime? creationTime;

  AppUser({required this.uid, required this.email, this.creationTime});

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'email': email,
        'creationTime': creationTime?.toIso8601String(),
      };

  factory AppUser.fromJson(Map<String, dynamic> jsonUser) {
    return AppUser(
      uid: jsonUser['uid'],
      email: jsonUser['email'],
      creationTime: jsonUser['creationTime'] != null
          ? DateTime.parse(jsonUser['creationTime'])
          : null,
    );
  }
}
