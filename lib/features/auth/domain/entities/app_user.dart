class AppUser {
  final String uid;
  final String? email;
  final String? phoneNumber;
  final DateTime? creationTime;
  final bool isNewUser;
  final String? name;
  final String? surname;
  final DateTime? dob;
  final String? profilePicPath;

  String? get age {
    if (dob == null) return null;
    final now = DateTime.now();
    int age = now.year - dob!.year;
    if (now.month < dob!.month ||
        (now.month == dob!.month && now.day < dob!.day)) {
      age--;
    }
    return age.toString();
  }

  AppUser({
    required this.uid,
    this.email,
    this.phoneNumber,
    this.creationTime,
    this.isNewUser = false,
    this.name,
    this.surname,
    this.dob,
    this.profilePicPath,
  });

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'email': email,
    'phoneNumber': phoneNumber,
    'creationTime': creationTime?.toIso8601String(),
    'isNewUser': isNewUser,
    'name': name,
    'surname': surname,
    'dob': dob?.toIso8601String(),
    'profilePicPath': profilePicPath,
  };

  factory AppUser.fromJson(Map<String, dynamic> jsonUser) {
    return AppUser(
      uid: jsonUser['uid'],
      email: jsonUser['email'],
      phoneNumber: jsonUser['phoneNumber'],
      creationTime: jsonUser['creationTime'] != null
          ? DateTime.parse(jsonUser['creationTime'])
          : null,
      isNewUser: jsonUser['isNewUser'] ?? false,
      name: jsonUser['name'],
      surname: jsonUser['surname'],
      dob: jsonUser['dob'] != null ? DateTime.parse(jsonUser['dob']) : null,
      profilePicPath: jsonUser['profilePicPath'],
    );
  }

  AppUser copyWith({
    String? uid,
    String? email,
    String? phoneNumber,
    DateTime? creationTime,
    bool? isNewUser,
    String? name,
    String? surname,
    DateTime? dob,
    String? profilePicPath,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      creationTime: creationTime ?? this.creationTime,
      isNewUser: isNewUser ?? this.isNewUser,
      name: name ?? this.name,
      surname: surname ?? this.surname,
      dob: dob ?? this.dob,
      profilePicPath: profilePicPath ?? this.profilePicPath,
    );
  }
}
