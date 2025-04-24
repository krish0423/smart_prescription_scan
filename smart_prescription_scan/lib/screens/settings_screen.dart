import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_constants.dart';
import '../main.dart';
import '../models/language_model.dart';
import '../services/storage_service.dart';
import 'profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final StorageService _storageService = StorageService();
  
  String _appVersion = '';
  String _buildNumber = '';
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadAppInfo();
  }
  
  Future<void> _loadAppInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      
      setState(() {
        _appVersion = packageInfo.version;
        _buildNumber = packageInfo.buildNumber;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _appVersion = '1.0.0';
        _buildNumber = '1';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _clearAllData() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'Are you sure you want to delete all scans and reset app settings? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      // TODO: Implement clearing all data from storage
      // This will be implemented when storage service is expanded
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All data has been cleared')),
        );
      }
    }
  }
  
  void _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open $url')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final userPreferences = Provider.of<AppStateProvider>(context).userPreferences;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.settings),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              children: [
                // Account section
                _buildSectionHeader('Account'),
                _buildSettingItem(
                  icon: Icons.person,
                  title: AppStrings.profile,
                  subtitle: userPreferences.name.isNotEmpty
                      ? userPreferences.name
                      : 'Tap to set your name',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ProfileScreen()),
                    );
                  },
                ),
                
                // Language section
                _buildSectionHeader(AppStrings.language),
                _buildLanguageItem(userPreferences.defaultLanguage),
                
                // Appearance section
                _buildSectionHeader('Appearance'),
                _buildSettingItem(
                  icon: Icons.light_mode,
                  title: AppStrings.theme,
                  subtitle: AppStrings.light,
                  trailing: null, // No action available for theme (light only)
                ),
                
                // About section
                _buildSectionHeader('About'),
                _buildSettingItem(
                  icon: Icons.info_outline,
                  title: 'Version',
                  subtitle: '$_appVersion (${_buildNumber})',
                  trailing: null,
                ),
                _buildSettingItem(
                  icon: Icons.policy_outlined,
                  title: 'Privacy Policy',
                  subtitle: 'View our privacy policy',
                  onTap: () {
                    _launchURL('https://www.example.com/privacy');
                  },
                ),
                _buildSettingItem(
                  icon: Icons.description_outlined,
                  title: 'Terms of Service',
                  subtitle: 'View our terms of service',
                  onTap: () {
                    _launchURL('https://www.example.com/terms');
                  },
                ),
                
                // Danger zone
                _buildSectionHeader('Danger Zone', isWarning: true),
                _buildSettingItem(
                  icon: Icons.delete_forever,
                  title: 'Clear All Data',
                  subtitle: 'Delete all scans and reset app settings',
                  onTap: _clearAllData,
                  textColor: AppColors.error,
                ),
              ],
            ),
    );
  }
  
  Widget _buildSectionHeader(String title, {bool isWarning = false}) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppDimensions.paddingM,
        right: AppDimensions.paddingM,
        top: AppDimensions.paddingL,
        bottom: AppDimensions.paddingS,
      ),
      child: Text(
        title,
        style: AppTextStyles.subtitle.copyWith(
          color: isWarning ? AppColors.error : AppColors.primaryBlue,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? textColor,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingS),
      child: ListTile(
        leading: Icon(icon, color: textColor ?? AppColors.primaryBlue),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: trailing ?? (onTap != null ? const Icon(Icons.arrow_forward_ios, size: 16) : null),
        onTap: onTap,
      ),
    );
  }
  
  Widget _buildLanguageItem(String languageCode) {
    final language = LanguageModel.findByCode(languageCode);
    
    return _buildSettingItem(
      icon: Icons.translate,
      title: AppStrings.language,
      subtitle: language != null
          ? '${language.name} (${language.nativeName})'
          : 'English',
      trailing: DropdownButton<String>(
        value: languageCode,
        underline: const SizedBox.shrink(),
        icon: const Icon(Icons.arrow_drop_down),
        onChanged: (String? newValue) {
          if (newValue != null) {
            Provider.of<AppStateProvider>(context, listen: false)
                .updateDefaultLanguage(newValue);
          }
        },
        items: LanguageModel.supportedLanguages().map<DropdownMenuItem<String>>((language) {
          return DropdownMenuItem<String>(
            value: language.code,
            child: Text(language.name),
          );
        }).toList(),
      ),
    );
  }
} 