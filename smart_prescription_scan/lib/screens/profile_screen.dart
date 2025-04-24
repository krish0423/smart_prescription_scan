import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../constants/app_constants.dart';
import '../main.dart';
import '../models/language_model.dart';
import '../models/prescription_model.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with WidgetsBindingObserver {
  final TextEditingController _nameController = TextEditingController();
  final StorageService _storageService = StorageService();
  final ImagePicker _imagePicker = ImagePicker();
  final FocusNode _focusNode = FocusNode();
  
  String? _profileImagePath;
  String _selectedLanguage = 'en';
  bool _isEditing = false;
  
  // Add scan statistics variables
  int _totalScans = 0;
  int _importantScans = 0;
  String _firstScanDate = 'None yet';
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _focusNode.addListener(_onFocusChange);
    _loadUserPreferences();
    _loadScanStatistics();
    
    // Schedule a post-frame callback to load statistics after first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadScanStatistics();
    });
  }
  
  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _nameController.dispose();
    super.dispose();
  }
  
  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _loadScanStatistics();
    }
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh stats when app is resumed
      _loadScanStatistics();
    }
  }

  void _loadUserPreferences() {
    final userPreferences = Provider.of<AppStateProvider>(context, listen: false).userPreferences;
    
    setState(() {
      _nameController.text = userPreferences.name;
      _profileImagePath = userPreferences.profilePicturePath;
      _selectedLanguage = userPreferences.defaultLanguage;
    });
  }
  
  // Add method to load scan statistics
  void _loadScanStatistics() {
    // Get a fresh list of all prescriptions
    final allScans = _storageService.getAllPrescriptions();
    
    if (allScans.isEmpty) {
      setState(() {
        _totalScans = 0;
        _importantScans = 0;
        _firstScanDate = 'None yet';
      });
      return;
    }
    
    // Sort scans by date for finding the oldest one
    final sortedScans = List<PrescriptionModel>.from(allScans)
      ..sort((a, b) => a.dateScanned.compareTo(b.dateScanned));
    
    final importantScansCount = allScans.where((scan) => scan.isImportant).length;
    final firstScan = sortedScans.first;
    
    // Only update state if the component is still mounted to avoid setState errors
    if (mounted) {
      setState(() {
        _totalScans = allScans.length;
        _importantScans = importantScansCount;
        _firstScanDate = _formatDate(firstScan.dateScanned);
      });
    }
  }
  
  // Add helper method to format date
  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final scanDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    if (scanDate == today) {
      return 'Today';
    } else if (scanDate == yesterday) {
      return 'Yesterday';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
  
  Future<void> _pickProfileImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      
      if (pickedFile != null) {
        // Save image to app directory
        final savedImagePath = await _storageService.saveImage(File(pickedFile.path));
        
        setState(() {
          _profileImagePath = savedImagePath;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to pick image. Please try again.')),
      );
    }
  }
  
  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
      
      // If canceling edit, reload preferences to discard unsaved changes
      if (!_isEditing) {
        _loadUserPreferences();
      }
    });
  }
  
  Future<void> _saveChanges() async {
    final appStateProvider = Provider.of<AppStateProvider>(context, listen: false);
    
    // Update profile information
    await appStateProvider.updateUserProfile(
      name: _nameController.text,
      profilePicturePath: _profileImagePath,
    );
    
    // Update default language if changed
    if (_selectedLanguage != appStateProvider.userPreferences.defaultLanguage) {
      await appStateProvider.updateDefaultLanguage(_selectedLanguage);
    }
    
    setState(() {
      _isEditing = false;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.profile),
          actions: [
            _isEditing
                ? IconButton(
                    icon: const Icon(Icons.check),
                    onPressed: _saveChanges,
                    tooltip: 'Save Changes',
                  )
                : IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: _toggleEditMode,
                    tooltip: 'Edit Profile',
                  ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile image
              _buildProfileImage(),
              const SizedBox(height: AppDimensions.paddingL),
              
              // Name field
              _buildNameField(),
              const SizedBox(height: AppDimensions.paddingL),
              
              // Default language selector
              _buildLanguageSelector(),
              const SizedBox(height: AppDimensions.paddingXL),
              
              // Stats section (placeholders for now)
              _buildStatsSection(),
              const SizedBox(height: AppDimensions.paddingL),
              
              // Cancel edit button (only when editing)
              if (_isEditing)
                OutlinedButton.icon(
                  onPressed: _toggleEditMode,
                  icon: const Icon(Icons.cancel),
                  label: const Text('Cancel'),
                ),
              
              // Sign out button
              const SizedBox(height: 32),
              Center(
                child: ElevatedButton.icon(
                  onPressed: _signOut,
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign Out'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildProfileImage() {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: AppColors.cardBackground,
          backgroundImage: _profileImagePath != null
              ? FileImage(File(_profileImagePath!))
              : null,
          child: _profileImagePath == null
              ? const Icon(
                  Icons.person,
                  size: 60,
                  color: AppColors.textLight,
                )
              : null,
        ),
        if (_isEditing)
          GestureDetector(
            onTap: _pickProfileImage,
            child: Container(
              padding: const EdgeInsets.all(AppDimensions.paddingS),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryBlue,
              ),
              child: const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: AppDimensions.iconSizeM,
              ),
            ),
          ),
      ],
    );
  }
  
  Widget _buildNameField() {
    return TextField(
      controller: _nameController,
      enabled: _isEditing,
      decoration: InputDecoration(
        labelText: AppStrings.name,
        hintText: 'Enter your name',
        prefixIcon: const Icon(Icons.person),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
      ),
      textCapitalization: TextCapitalization.words,
    );
  }
  
  Widget _buildLanguageSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          AppStrings.defaultLanguage,
          style: AppTextStyles.subtitle,
        ),
        const SizedBox(height: AppDimensions.paddingS),
        DropdownButtonFormField<String>(
          value: _selectedLanguage,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.translate),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusL),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
          ),
          items: LanguageModel.supportedLanguages().map((language) {
            return DropdownMenuItem<String>(
              value: language.code,
              child: Text('${language.name} (${language.nativeName})'),
            );
          }).toList(),
          onChanged: _isEditing
              ? (value) {
                  if (value != null) {
                    setState(() {
                      _selectedLanguage = value;
                    });
                  }
                }
              : null,
        ),
      ],
    );
  }
  
  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Statistics',
          style: AppTextStyles.heading3,
        ),
        const SizedBox(height: AppDimensions.paddingM),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingL),
            child: Column(
              children: [
                _buildStatItem(
                  icon: Icons.document_scanner,
                  title: 'Total Scans',
                  value: '$_totalScans',
                ),
                const Divider(),
                _buildStatItem(
                  icon: Icons.star,
                  title: 'Important Scans',
                  value: '$_importantScans',
                ),
                const Divider(),
                _buildStatItem(
                  icon: Icons.calendar_today,
                  title: 'First Scan',
                  value: _firstScanDate,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildStatItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingS),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.primaryBlue,
            size: AppDimensions.iconSizeM,
          ),
          const SizedBox(width: AppDimensions.paddingM),
          Text(
            title,
            style: AppTextStyles.subtitle,
          ),
          const Spacer(),
          Text(
            value,
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  // Sign out method
  Future<void> _signOut() async {
    final appStateProvider = Provider.of<AppStateProvider>(context, listen: false);
    
    try {
      await appStateProvider.signOut();
      
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to sign out: ${e.toString()}')),
        );
      }
    }
  }
} 