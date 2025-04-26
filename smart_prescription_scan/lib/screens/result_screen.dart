import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_constants.dart';
import '../main.dart';
import '../models/language_model.dart';
import '../models/prescription_model.dart';
import '../models/medicine_model.dart';
import '../services/gemini_service.dart';
import '../services/storage_service.dart';

class ResultScreen extends StatefulWidget {
  final PrescriptionModel prescription;
  
  const ResultScreen({super.key, required this.prescription});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> with SingleTickerProviderStateMixin {
  final StorageService _storageService = StorageService();
  final GeminiService _geminiService = GeminiService();
  
  late PrescriptionModel _prescription;
  bool _isTranslating = false;
  bool _isLoadingMedicineDetails = false;
  String _selectedLanguage = 'en'; // Default to English
  String? _errorMessage;
  String _processingStatus = '';
  MedicineModel? _selectedMedicine;
  
  // Animation controller for card transitions
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    _prescription = widget.prescription;
    
    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    _animationController.forward();
    
    // Set default language from user preferences
    final userPreferences = Provider.of<AppStateProvider>(context, listen: false).userPreferences;
    _selectedLanguage = userPreferences.defaultLanguage;
    
    // If the default language is not English and we don't have a translation yet,
    // translate automatically
    if (_selectedLanguage != 'en' && !_prescription.translations.containsKey(_selectedLanguage)) {
      _translateSummary(_selectedLanguage);
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  Future<void> _translateSummary(String languageCode) async {
    // If we already have a translation for this language, no need to fetch it again
    if (_prescription.translations.containsKey(languageCode)) {
      setState(() {
        _selectedLanguage = languageCode;
      });
      return;
    }
    
    setState(() {
      _isTranslating = true;
      _errorMessage = null;
    });
    
    try {
      // Get language name for translation
      final language = LanguageModel.findByCode(languageCode);
      if (language == null) {
        throw Exception('Language not supported');
      }
      
      // Get the English summary as source for translation
      final englishSummary = _prescription.translations['en'] ?? _prescription.summary;
      
      // Translate the summary
      final translatedSummary = await _geminiService.translateSummary(
        englishSummary,
        language.name,
      );
      
      // Update the prescription with the new translation
      final updatedTranslations = Map<String, String>.from(_prescription.translations);
      updatedTranslations[languageCode] = translatedSummary;
      
      // Also translate all medicines if any exist
      List<MedicineModel> translatedMedicines = [];
      
      if (_prescription.medicines.isNotEmpty) {
        // Set status for medicine translation
        setState(() {
          _processingStatus = 'Translating medicines...';
        });
        
        // Translate each medicine
        for (final medicine in _prescription.medicines) {
          try {
            final translatedMedicine = await _geminiService.translateMedicine(
              medicine, 
              languageCode, 
              language.name
            );
            translatedMedicines.add(translatedMedicine);
          } catch (e) {
            // If translation fails for a specific medicine, keep the original
            translatedMedicines.add(medicine);
            if (kDebugMode) {
              print('Failed to translate medicine ${medicine.name}: $e');
            }
          }
        }
      } else {
        translatedMedicines = _prescription.medicines;
      }
      
      final updatedPrescription = _prescription.copyWith(
        translations: updatedTranslations,
        medicines: translatedMedicines,
      );
      
      // Save the updated prescription
      await _storageService.savePrescription(updatedPrescription);
      
      // Update the local state
      setState(() {
        _prescription = updatedPrescription;
        _selectedLanguage = languageCode;
        _isTranslating = false;
      });
      
      // Animate the new content
      _animationController.reset();
      _animationController.forward();
      
    } catch (e) {
      setState(() {
        _isTranslating = false;
        _errorMessage = 'Failed to translate: ${e.toString()}';
      });
    }
  }
  
  void _toggleImportant() async {
    final updatedPrescription = _prescription.copyWith(
      isImportant: !_prescription.isImportant,
    );
    
    // Save the updated prescription
    await _storageService.savePrescription(updatedPrescription);
    
    // Update the local state
    setState(() {
      _prescription = updatedPrescription;
    });
  }
  
  void _copySummaryToClipboard() {
    final summary = _prescription.translations[_selectedLanguage] ?? _prescription.summary;
    Clipboard.setData(ClipboardData(text: summary));
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            const Text('Summary copied to clipboard'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        backgroundColor: AppColors.success,
      ),
    );
  }
  
  void _shareSummary() {
    final summary = _prescription.translations[_selectedLanguage] ?? _prescription.summary;
    Share.share(summary, subject: 'Prescription Summary');
  }
  
  Future<void> _getMedicineDetails(String medicineName) async {
    setState(() {
      _isLoadingMedicineDetails = true;
      _errorMessage = null;
    });
    
    try {
      final medicineDetails = await _geminiService.getMedicineDetails(medicineName);
      
      // Start animation
      _animationController.reset();
      
      // Update the state with the selected medicine
      setState(() {
        _selectedMedicine = medicineDetails;
        _isLoadingMedicineDetails = false;
      });
      
      // Run the animation
      _animationController.forward();
      
    } catch (e) {
      setState(() {
        _isLoadingMedicineDetails = false;
        _errorMessage = 'Failed to get medicine details: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = _prescription.translations[_selectedLanguage] ?? _prescription.summary;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.summary),
        elevation: 0,
        actions: [
          // Star/Unstar button
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                _prescription.isImportant ? Icons.star : Icons.star_border,
                key: ValueKey<bool>(_prescription.isImportant),
                color: _prescription.isImportant ? AppColors.warning : null,
              ),
            ),
            onPressed: _toggleImportant,
            tooltip: _prescription.isImportant ? 'Remove from important' : 'Mark as important',
          ),
          
          // Share button
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareSummary,
            tooltip: 'Share summary',
          ),
          
          // Language selector
          _buildLanguageSelector(),
        ],
      ),
      body: SafeArea(
        child: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              // Language indicator while translating
              if (_isTranslating)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: AppDimensions.paddingL),
                  color: AppColors.info.withOpacity(0.1),
                  child: Row(
                    children: [
                      SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.info),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _processingStatus.isNotEmpty 
                              ? _processingStatus 
                              : 'Translating to ${LanguageModel.findByCode(_selectedLanguage)?.name ?? _selectedLanguage}...',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.info,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Error message if any
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(AppDimensions.paddingM),
                  margin: const EdgeInsets.all(AppDimensions.paddingM),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: AppColors.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: AppColors.error,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () {
                          setState(() {
                            _errorMessage = null;
                          });
                        },
                        color: AppColors.error,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              
              // Tab Bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TabBar(
                  indicatorColor: AppColors.primaryBlue,
                  labelColor: AppColors.primaryBlue,
                  unselectedLabelColor: AppColors.textSecondary,
                  tabs: [
                    Tab(
                      text: 'Summary',
                      icon: Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Icon(
                          Icons.description,
                          size: 20,
                          color: Theme.of(context).tabBarTheme.labelColor,
                        ),
                      ),
                    ),
                    Tab(
                      text: 'Medicines',
                      icon: Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Icon(
                          Icons.medication,
                          size: 20,
                          color: Theme.of(context).tabBarTheme.labelColor,
                        ),
                      ),
                    ),
                  ],
                  onTap: (_) {
                    // Reset selected medicine when switching tabs
                    if (_selectedMedicine != null) {
                      setState(() {
                        _selectedMedicine = null;
                      });
                    }
                  },
                ),
              ),
              
              // Tab content
              Expanded(
                child: TabBarView(
                  children: [
                    // Summary tab
                    _buildSummaryTab(summary),
                    
                    // Medicines tab
                    _selectedMedicine != null
                        ? SingleChildScrollView(
                            padding: const EdgeInsets.all(AppDimensions.paddingM),
                            child: _buildMedicineDetailsCard(_selectedMedicine!),
                          )
                        : _buildMedicineList(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _selectedMedicine != null ? () => _showMedicineDetails(_selectedMedicine!) : null,
        child: const Icon(Icons.info),
      ),
    );
  }
  
  Widget _buildLanguageSelector() {
    final languages = LanguageModel.supportedLanguages();
    
    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: PopupMenuButton<String>(
          tooltip: 'Select language',
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          ),
          offset: const Offset(0, 50),
          onSelected: (value) {
            if (value != _selectedLanguage) {
              _translateSummary(value);
            }
          },
          itemBuilder: (BuildContext context) {
            return languages.map((language) {
              final isSelected = language.code == _selectedLanguage;
              return PopupMenuItem<String>(
                value: language.code,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryBlue.withOpacity(0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            getLanguageFlag(language.code),
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            language.name,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? AppColors.primaryBlue : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle,
                          color: AppColors.primaryBlue,
                          size: 16,
                        ),
                    ],
                  ),
                ),
              );
            }).toList();
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                getLanguageFlag(_selectedLanguage),
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_drop_down),
            ],
          ),
        ),
      ),
    );
  }
  
  String getLanguageFlag(String languageCode) {
    final Map<String, String> flags = {
      'en': '🇺🇸',
      'es': '🇪🇸',
      'fr': '🇫🇷',
      'de': '🇩🇪',
      'it': '🇮🇹',
      'pt': '🇵🇹',
      'ru': '🇷🇺',
      'zh': '🇨🇳',
      'ja': '🇯🇵',
      'hi': '🇮🇳',
      'ar': '🇸🇦',
      'gu': '🇮🇳',
    };
    
    return flags[languageCode] ?? '🌐';
  }
  
  Widget _buildSummaryTab(String summary) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Prescription image
          if (_prescription.imagePath.isNotEmpty && !kIsWeb)
            Hero(
              tag: 'prescription_image_${_prescription.id}',
              child: Container(
                width: double.infinity,
                height: 200,
                margin: const EdgeInsets.only(bottom: AppDimensions.paddingL),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  child: Image.file(
                    File(_prescription.imagePath),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          
          // Date
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  _formatDate(_prescription.dateScanned),
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppDimensions.paddingM),
          
          // Summary card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Prescription Summary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          // Copy button
                          IconButton(
                            icon: const Icon(Icons.copy, size: 18),
                            onPressed: _copySummaryToClipboard,
                            tooltip: 'Copy to clipboard',
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(8),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  const Divider(height: 24),
                  
                  // Summary text
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      summary,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: AppDimensions.paddingM),
          
          // Medicine count if any
          if (_prescription.medicines.isNotEmpty)
            GestureDetector(
              onTap: () {
                // Switch to medicines tab
                DefaultTabController.of(context).animateTo(1);
              },
              child: Container(
                padding: const EdgeInsets.all(AppDimensions.paddingM),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.medication,
                        color: AppColors.primaryBlue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Medicines (${_prescription.medicines.length})',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap to view detailed information',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward,
                      color: AppColors.primaryBlue,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    // Format: "Jan 12, 2023 at 14:30"
    final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final month = monthNames[date.month - 1];
    final day = date.day;
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    
    return '$month $day, $year at $hour:$minute';
  }
  
  Widget _buildMedicineDetailsCard(MedicineModel medicine) {
    final isLoading = _isLoadingMedicineDetails && _selectedMedicine == null;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            AppColors.primaryBlue.withOpacity(0.05),
          ],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: isLoading
              ? _buildLoadingIndicator()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header with medicine name
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.paddingL,
                        vertical: AppDimensions.paddingM,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.1),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(AppDimensions.radiusL),
                          topRight: Radius.circular(AppDimensions.radiusL),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.medication_rounded,
                            color: AppColors.primaryBlue,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              medicine.getTranslatedField('name', _selectedLanguage),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () {
                              setState(() {
                                _selectedMedicine = null;
                              });
                            },
                            color: AppColors.textSecondary,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                    
                    // Medicine details
                    Padding(
                      padding: const EdgeInsets.all(AppDimensions.paddingL),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildMedicineDetailSection(
                            title: 'Usage',
                            content: medicine.getTranslatedField('usage', _selectedLanguage),
                            icon: Icons.local_hospital_outlined,
                            iconColor: AppColors.primaryBlue,
                          ),
                          
                          _buildMedicineDetailSection(
                            title: 'How it Works',
                            content: medicine.getTranslatedField('mechanism', _selectedLanguage),
                            icon: Icons.biotech_outlined,
                            iconColor: AppColors.primaryPurple,
                          ),
                          
                          _buildMedicineDetailSection(
                            title: 'Side Effects',
                            content: medicine.getTranslatedField('sideEffects', _selectedLanguage),
                            icon: Icons.warning_amber_outlined,
                            iconColor: AppColors.warning,
                          ),
                          
                          _buildMedicineDetailSection(
                            title: 'Risks',
                            content: medicine.getTranslatedField('risks', _selectedLanguage),
                            icon: Icons.error_outline,
                            iconColor: AppColors.error,
                            isLast: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
  
  Widget _buildMedicineDetailSection({
    required String title,
    required String content,
    required IconData icon,
    required Color iconColor,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMedicineList() {
    if (_prescription.medicines.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.medication_outlined,
                size: 60,
                color: AppColors.primaryBlue.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No medicines found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This prescription doesn\'t contain any medicine details',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      itemCount: _prescription.medicines.length,
      itemBuilder: (context, index) {
        final medicine = _prescription.medicines[index];
        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            final delay = index * 0.1;
            final animationValue = max(
              0.0,
              min(1.0, (_animationController.value - delay) / (1.0 - delay)),
            );
            
            return FadeTransition(
              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(
                  parent: _animationController,
                  curve: Interval(
                    delay,
                    min(1.0, delay + 0.5),
                    curve: Curves.easeOut,
                  ),
                ),
              ),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.3, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: _animationController,
                    curve: Interval(
                      delay,
                      min(1.0, delay + 0.5),
                      curve: Curves.easeOut,
                    ),
                  ),
                ),
                child: _buildMedicineCard(medicine, animationValue),
              ),
            );
          },
        );
      },
    );
  }
  
  Widget _buildMedicineCard(MedicineModel medicine, double animationValue) {
    final hasDetails = medicine.usage.isNotEmpty || 
                       medicine.mechanism.isNotEmpty || 
                       medicine.sideEffects.isNotEmpty || 
                       medicine.risks.isNotEmpty;
    
    final cardHeight = 90.0 + lerpDouble(0, 20, animationValue)!;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.paddingM),
      child: InkWell(
        onTap: () {
          _showMedicineDetails(medicine);
        },
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: cardHeight,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: lerpDouble(5, 10, animationValue)!,
                offset: Offset(0, lerpDouble(2, 4, animationValue)!),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Medicine card content
              Row(
                children: [
                  // Medicine icon with colored background
                  Container(
                    width: 90,
                    decoration: BoxDecoration(
                      color: _getMedicineColor(medicine).withOpacity(0.1),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(AppDimensions.radiusM),
                        bottomLeft: Radius.circular(AppDimensions.radiusM),
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        _getMedicineIcon(medicine),
                        size: 36,
                        color: _getMedicineColor(medicine),
                      ),
                    ),
                  ),
                  
                  // Medicine details
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppDimensions.paddingM,
                        horizontal: AppDimensions.paddingL,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Medicine name
                          Text(
                            medicine.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          
                          if (medicine.dosage.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              medicine.dosage,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          
                          const SizedBox(height: 8),
                          
                          // Detail indicators
                          if (hasDetails)
                            Row(
                              children: [
                                if (medicine.usage.isNotEmpty)
                                  _buildDetailIndicator(
                                    Icons.schedule,
                                    AppColors.success,
                                  ),
                                if (medicine.mechanism.isNotEmpty)
                                  _buildDetailIndicator(
                                    Icons.insights,
                                    AppColors.info,
                                  ),
                                if (medicine.sideEffects.isNotEmpty)
                                  _buildDetailIndicator(
                                    Icons.warning_amber,
                                    AppColors.warning,
                                  ),
                                if (medicine.risks.isNotEmpty)
                                  _buildDetailIndicator(
                                    Icons.dangerous,
                                    AppColors.error,
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Arrow indicator
                  Padding(
                    padding: const EdgeInsets.only(right: AppDimensions.paddingM),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: AppColors.textSecondary.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
              
              // Bottom divider
              Positioned(
                bottom: 0,
                left: 90,
                right: 0,
                child: Container(
                  height: 1,
                  color: AppColors.divider.withOpacity(0.3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildDetailIndicator(IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          icon,
          size: 12,
          color: color,
        ),
      ),
    );
  }
  
  Color _getMedicineColor(MedicineModel medicine) {
    // Return color based on medicine type or category
    if (medicine.category.toLowerCase().contains('antibiotic')) {
      return AppColors.info;
    } else if (medicine.category.toLowerCase().contains('painkiller') ||
               medicine.category.toLowerCase().contains('analgesic')) {
      return AppColors.warning;
    } else if (medicine.category.toLowerCase().contains('vitamin') ||
               medicine.category.toLowerCase().contains('supplement')) {
      return AppColors.success;
    } else if (medicine.sideEffects.isNotEmpty && medicine.risks.isNotEmpty) {
      return AppColors.error;
    } else {
      return AppColors.primaryBlue;
    }
  }
  
  IconData _getMedicineIcon(MedicineModel medicine) {
    // Return icon based on medicine type or category
    if (medicine.category.toLowerCase().contains('tablet') ||
        medicine.category.toLowerCase().contains('pill')) {
      return Icons.medication;
    } else if (medicine.category.toLowerCase().contains('syrup') ||
               medicine.category.toLowerCase().contains('liquid')) {
      return Icons.local_drink;
    } else if (medicine.category.toLowerCase().contains('injection') ||
               medicine.category.toLowerCase().contains('syringe')) {
      return Icons.vaccines;
    } else if (medicine.category.toLowerCase().contains('cream') ||
               medicine.category.toLowerCase().contains('ointment') ||
               medicine.category.toLowerCase().contains('topical')) {
      return Icons.sanitizer;
    } else if (medicine.category.toLowerCase().contains('inhaler') ||
               medicine.category.toLowerCase().contains('respiratory')) {
      return Icons.air;
    } else {
      return Icons.medication_outlined;
    }
  }
  
  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LoadingAnimationWidget.staggeredDotsWave(
            color: AppColors.primaryBlue,
            size: 40,
          ),
          const SizedBox(height: AppDimensions.paddingM),
          Text(
            _processingStatus.isNotEmpty ? _processingStatus : 'Loading medicine details...',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _showMedicineDetails(MedicineModel medicine) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusXL)),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  height: 5,
                  width: 40,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  ),
                ),
                
                // Header
                Padding(
                  padding: const EdgeInsets.all(AppDimensions.paddingL),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getMedicineColor(medicine).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                        ),
                        child: Icon(
                          _getMedicineIcon(medicine),
                          size: 28,
                          color: _getMedicineColor(medicine),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              medicine.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (medicine.dosage.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                medicine.dosage,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
                
                const Divider(),
                
                // Content
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(AppDimensions.paddingL),
                    children: [
                      // Category
                      if (medicine.category.isNotEmpty) ...[
                        _buildDetailSection(
                          'Category',
                          medicine.category,
                          Icons.category,
                          AppColors.primaryBlue,
                        ),
                        const SizedBox(height: 24),
                      ],
                      
                      // Usage instructions
                      if (medicine.usage.isNotEmpty) ...[
                        _buildDetailSection(
                          'Usage Instructions',
                          medicine.usage,
                          Icons.schedule,
                          AppColors.success,
                        ),
                        const SizedBox(height: 24),
                      ],
                      
                      // Mechanism of action
                      if (medicine.mechanism.isNotEmpty) ...[
                        _buildDetailSection(
                          'How it Works',
                          medicine.mechanism,
                          Icons.insights,
                          AppColors.info,
                        ),
                        const SizedBox(height: 24),
                      ],
                      
                      // Side effects
                      if (medicine.sideEffects.isNotEmpty) ...[
                        _buildDetailSection(
                          'Possible Side Effects',
                          medicine.sideEffects,
                          Icons.warning_amber,
                          AppColors.warning,
                        ),
                        const SizedBox(height: 24),
                      ],
                      
                      // Risks and warnings
                      if (medicine.risks.isNotEmpty) ...[
                        _buildDetailSection(
                          'Risks & Warnings',
                          medicine.risks,
                          Icons.dangerous,
                          AppColors.error,
                        ),
                        const SizedBox(height: 24),
                      ],
                      
                      // Interactions
                      if (medicine.interactions.isNotEmpty) ...[
                        _buildDetailSection(
                          'Drug Interactions',
                          medicine.interactions,
                          Icons.sync_problem,
                          Colors.purple,
                        ),
                        const SizedBox(height: 24),
                      ],
                    ],
                  ),
                ),
                
                // Actions
                Padding(
                  padding: const EdgeInsets.all(AppDimensions.paddingL),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Copy medicine details
                            final text = '''
${medicine.name}
${medicine.dosage}
${medicine.category.isNotEmpty ? '\nCategory: ${medicine.category}' : ''}
${medicine.usage.isNotEmpty ? '\nUsage: ${medicine.usage}' : ''}
${medicine.mechanism.isNotEmpty ? '\nHow it works: ${medicine.mechanism}' : ''}
${medicine.sideEffects.isNotEmpty ? '\nSide effects: ${medicine.sideEffects}' : ''}
${medicine.risks.isNotEmpty ? '\nRisks & warnings: ${medicine.risks}' : ''}
${medicine.interactions.isNotEmpty ? '\nInteractions: ${medicine.interactions}' : ''}
''';
                            Clipboard.setData(ClipboardData(text: text));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Medicine details copied to clipboard'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy),
                          label: const Text('Copy Details'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.cardBackground,
                            foregroundColor: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Search medicine online
                            final query = Uri.encodeComponent('${medicine.name} medication information');
                            launchUrl(Uri.parse('https://www.google.com/search?q=$query'));
                          },
                          icon: const Icon(Icons.search),
                          label: const Text('Learn More'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildDetailSection(String title, String content, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Text(
            content,
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
} 