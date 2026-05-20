class UserModel {
  final String userId;
  final String role;
  final String phone;
  final bool isVerified;
  final bool isBlocked;
  final String storeId;
  final String createdAt;
  final String updatedAt;

  UserModel({
    required this.userId,
    required this.role,
    required this.phone,
    required this.isVerified,
    required this.isBlocked,
    required this.storeId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId'] ?? '',
      role: json['role'] ?? 'supplier',
      phone: json['phone'] ?? '',
      isVerified: json['isVerified'] == true || json['isVerified']?.toString().toLowerCase() == 'true',
      isBlocked: json['isBlocked'] == true || json['isBlocked']?.toString().toLowerCase() == 'true',
      storeId: json['storeId'] ?? '',
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'role': role,
      'phone': phone,
      'isVerified': isVerified,
      'isBlocked': isBlocked,
      'storeId': storeId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  UserModel copyWith({
    String? userId,
    String? role,
    String? phone,
    bool? isVerified,
    bool? isBlocked,
    String? storeId,
    String? createdAt,
    String? updatedAt,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      isVerified: isVerified ?? this.isVerified,
      isBlocked: isBlocked ?? this.isBlocked,
      storeId: storeId ?? this.storeId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
