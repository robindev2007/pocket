class UserProfileModel {
  UserProfileModel({
    required this.name,
    this.email,
    this.avatar = '👤',
    this.bio,
    this.hasCompletedOnboarding = false,
  });

  final String name;
  final String? email;
  final String avatar;
  final String? bio;
  final bool hasCompletedOnboarding;

  UserProfileModel copyWith({
    String? name,
    String? email,
    String? avatar,
    String? bio,
    bool? hasCompletedOnboarding,
  }) {
    return UserProfileModel(
      name: name ?? this.name,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      bio: bio ?? this.bio,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'avatar': avatar,
      'bio': bio,
      'hasCompletedOnboarding': hasCompletedOnboarding,
    };
  }

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      name: json['name'] as String? ?? '',
      email: json['email'] as String?,
      avatar: json['avatar'] as String? ?? '👤',
      bio: json['bio'] as String?,
      hasCompletedOnboarding:
          json['hasCompletedOnboarding'] as bool? ?? false,
    );
  }
}

