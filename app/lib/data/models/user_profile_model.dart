class UserProfileModel {
  UserProfileModel({
    required this.name,
    this.id,
    this.email,
    this.avatar = '👤',
    this.bio,
    this.currency = 'USD',
    this.hasCompletedOnboarding = false,
  });

  final String? id;
  final String name;
  final String? email;
  final String avatar;
  final String? bio;
  final String currency;
  final bool hasCompletedOnboarding;

  UserProfileModel copyWith({
    String? id,
    String? name,
    String? email,
    String? avatar,
    String? bio,
    String? currency,
    bool? hasCompletedOnboarding,
  }) {
    return UserProfileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      bio: bio ?? this.bio,
      currency: currency ?? this.currency,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      if (email != null) 'email': email,
      'avatar': avatar,
      if (bio != null) 'bio': bio,
      'currency': currency,
      'hasCompletedOnboarding': hasCompletedOnboarding,
    };
  }

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] as String?,
      name: json['name'] as String? ?? '',
      email: json['email'] as String?,
      avatar: json['avatar'] as String? ?? '👤',
      bio: json['bio'] as String?,
      currency: json['currency'] as String? ?? 'USD',
      hasCompletedOnboarding:
          json['hasCompletedOnboarding'] as bool? ?? false,
    );
  }
}
