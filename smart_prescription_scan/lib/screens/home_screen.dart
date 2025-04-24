import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';

import '../constants/app_constants.dart';
import '../main.dart';
import '../models/prescription_model.dart';
import '../services/storage_service.dart';
import 'upload_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StorageService _storageService = StorageService();
  List<PrescriptionModel> _recentScans = [];
  
  @override
  void initState() {
    super.initState();
    _loadRecentScans();
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
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppStrings.appName,
          style: AppTextStyles.heading3,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              ).then((_) => _loadRecentScans());
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome header
              Text(
                userPreferences.name.isNotEmpty 
                    ? 'Hello, ${userPreferences.name}!' 
                    : AppStrings.welcome,
                style: AppTextStyles.heading2,
              ),
              const SizedBox(height: AppDimensions.paddingL),
              
              // Main action buttons
              _buildActionCard(
                icon: Icons.document_scanner,
                title: AppStrings.uploadNewPrescription,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const UploadScreen()),
                  ).then((_) => _loadRecentScans());
                },
              ),
              const SizedBox(height: AppDimensions.paddingM),
              
              _buildActionCard(
                icon: Icons.history,
                title: AppStrings.viewHistory,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HistoryScreen()),
                  ).then((_) => _loadRecentScans());
                },
              ),
              const SizedBox(height: AppDimensions.paddingM),
              
              // Recent scans section
              const Text(
                AppStrings.recentScans,
                style: AppTextStyles.heading3,
              ),
              const SizedBox(height: AppDimensions.paddingM),
              
              // Recent scans list
              _recentScans.isEmpty
                  ? _buildEmptyRecentScans()
                  : Column(
                      children: _recentScans.map((scan) => _buildRecentScanItem(scan)).toList(),
                    ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        onTap: (index) {
          if (index == 0) {
            // Already on home screen
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HistoryScreen()),
            ).then((_) => _loadRecentScans());
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ProfileScreen(),
                settings: const RouteSettings(name: '/profile'),
              ),
            ).then((_) {
              // Refresh the recent scans when returning from profile screen
              _loadRecentScans();
            });
          }
        },
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.paddingM),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primaryBlue,
                  size: AppDimensions.iconSizeL,
                ),
              ),
              const SizedBox(width: AppDimensions.paddingL),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.subtitle.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: AppColors.textLight,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyRecentScans() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.description_outlined,
            size: 48,
            color: AppColors.textLight,
          ),
          const SizedBox(height: AppDimensions.paddingM),
          Text(
            AppStrings.noRecentScans,
            style: AppTextStyles.subtitle.copyWith(
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingL),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UploadScreen()),
              ).then((_) => _loadRecentScans());
            },
            child: const Text(AppStrings.uploadNewPrescription),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentScanItem(PrescriptionModel scan) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingM),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to view the scan detail
          // Will be implemented later
        },
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          child: Row(
            children: [
              // Image preview
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  image: DecorationImage(
                    image: FileImage(File(scan.imagePath)),
                    fit: BoxFit.cover,
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
                    Text(
                      _formatDate(scan.dateScanned),
                      style: AppTextStyles.caption,
                    ),
                    const SizedBox(height: 4),
                    
                    // Summary preview
                    Text(
                      _getSummaryPreview(scan.summary),
                      style: AppTextStyles.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              // Important icon if marked
              if (scan.isImportant)
                const Icon(
                  Icons.star,
                  color: AppColors.warning,
                  size: AppDimensions.iconSizeM,
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  String _formatDate(DateTime dateTime) {
    // Format date as 'Month dd, yyyy'
    final month = _getMonthName(dateTime.month);
    return '$month ${dateTime.day}, ${dateTime.year}';
  }
  
  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return months[month - 1];
  }
  
  String _getSummaryPreview(String summary) {
    // Return first 100 characters as preview
    if (summary.length > 100) {
      return '${summary.substring(0, 100)}...';
    }
    return summary;
  }
} 