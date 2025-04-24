import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

import '../constants/app_constants.dart';
import '../main.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  final List<_OnboardingStep> _steps = [
    _OnboardingStep(
      title: 'Welcome to Smart Prescription Scan',
      description: 'Easily scan, understand, and manage your medical prescriptions.',
      image: 'assets/images/onboarding_1.png', // Placeholder - Add actual image
      icon: Icons.document_scanner,
    ),
    _OnboardingStep(
      title: 'AI-Powered Summaries',
      description: 'Our app uses AI to analyze and summarize your prescriptions in simple language.',
      image: 'assets/images/onboarding_2.png', // Placeholder - Add actual image
      icon: Icons.psychology,
    ),
    _OnboardingStep(
      title: 'Translate to Your Language',
      description: 'Translate prescriptions to multiple languages for better understanding.',
      image: 'assets/images/onboarding_3.png', // Placeholder - Add actual image
      icon: Icons.translate,
    ),
    _OnboardingStep(
      title: 'Safe and Secure',
      description: 'All your data is stored locally on your device. No cloud storage required.',
      image: 'assets/images/onboarding_4.png', // Placeholder - Add actual image
      icon: Icons.lock,
    ),
  ];

  Future<void> _requestPermissions() async {
    // Skip permission requests on web and desktop platforms where they might not be implemented
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
      return;
    }
    
    try {
      // Request camera permission
      await Permission.camera.request();
      
      // Request storage permission for accessing gallery
      if (await Permission.photos.isGranted == false) {
        await Permission.photos.request();
      }
    } catch (e) {
      // Ignore permission errors, as they should not block the app from proceeding
      debugPrint('Error requesting permissions: $e');
    }
  }

  void _nextPage() {
    if (_currentPage < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _skipOnboarding() {
    _completeOnboarding();
  }

  Future<void> _completeOnboarding() async {
    try {
      // Request permissions (will be skipped on unsupported platforms)
      await _requestPermissions();
      
      // Mark onboarding as completed
      if (mounted) {
        await Provider.of<AppStateProvider>(context, listen: false).completeOnboarding();
        
        // Navigate to login screen instead of home screen
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      }
    } catch (e) {
      debugPrint('Error completing onboarding: $e');
      // Even if there's an error, try to navigate to the login screen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextButton(
                  onPressed: _skipOnboarding,
                  child: Text(
                    AppStrings.skip,
                    style: AppTextStyles.subtitle.copyWith(
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
              ),
            ),
            
            // Onboarding pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _steps.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final step = _steps[index];
                  return _buildOnboardingStep(step);
                },
              ),
            ),
            
            // Page indicator
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _steps.length,
                  (index) => _buildPageIndicator(index == _currentPage),
                ),
              ),
            ),
            
            // Next/Get Started button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: AppDimensions.buttonHeight,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  child: Text(
                    _currentPage == _steps.length - 1
                        ? AppStrings.getStarted
                        : AppStrings.next,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingStep(_OnboardingStep step) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Placeholder for image
          Icon(
            step.icon,
            size: 120,
            color: AppColors.primaryBlue,
          ),
          const SizedBox(height: 40),
          
          // Title
          Text(
            step.title,
            style: AppTextStyles.heading2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          
          // Description
          Text(
            step.description,
            style: AppTextStyles.subtitle,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(bool isActive) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      height: 8.0,
      width: isActive ? 24.0 : 8.0,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primaryBlue : AppColors.divider,
        borderRadius: BorderRadius.circular(4.0),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class _OnboardingStep {
  final String title;
  final String description;
  final String image;
  final IconData icon;

  _OnboardingStep({
    required this.title,
    required this.description,
    required this.image,
    required this.icon,
  });
} 