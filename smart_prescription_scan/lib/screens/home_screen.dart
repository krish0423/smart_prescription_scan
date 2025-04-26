import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../constants/app_constants.dart';
import '../main.dart';
import '../models/prescription_model.dart';
import '../services/storage_service.dart';
import 'upload_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'result_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final StorageService _storageService = StorageService();
  List<PrescriptionModel> _recentScans = [];
  int _currentIndex = 0;
  bool _skipInitialAnimations = true; // Skip animations on first load
  
  // Animation controller for page transitions and pulse effect
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  
  @override
  void initState() {
    super.initState();
    _loadRecentScans();
    
    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
      reverseDuration: const Duration(milliseconds: 1000),
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Set up pulse animation only (not entry animation)
    _animationController.forward();
    
    // Set repeat for pulse animation
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _animationController.forward();
      }
    });
    
    // After initial load, enable animations for future interactions
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _skipInitialAnimations = false;
        });
      }
    });
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  void _loadRecentScans() {
    // Get all prescriptions and sort by date
    List<PrescriptionModel> allScans = _storageService.getAllPrescriptions();
    allScans.sort((a, b) => b.dateScanned.compareTo(a.dateScanned));
    
    // Take only the 3 most recent scans
    setState(() {
      _recentScans = allScans.take(3).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userPreferences = Provider.of<AppStateProvider>(context).userPreferences;
    final size = MediaQuery.of(context).size;
    
    // Set status bar color
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              floating: true,
              pinned: false,
              expandedHeight: 120,
              backgroundColor: Colors.transparent,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimensions.paddingL,
                    AppDimensions.paddingM, 
                    AppDimensions.paddingL, 
                    0
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userPreferences.name.isNotEmpty 
                                      ? 'Hello, ${userPreferences.name}!' 
                                      : AppStrings.welcome,
                                  style: AppTextStyles.heading2,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Manage your prescriptions easily',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                _createPageRouteBuilder((context) => const ProfileScreen()),
                              ).then((_) => _loadRecentScans());
                            },
                            child: Hero(
                              tag: 'profile_avatar',
                              child: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryBlue.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.primaryBlue,
                                    width: 2,
                                  ),
                                ),
                                child: userPreferences.profilePicturePath.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(25),
                                        child: Image.file(
                                          File(userPreferences.profilePicturePath),
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : Icon(
                                        Icons.person,
                                        color: AppColors.primaryBlue,
                                        size: 26,
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Main content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick access cards
                    _buildQuickAccessGrid(),
                    
                    const SizedBox(height: AppDimensions.paddingL),
                    
                    // Recent scans section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          AppStrings.recentScans,
                          style: AppTextStyles.heading3,
                        ),
                        if (_recentScans.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                _createPageRouteBuilder((context) => const HistoryScreen()),
                              ).then((_) => _loadRecentScans());
                            },
                            child: Text(
                              'View all',
                              style: TextStyle(
                                color: AppColors.primaryBlue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.paddingM),
                    
                    // Recent scans list
                    _recentScans.isEmpty
                        ? _buildEmptyRecentScans()
                        : _skipInitialAnimations
                            ? Column(
                                children: _recentScans.map((scan) => _buildRecentScanItem(scan)).toList(),
                              )
                            : AnimationLimiter(
                                child: Column(
                                  children: List.generate(_recentScans.length, (index) {
                                    return AnimationConfiguration.staggeredList(
                                      position: index,
                                      duration: const Duration(milliseconds: 600),
                                      child: SlideAnimation(
                                        verticalOffset: 50.0,
                                        child: FadeInAnimation(
                                          child: _buildRecentScanItem(_recentScans[index]),
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withOpacity(0.3),
                    blurRadius: 10 * _pulseAnimation.value,
                    spreadRadius: 2 * _pulseAnimation.value,
                  ),
                ],
              ),
              child: child,
            ),
          );
        },
        child: SizedBox(
          height: 56,
          width: 56,
          child: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                _createPageRouteBuilder((context) => const UploadScreen()),
              ).then((_) => _loadRecentScans());
            },
            backgroundColor: AppColors.primaryBlue,
            child: const Icon(Icons.add_a_photo, size: 22),
            elevation: 4,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: Colors.white,
        elevation: 8,
        child: Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Home button
              Flexible(child: _buildNavItem(Icons.home, 'Home', 0)),
              
              // History button
              Flexible(child: _buildNavItem(Icons.history, 'History', 1)),
              
              // Empty space for FAB
              const SizedBox(width: 30),
              
              // Settings button
              Flexible(child: _buildNavItem(Icons.settings, 'Settings', 2)),
              
              // Profile button
              Flexible(child: _buildNavItem(Icons.person, 'Profile', 3)),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => _onNavItemTapped(index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primaryBlue : AppColors.textLight,
              size: 22,
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? AppColors.primaryBlue : AppColors.textLight,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onNavItemTapped(int index) {
    if (index == _currentIndex) return;
    
    setState(() {
      _currentIndex = index;
    });
    
    switch (index) {
      case 0: // Home - already here
        break;
      case 1: // History
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const HistoryScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              var begin = const Offset(1.0, 0.0);
              var end = Offset.zero;
              var curve = Curves.easeInOut;
              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              return SlideTransition(
                position: animation.drive(tween),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        ).then((_) {
          _loadRecentScans();
          setState(() => _currentIndex = 0);
        });
        break;
      case 2: // Settings
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const SettingsScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              var begin = const Offset(1.0, 0.0);
              var end = Offset.zero;
              var curve = Curves.easeInOut;
              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              return SlideTransition(
                position: animation.drive(tween),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        ).then((_) {
          _loadRecentScans();
          setState(() => _currentIndex = 0);
        });
        break;
      case 3: // Profile
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const ProfileScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              var begin = const Offset(1.0, 0.0);
              var end = Offset.zero;
              var curve = Curves.easeInOut;
              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              return SlideTransition(
                position: animation.drive(tween),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 300),
            settings: const RouteSettings(name: '/profile'),
          ),
        ).then((_) {
          _loadRecentScans();
          setState(() => _currentIndex = 0);
        });
        break;
    }
  }

  Widget _buildQuickAccessGrid() {
    if (_skipInitialAnimations) {
      // Without animations on first load
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          _buildQuickAccessCard(
            icon: Icons.document_scanner,
            iconColor: AppColors.primaryBlue,
            title: 'Scan Prescription',
            description: 'Scan a new prescription',
            onTap: () {
              Navigator.push(
                context,
                _createPageRouteBuilder((context) => const UploadScreen()),
              ).then((_) => _loadRecentScans());
            },
          ),
          _buildQuickAccessCard(
            icon: Icons.person,
            iconColor: AppColors.warning,
            title: 'Profile',
            description: 'Your information',
            onTap: () {
              Navigator.push(
                context,
                _createPageRouteBuilder((context) => const ProfileScreen()),
              ).then((_) => _loadRecentScans());
            },
          ),
          _buildQuickAccessCard(
            icon: Icons.history,
            iconColor: AppColors.primaryPurple,
            title: 'View History',
            description: 'See all your scans',
            onTap: () {
              Navigator.push(
                context,
                _createPageRouteBuilder((context) => const HistoryScreen()),
              ).then((_) => _loadRecentScans());
            },
          ),
          _buildQuickAccessCard(
            icon: Icons.settings,
            iconColor: AppColors.success,
            title: 'Settings',
            description: 'App preferences',
            onTap: () {
              Navigator.push(
                context,
                _createPageRouteBuilder((context) => const SettingsScreen()),
              ).then((_) => _loadRecentScans());
            },
          ),
        ],
      );
    }
    
    // With animations for subsequent interactions
    return AnimationLimiter(
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: List.generate(4, (index) {
          Widget card;
          VoidCallback onTap;
          Widget Function(BuildContext) builder;
          
          switch(index) {
            case 0:
              builder = (context) => const UploadScreen();
              onTap = () {
                Navigator.push(
                  context,
                  _createPageRouteBuilder(builder),
                ).then((_) => _loadRecentScans());
              };
              card = _buildQuickAccessCard(
                icon: Icons.document_scanner,
                iconColor: AppColors.primaryBlue,
                title: 'Scan Prescription',
                description: 'Scan a new prescription',
                onTap: onTap,
              );
              break;
            case 1:
              builder = (context) => const ProfileScreen();
              onTap = () {
                Navigator.push(
                  context,
                  _createPageRouteBuilder(builder),
                ).then((_) => _loadRecentScans());
              };
              card = _buildQuickAccessCard(
                icon: Icons.person,
                iconColor: AppColors.warning,
                title: 'Profile',
                description: 'Your information',
                onTap: onTap,
              );
              break;
            case 2:
              builder = (context) => const HistoryScreen();
              onTap = () {
                Navigator.push(
                  context,
                  _createPageRouteBuilder(builder),
                ).then((_) => _loadRecentScans());
              };
              card = _buildQuickAccessCard(
                icon: Icons.history,
                iconColor: AppColors.primaryPurple,
                title: 'View History',
                description: 'See all your scans',
                onTap: onTap,
              );
              break;
            case 3:
              builder = (context) => const SettingsScreen();
              onTap = () {
                Navigator.push(
                  context,
                  _createPageRouteBuilder(builder),
                ).then((_) => _loadRecentScans());
              };
              card = _buildQuickAccessCard(
                icon: Icons.settings,
                iconColor: AppColors.success,
                title: 'Settings',
                description: 'App preferences',
                onTap: onTap,
              );
              break;
            default:
              card = const SizedBox();
              onTap = () {};
              builder = (context) => const SizedBox();
          }
          
          return AnimationConfiguration.staggeredGrid(
            position: index,
            duration: const Duration(milliseconds: 500),
            columnCount: 2,
            child: ScaleAnimation(
              scale: 0.9,
              child: FadeInAnimation(
                child: card,
              ),
            ),
          );
        }),
      ),
    );
  }

  PageRouteBuilder _createPageRouteBuilder(Widget Function(BuildContext) builder) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var begin = const Offset(1.0, 0.0);
        var end = Offset.zero;
        var curve = Curves.easeInOut;
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        
        var fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeIn)
        );
        
        return FadeTransition(
          opacity: fadeAnimation,
          child: SlideTransition(
            position: animation.drive(tween),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  Widget _buildQuickAccessCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 1.0, end: 1.0),
      duration: const Duration(milliseconds: 200),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: Builder(
        builder: (context) {
          return GestureDetector(
            onTapDown: (_) {
              // When the card is pressed, update the tween
              final TweenAnimationBuilder<double> tweenAnimation = 
                  context.findAncestorWidgetOfExactType<TweenAnimationBuilder<double>>()!;
              tweenAnimation.tween.begin = 0.95;
              tweenAnimation.tween.end = 0.95;
            },
            onTapUp: (_) {
              // When the card is released, update the tween
              final TweenAnimationBuilder<double> tweenAnimation = 
                  context.findAncestorWidgetOfExactType<TweenAnimationBuilder<double>>()!;
              tweenAnimation.tween.begin = 0.95;
              tweenAnimation.tween.end = 1.0;
            },
            onTapCancel: () {
              // When tap is canceled, reset the scale
              final TweenAnimationBuilder<double> tweenAnimation = 
                  context.findAncestorWidgetOfExactType<TweenAnimationBuilder<double>>()!;
              tweenAnimation.tween.begin = 0.95;
              tweenAnimation.tween.end = 1.0;
            },
            onTap: onTap,
            child: Card(
              elevation: 3,
              shadowColor: iconColor.withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      iconColor.withOpacity(0.1),
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: iconColor.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        icon,
                        color: iconColor,
                        size: 24,
                      ),
                    ),
                    const Spacer(flex: 1),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      ),
    );
  }

  Widget _buildEmptyRecentScans() {
    if (_skipInitialAnimations) {
      // Without animations on first load
      return Container(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          border: Border.all(
            color: AppColors.divider,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.description_outlined,
                size: 32,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingM),
            Text(
              AppStrings.noRecentScans,
              style: AppTextStyles.subtitle.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Scan your first prescription',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingL),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  _createPageRouteBuilder((context) => const UploadScreen()),
                ).then((_) => _loadRecentScans());
              },
              icon: const Icon(Icons.add_a_photo, size: 16),
              label: const Text('Scan Now'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                shadowColor: AppColors.primaryBlue.withOpacity(0.3),
              ),
            ),
          ],
        ),
      );
    }
    
    // With animations for subsequent interactions
    return AnimationConfiguration.synchronized(
      duration: const Duration(milliseconds: 800),
      child: SlideAnimation(
        verticalOffset: 50.0,
        child: FadeInAnimation(
          child: Container(
            padding: const EdgeInsets.all(AppDimensions.paddingL),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(AppDimensions.radiusL),
              border: Border.all(
                color: AppColors.divider,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.description_outlined,
                          size: 32,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppDimensions.paddingM),
                Text(
                  AppStrings.noRecentScans,
                  style: AppTextStyles.subtitle.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Scan your first prescription',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingL),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      _createPageRouteBuilder((context) => const UploadScreen()),
                    ).then((_) => _loadRecentScans());
                  },
                  icon: const Icon(Icons.add_a_photo, size: 16),
                  label: const Text('Scan Now'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                    shadowColor: AppColors.primaryBlue.withOpacity(0.3),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentScanItem(PrescriptionModel scan) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 1.0, end: 1.0),
      duration: const Duration(milliseconds: 200),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: Builder(
        builder: (context) {
          return GestureDetector(
            onTapDown: (_) {
              final TweenAnimationBuilder<double> tweenAnimation = 
                  context.findAncestorWidgetOfExactType<TweenAnimationBuilder<double>>()!;
              tweenAnimation.tween.begin = 0.98;
              tweenAnimation.tween.end = 0.98;
            },
            onTapUp: (_) {
              final TweenAnimationBuilder<double> tweenAnimation = 
                  context.findAncestorWidgetOfExactType<TweenAnimationBuilder<double>>()!;
              tweenAnimation.tween.begin = 0.98;
              tweenAnimation.tween.end = 1.0;
            },
            onTapCancel: () {
              final TweenAnimationBuilder<double> tweenAnimation = 
                  context.findAncestorWidgetOfExactType<TweenAnimationBuilder<double>>()!;
              tweenAnimation.tween.begin = 0.98;
              tweenAnimation.tween.end = 1.0;
            },
            onTap: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => 
                    ResultScreen(prescription: scan),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    // Create hero animation for prescription image
                    return FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                  },
                  transitionDuration: const Duration(milliseconds: 300),
                ),
              ).then((_) => _loadRecentScans());
            },
            child: Card(
              margin: const EdgeInsets.only(bottom: AppDimensions.paddingM),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusL),
              ),
              elevation: 3,
              shadowColor: AppColors.primaryBlue.withOpacity(0.2),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      scan.isImportant 
                          ? AppColors.warning.withOpacity(0.05)
                          : AppColors.primaryBlue.withOpacity(0.05),
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(AppDimensions.paddingM),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Image preview with gradient overlay
                    Hero(
                      tag: 'prescription_image_${scan.id}',
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 3,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              _buildImagePreview(scan),
                              // Gradient overlay
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.6),
                                    ],
                                    stops: const [0.7, 1.0],
                                  ),
                                ),
                              ),
                              // Important icon if marked
                              if (scan.isImportant)
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Icon(
                                      Icons.star,
                                      color: AppColors.warning,
                                      size: 14,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: AppDimensions.paddingM),
                    
                    // Scan info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 12,
                                color: AppColors.textLight,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatDate(scan.dateScanned),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textLight,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          
                          // Summary preview
                          Text(
                            _getSummaryPreview(scan.summary),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          
                          // Medicine count badge
                          if (scan.medicines.isNotEmpty)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryBlue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.medication_outlined,
                                        size: 12,
                                        color: AppColors.primaryBlue,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${scan.medicines.length} ${scan.medicines.length == 1 ? 'medicine' : 'medicines'}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.primaryBlue,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    
                    // Arrow icon
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward_ios,
                          color: AppColors.primaryBlue,
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      ),
    );
  }
  
  Widget _buildImagePreview(PrescriptionModel scan) {
    if (scan.imagePath.isEmpty) {
      return Container(
        color: AppColors.cardBackground,
        child: const Icon(
          Icons.description,
          color: AppColors.primaryBlue,
          size: 40,
        ),
      );
    } else {
      // Check if this is running on web
      if (kIsWeb) {
        return Container(
          color: AppColors.cardBackground,
          child: const Icon(
            Icons.image,
            color: AppColors.primaryBlue,
            size: 40,
          ),
        );
      } else {
        return Image.file(
          File(scan.imagePath),
          fit: BoxFit.cover,
        );
      }
    }
  }
  
  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final scanDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    if (scanDate == today) {
      return 'Today, ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (scanDate == yesterday) {
      return 'Yesterday, ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
  
  String _getSummaryPreview(String summary) {
    // Return first 100 characters as preview
    if (summary.length > 100) {
      return '${summary.substring(0, 100)}...';
    }
    return summary;
  }
} 