class UserModel {
  final String uid;
  final String fullName;
  final String email;
  final String phone;
  final String dob;
  final String gender;
  final String nationality;
  final String address;
  final String profileImage;
  final String emergencyContact1;
  final String emergencyContact2;
  final String emergencyContact3;
  final bool profileCompleted;

  UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.dob,
    required this.gender,
    required this.nationality,
    required this.address,
    required this.profileImage,
    required this.emergencyContact1,
    required this.emergencyContact2,
    required this.emergencyContact3,
    required this.profileCompleted,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'dob': dob,
      'gender': gender,
      'nationality': nationality,
      'address': address,
      'profileImage': profileImage,
      'emergencyContact1': emergencyContact1,
      'emergencyContact2': emergencyContact2,
      'emergencyContact3': emergencyContact3,
      'profileCompleted': profileCompleted,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      dob: map['dob'] ?? '',
      gender: map['gender'] ?? '',
      nationality: map['nationality'] ?? '',
      address: map['address'] ?? '',
      profileImage: map['profileImage'] ?? '',
      emergencyContact1: map['emergencyContact1'] ?? '',
      emergencyContact2: map['emergencyContact2'] ?? '',
      emergencyContact3: map['emergencyContact3'] ?? '',
      profileCompleted: map['profileCompleted'] ?? false,
    );
  }
}
