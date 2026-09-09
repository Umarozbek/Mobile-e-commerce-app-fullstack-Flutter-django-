import 'package:equatable/equatable.dart';

class LocationModel extends Equatable {
  final int? id;
  final int? user;
  final String address;
  final bool active;
  final String? created;
  final String? modified;
  
  // Backward compatibility fields (optional)
  final String name;
  final String phone;
  final String? description;
  final bool isDefault;

  const LocationModel({
    this.id,
    this.user,
    required this.address,
    this.active = true,
    this.created,
    this.modified,
    this.name = '',
    this.phone = '',
    this.description,
    this.isDefault = false,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: json['id'],
      user: json['user'],
      address: json['address'] ?? '',
      active: json['active'] ?? true,
      created: json['created'],
      modified: json['modified'],
      // Fallback for fields not in new API
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      description: json['description'],
      isDefault: json['is_default'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user,
      'address': address,
      'active': active,
      'created': created,
      'modified': modified,
      'name': name,
      'phone': phone,
      'description': description,
      'is_default': isDefault,
    };
  }

  LocationModel copyWith({
    int? id,
    int? user,
    String? address,
    bool? active,
    String? created,
    String? modified,
    String? name,
    String? phone,
    String? description,
    bool? isDefault,
  }) {
    return LocationModel(
      id: id ?? this.id,
      user: user ?? this.user,
      address: address ?? this.address,
      active: active ?? this.active,
      created: created ?? this.created,
      modified: modified ?? this.modified,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      description: description ?? this.description,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  String get fullAddress => address;

  @override
  List<Object?> get props => [id, user, address, active, created, modified, name, phone, description, isDefault];
}
