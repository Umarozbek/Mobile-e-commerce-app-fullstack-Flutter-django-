class ProfileModel {
  final int? id;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? email;
  final String? image;
  final String? dateOfBirth;
  final String? gender;
  final bool? isActive;
  final String? createdAt;
  final String? updatedAt;

  ProfileModel({
    this.id,
    this.firstName,
    this.lastName,
    this.phone,
    this.email,
    this.image,
    this.dateOfBirth,
    this.gender,
    this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'],
      firstName: json['first_name'] ?? json['firstName'],
      lastName: json['last_name'] ?? json['lastName'],
      phone: json['phone'],
      email: json['email'],
      image: json['image'],
      dateOfBirth: json['date_of_birth'] ?? json['dateOfBirth'],
      gender: json['gender'],
      isActive: json['is_active'] ?? json['isActive'],
      createdAt: json['created_at'] ?? json['createdAt'],
      updatedAt: json['updated_at'] ?? json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'email': email,
      'image': image,
      'date_of_birth': dateOfBirth,
      'gender': gender,
      'is_active': isActive,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    return firstName ?? lastName ?? phone ?? 'Foydalanuvchi';
  }
}









