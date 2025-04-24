import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'constants/app_constants.dart';
import 'models/user_model.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/storage_service.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase for web
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize storage service
  final storageService = StorageService();
  await storageService.init();
  
  // Get user preferences
  final userPreferences = storageService.getUserPreferences();
  
  runApp(MyApp(userPreferences: userPreferences));
}

class MyApp extends StatelessWidget {
  final UserModel userPreferences;
  
  const MyApp({super.key, required this.userPreferences});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppStateProvider(userPreferences),
      child: MaterialApp(
        title: AppStrings.appName,
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final appStateProvider = Provider.of<AppStateProvider>(context);
    final authService = AuthService();
    
    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // If user is authenticated in Firebase
        if (snapshot.hasData) {
          // Update user data if needed
          if (!appStateProvider.userPreferences.isAuthenticated) {
            final user = snapshot.data!;
            appStateProvider.updateUserPreferences(
              appStateProvider.userPreferences.copyWith(
                uid: user.uid,
                email: user.email,
                isAuthenticated: true,
              ),
            );
          }
          
          // Show onboarding if not completed, otherwise show home screen
          return appStateProvider.userPreferences.hasCompletedOnboarding
              ? const HomeScreen()
              : const OnboardingScreen();
        }
        
        // If authentication state is loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        // If not authenticated and onboarding completed, show login screen
        if (appStateProvider.userPreferences.hasCompletedOnboarding) {
          // Clean up any stale auth data
          if (appStateProvider.userPreferences.isAuthenticated) {
            appStateProvider.updateUserPreferences(
              appStateProvider.userPreferences.copyWith(
                uid: null,
                email: null,
                isAuthenticated: false,
              ),
            );
          }
          return const LoginScreen();
        }
        
        // If not authenticated and onboarding not completed
        return const OnboardingScreen();
      },
    );
  }
}

class AppStateProvider extends ChangeNotifier {
  UserModel _userPreferences;
  final StorageService _storageService = StorageService();
  
  AppStateProvider(this._userPreferences);
  
  UserModel get userPreferences => _userPreferences;
  
  // Update user preferences
  Future<void> updateUserPreferences(UserModel updatedPreferences) async {
    _userPreferences = updatedPreferences;
    await _storageService.saveUserPreferences(_userPreferences);
    notifyListeners();
  }
  
  // Set onboarding as completed
  Future<void> completeOnboarding() async {
    final updatedPreferences = _userPreferences.copyWith(hasCompletedOnboarding: true);
    await updateUserPreferences(updatedPreferences);
  }
  
  // Update default language
  Future<void> updateDefaultLanguage(String languageCode) async {
    final updatedPreferences = _userPreferences.copyWith(defaultLanguage: languageCode);
    await updateUserPreferences(updatedPreferences);
  }
  
  // Update user profile
  Future<void> updateUserProfile({String? name, String? profilePicturePath}) async {
    final updatedPreferences = _userPreferences.copyWith(
      name: name,
      profilePicturePath: profilePicturePath,
    );
    await updateUserPreferences(updatedPreferences);
  }
  
  // Sign out user
  Future<void> signOut() async {
    final authService = AuthService();
    await authService.signOut();
    
    // Reset authentication state
    final updatedPreferences = _userPreferences.copyWith(
      uid: null,
      email: null,
      isAuthenticated: false,
    );
    await updateUserPreferences(updatedPreferences);
  }
}
