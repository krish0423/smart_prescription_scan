import 'dart:convert';

class UserModel {
  final String? uid;
  final String? email;
  final String name;
  final String profilePicturePath;
  final bool isAuthenticated;
  final bool hasCompletedOnboarding;
  final String defaultLanguage;
  
  UserModel({
    this.uid,
    this.email,
    this.name = '',
    this.profilePicturePath = '',
    this.isAuthenticated = false,
    this.hasCompletedOnboarding = false,
    this.defaultLanguage = 'en',
  });
  
  // Create a copy of this user model with updated fields
  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? profilePicturePath,
    bool? isAuthenticated,
    bool? hasCompletedOnboarding,
    String? defaultLanguage,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      profilePicturePath: profilePicturePath ?? this.profilePicturePath,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      hasCompletedOnboarding: hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      defaultLanguage: defaultLanguage ?? this.defaultLanguage,
    );
  }
  
  // Convert model to JSON
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'profilePicturePath': profilePicturePath,
      'isAuthenticated': isAuthenticated,
      'hasCompletedOnboarding': hasCompletedOnboarding,
      'defaultLanguage': defaultLanguage,
    };
  }
  
  // Create model from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'],
      email: json['email'],
      name: json['name'] ?? '',
      profilePicturePath: json['profilePicturePath'] ?? '',
      isAuthenticated: json['isAuthenticated'] ?? false,
      hasCompletedOnboarding: json['hasCompletedOnboarding'] ?? false,
      defaultLanguage: json['defaultLanguage'] ?? 'en',
    );
  }
  
  // For storing in storage if needed
  String serialize() {
    return jsonEncode(toJson());
  }
  
  // For retrieving from storage if needed
  static UserModel deserialize(String data) {
    return UserModel.fromJson(jsonDecode(data));
  }
  
  // Default user model for new installations
  static UserModel defaultUser() {
    return UserModel(
      uid: null,
      email: null,
      name: '',
      profilePicturePath: '',
      isAuthenticated: false,
      hasCompletedOnboarding: false,
      defaultLanguage: 'en',
    );
  }
} 