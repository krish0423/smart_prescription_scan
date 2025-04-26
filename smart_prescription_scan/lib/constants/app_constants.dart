import 'package:flutter/material.dart';

// App Colors
class AppColors {
  // Primary Colors
  static const Color primaryBlue = Color(0xFF2E7BFF);
  static const Color primaryPurple = Color(0xFF6E5AFF);
  
  // Secondary Colors
  static const Color secondaryBlue = Color(0xFF91BBFF);
  static const Color secondaryPurple = Color(0xFFA59EFF);
  
  // Background Colors
  static const Color background = Colors.white;
  static const Color cardBackground = Color(0xFFF5F7FF);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF4A5568);
  static const Color textLight = Color(0xFF718096);
  
  // Status Colors
  static const Color success = Color(0xFF28C76F);
  static const Color warning = Color(0xFFFF9F43);
  static const Color error = Color(0xFFEA5455);
  static const Color info = Color(0xFF00CFE8);
  
  // Additional Colors
  static const Color divider = Color(0xFFE2E8F0);
  static const Color shadow = Color(0x1A000000);
}

// Text Styles
class AppTextStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle heading3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle subtitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );
  
  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle bodyBold = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textLight,
  );
  
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
}

// App Theme
class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.light(
      primary: AppColors.primaryBlue,
      secondary: AppColors.primaryPurple,
      background: AppColors.background,
      error: AppColors.error,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      elevation: 0,
      titleTextStyle: AppTextStyles.heading3,
      iconTheme: IconThemeData(color: AppColors.textPrimary),
    ),
    cardTheme: CardTheme(
      color: AppColors.cardBackground,
      elevation: 2,
      shadowColor: AppColors.shadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        textStyle: AppTextStyles.button,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryBlue,
        side: const BorderSide(color: AppColors.primaryBlue),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        textStyle: AppTextStyles.button.copyWith(color: AppColors.primaryBlue),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.divider,
      thickness: 1,
      space: 24,
    ),
  );
}

// App Dimensions
class AppDimensions {
  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 16.0;
  static const double paddingL = 24.0;
  static const double paddingXL = 32.0;
  
  static const double radiusS = 4.0;
  static const double radiusM = 8.0;
  static const double radiusL = 12.0;
  static const double radiusXL = 16.0;
  
  static const double iconSizeS = 16.0;
  static const double iconSizeM = 24.0;
  static const double iconSizeL = 32.0;
  
  static const double buttonHeight = 48.0;
}

// App Strings
class AppStrings {
  // App Name
  static const String appName = "Smart Prescription Scan";
  
  // Onboarding
  static const String getStarted = "Get Started";
  static const String skip = "Skip";
  static const String next = "Next";
  
  // Home Screen
  static const String welcome = "Welcome to Smart Prescription Scan";
  static const String uploadNewPrescription = "Upload New Prescription";
  static const String viewHistory = "View History";
  static const String languagePreference = "Language Preference";
  static const String recentScans = "Recent Scans";
  static const String noRecentScans = "No recent scans yet";
  
  // Upload Screen
  static const String selectImage = "Select an Image";
  static const String camera = "Camera";
  static const String gallery = "Gallery";
  static const String processing = "Processing...";
  static const String uploading = "Uploading...";
  static const String summarizing = "Summarizing...";
  static const String translating = "Translating...";
  
  // Result Screen
  static const String summary = "Summary";
  static const String translate = "Translate";
  static const String copy = "Copy";
  static const String save = "Save";
  static const String share = "Share";
  static const String markAsImportant = "Mark as Important";
  
  // History Screen
  static const String history = "Scan History";
  static const String search = "Search scans";
  static const String filter = "Filter";
  static const String sortBy = "Sort by";
  static const String noHistory = "No scan history yet";
  
  // Profile Screen
  static const String profile = "Profile";
  static const String editProfile = "Edit Profile";
  static const String name = "Name";
  static const String defaultLanguage = "Default Language";
  
  // Settings Screen
  static const String settings = "Settings";
  static const String language = "Language";
  static const String theme = "Theme";
  static const String light = "Light";
  static const String version = "Version";
  
  // Error Messages
  static const String errorOccurred = "An error occurred";
  static const String tryAgain = "Try Again";
  static const String noInternet = "No internet connection";
  static const String cameraPermission = "Camera permission required";
  static const String storagePermission = "Storage permission required";
} 