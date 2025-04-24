import 'dart:convert';

class UserModel {
  final String name;
  final String? profilePicturePath;
  final String defaultLanguage;
  final bool hasCompletedOnboarding;
  final String? uid;
  final String? email;
  final bool isAuthenticated;

  UserModel({
    this.name = '',
    this.profilePicturePath,
    this.defaultLanguage = 'en', // Default to English
    this.hasCompletedOnboarding = false,
    this.uid,
    this.email,
    this.isAuthenticated = false,
  });

  // Create a copy of this user model with updated fields
  UserModel copyWith({
    String? name,
    String? profilePicturePath,
    String? defaultLanguage,
    bool? hasCompletedOnboarding,
    String? uid,
    String? email,
    bool? isAuthenticated,
  }) {
    return UserModel(
      name: name ?? this.name,
      profilePicturePath: profilePicturePath ?? this.profilePicturePath,
      defaultLanguage: defaultLanguage ?? this.defaultLanguage,
      hasCompletedOnboarding: hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      uid: uid ?? this.uid,
      email: email ?? this.email,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }

  // Convert model to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'profilePicturePath': profilePicturePath,
      'defaultLanguage': defaultLanguage,
      'hasCompletedOnboarding': hasCompletedOnboarding,
      'uid': uid,
      'email': email,
      'isAuthenticated': isAuthenticated,
    };
  }

  // Create model from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      name: json['name'] ?? '',
      profilePicturePath: json['profilePicturePath'],
      defaultLanguage: json['defaultLanguage'] ?? 'en',
      hasCompletedOnboarding: json['hasCompletedOnboarding'] ?? false,
      uid: json['uid'],
      email: json['email'],
      isAuthenticated: json['isAuthenticated'] ?? false,
    );
  }

  // For storing in SharedPreferences
  String serialize() {
    return jsonEncode(toJson());
  }

  // For retrieving from SharedPreferences
  static UserModel deserialize(String data) {
    return UserModel.fromJson(jsonDecode(data));
  }
} 