class FollowerModel {
  final String followId;
  final String storeId;
  final String userId;
  final String followedAt;

  FollowerModel({
    required this.followId,
    required this.storeId,
    required this.userId,
    required this.followedAt,
  });

  factory FollowerModel.fromJson(Map<String, dynamic> json) {
    return FollowerModel(
      followId: json['followId'] ?? '',
      storeId: json['storeId'] ?? '',
      userId: json['userId'] ?? '',
      followedAt: json['followedAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'followId': followId,
      'storeId': storeId,
      'userId': userId,
      'followedAt': followedAt,
    };
  }

  FollowerModel copyWith({
    String? followId,
    String? storeId,
    String? userId,
    String? followedAt,
  }) {
    return FollowerModel(
      followId: followId ?? this.followId,
      storeId: storeId ?? this.storeId,
      userId: userId ?? this.userId,
      followedAt: followedAt ?? this.followedAt,
    );
  }
}
