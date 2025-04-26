import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:math' show pi;

import '../constants/app_constants.dart';
import '../main.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  int _currentPage = 0;
  
  final List<_OnboardingStep> _steps = [
    _OnboardingStep(
      title: 'Welcome to Smart Prescription Scan',
      description: 'Easily scan, understand, and manage your medical prescriptions.',
      image: 'assets/images/onboarding_1.png', // Placeholder - Add actual image
      icon: Icons.document_scanner,
      color: AppColors.primaryBlue,
    ),
    _OnboardingStep(
      title: 'AI-Powered Summaries',
      description: 'Our app uses AI to analyze and summarize your prescriptions in simple language.',
      image: 'assets/images/onboarding_2.png', // Placeholder - Add actual image
      icon: Icons.psychology,
      color: AppColors.primaryPurple,
    ),
    _OnboardingStep(
      title: 'Translate to Your Language',
      description: 'Translate prescriptions to multiple languages for better understanding.',
      image: 'assets/images/onboarding_3.png', // Placeholder - Add actual image
      icon: Icons.translate,
      color: Colors.orange,
    ),
    _OnboardingStep(
      title: 'Safe and Secure',
      description: 'All your data is stored locally on your device. No cloud storage required.',
      image: 'assets/images/onboarding_4.png', // Placeholder - Add actual image
      icon: Icons.lock,
      color: AppColors.success,
    ),
  ];

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    // Start animation
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

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
        duration: const Duration(milliseconds: 500),
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              _steps[_currentPage].color.withOpacity(0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextButton(
                    onPressed: _skipOnboarding,
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      backgroundColor: Colors.white.withOpacity(0.3),
                    ),
                    child: Text(
                      AppStrings.skip,
                      style: AppTextStyles.subtitle.copyWith(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.bold,
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
                      // Reset and start animation for new page
                      _animationController.reset();
                      _animationController.forward();
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
                    (index) => _buildPageIndicator(index == _currentPage, _steps[index].color),
                  ),
                ),
              ),
              
              // Next/Get Started button
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: SizedBox(
                  width: double.infinity,
                  height: AppDimensions.buttonHeight,
                  child: ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _steps[_currentPage].color,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _currentPage == _steps.length - 1
                              ? AppStrings.getStarted
                              : AppStrings.next,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _currentPage == _steps.length - 1
                              ? Icons.check_circle
                              : Icons.arrow_forward,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOnboardingStep(_OnboardingStep step) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated icon
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 800),
                curve: Curves.elasticOut,
                builder: (context, double value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        color: step.color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: step.color.withOpacity(0.3),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: step.color.withOpacity(0.2),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              step.icon,
                              size: 70,
                              color: step.color,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 50),
              
              // Title with animated underline
              Text(
                step.title,
                style: AppTextStyles.heading2.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOut,
                builder: (context, double value, child) {
                  return Container(
                    width: 100 * value,
                    height: 3,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: step.color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              
              // Description
              Text(
                step.description,
                style: AppTextStyles.subtitle.copyWith(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageIndicator(bool isActive, Color color) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      height: 8.0,
      width: isActive ? 24.0 : 8.0,
      decoration: BoxDecoration(
        color: isActive ? color : AppColors.divider,
        borderRadius: BorderRadius.circular(4.0),
        boxShadow: isActive ? [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ] : null,
      ),
    );
  }
}

class _OnboardingStep {
  final String title;
  final String description;
  final String image;
  final IconData icon;
  final Color color;

  _OnboardingStep({
    required this.title,
    required this.description,
    required this.image,
    required this.icon,
    required this.color,
  });
} 