import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;

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
              transitionBuilder: (Widget child, Animation<double> animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: Icon(
                _prescription.isImportant ? Icons.star : Icons.star_border,
                key: ValueKey<bool>(_prescription.isImportant),
                color: _prescription.isImportant ? AppColors.warning : null,
              ),
            ),
            onPressed: _toggleImportant,
            tooltip: AppStrings.markAsImportant,
          ),
          
          // Share button
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareSummary,
            tooltip: AppStrings.share,
          ),
        ],
      ),
      body: Column(
        children: [
          // Image preview with gradient overlay
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Image
                SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: _buildImagePreview(),
                ),
                // Gradient overlay
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.5),
                        ],
                      ),
                    ),
                  ),
                ),
                // Date text
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Text(
                    _formatDate(_prescription.dateScanned),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          offset: Offset(1, 1),
                          blurRadius: 2,
                          color: Color.fromARGB(150, 0, 0, 0),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Language selector
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.translate,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(width: AppDimensions.paddingM),
                const Text(
                  AppStrings.translate,
                  style: AppTextStyles.subtitle,
                ),
                const SizedBox(width: AppDimensions.paddingM),
                Expanded(
                  child: _buildLanguageDropdown(),
                ),
              ],
            ),
          ),
          
          // Error message (if any)
          if (_errorMessage != null)
            Container(
              margin: const EdgeInsets.all(AppDimensions.paddingM),
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                border: Border.all(color: AppColors.error.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: AppTextStyles.body.copyWith(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),
          
          // Content
          Expanded(
            child: _isTranslating
                ? _buildLoadingIndicator(_processingStatus.isNotEmpty ? _processingStatus : 'Translating...')
                : FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildContent(summary),
                  ),
          ),
          
          // Action buttons
          _buildActionButtons(),
        ],
      ),
    );
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
  
  Widget _buildImagePreview() {
    // On web, we can't use File, so we just show a placeholder
    if (kIsWeb) {
      return Container(
        color: AppColors.cardBackground,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image,
                size: 64,
                color: AppColors.primaryBlue.withOpacity(0.7),
              ),
              const SizedBox(height: 8),
              const Text(
                'Prescription Image',
                style: AppTextStyles.subtitle,
              ),
            ],
          ),
        ),
      );
    } else {
      // On mobile platforms, use File
      return Image.file(
        File(_prescription.imagePath),
        fit: BoxFit.cover,
      );
    }
  }
  
  Widget _buildLanguageDropdown() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider),
        color: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedLanguage,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.primaryBlue),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          borderRadius: BorderRadius.circular(8),
          items: LanguageModel.supportedLanguages().map((language) {
            return DropdownMenuItem<String>(
              value: language.code,
              child: Row(
                children: [
                  Text(language.name),
                  const SizedBox(width: 4),
                  Text(
                    '(${language.nativeName})',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              _translateSummary(value);
            }
          },
        ),
      ),
    );
  }
  
  Widget _buildLoadingIndicator(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LoadingAnimationWidget.staggeredDotsWave(
            color: AppColors.primaryBlue,
            size: 50,
          ),
          const SizedBox(height: AppDimensions.paddingM),
          Text(
            message,
            style: AppTextStyles.subtitle,
          ),
        ],
      ),
    );
  }
  
  Widget _buildContent(String summary) {
    // If a medicine is selected, show its details
    if (_selectedMedicine != null) {
      return _buildMedicineDetails(_selectedMedicine!);
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Summary Card
          _buildElevatedCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.description, color: AppColors.primaryBlue),
                    ),
                    const SizedBox(width: AppDimensions.paddingM),
                    const Text(
                      'Prescription Details',
                      style: AppTextStyles.subtitle,
                    ),
                  ],
                ),
                const Divider(height: 24),
                Text(
                  summary,
                  style: AppTextStyles.body,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppDimensions.paddingL),
          
          // Medicines Card
          if (_prescription.medicines.isNotEmpty)
            _buildElevatedCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.medication, color: AppColors.primaryBlue),
                      ),
                      const SizedBox(width: AppDimensions.paddingM),
                      const Text(
                        'Medicines',
                        style: AppTextStyles.subtitle,
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_prescription.medicines.length} items',
                          style: TextStyle(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _isLoadingMedicineDetails
                      ? _buildLoadingIndicator('Loading medicine details...')
                      : _buildMedicinesList(_prescription.medicines),
                ],
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildElevatedCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: AppColors.primaryBlue,
                width: 4,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingL),
            child: child,
          ),
        ),
      ),
    );
  }
  
  Widget _buildMedicinesList(List<MedicineModel> medicines) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: medicines.length,
      separatorBuilder: (context, index) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Divider(height: 1),
      ),
      itemBuilder: (context, index) {
        final medicine = medicines[index];
        return _buildMedicineListItem(medicine, index);
      },
    );
  }
  
  Widget _buildMedicineListItem(MedicineModel medicine, int index) {
    final colors = [
      AppColors.primaryBlue,
      AppColors.primaryPurple,
      AppColors.success,
      AppColors.warning,
      AppColors.info,
    ];
    
    final color = colors[index % colors.length];
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _getMedicineDetails(medicine.name),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Medicine icon with background
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(
                    Icons.medication_outlined,
                    color: color,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Medicine info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medicine.getTranslatedField('name', _selectedLanguage),
                      style: AppTextStyles.bodyBold,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      medicine.getTranslatedField('usage', _selectedLanguage),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Arrow icon
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: color,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildMedicineDetails(MedicineModel medicine) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Back button
          TextButton.icon(
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back to summary'),
            onPressed: () {
              setState(() {
                _selectedMedicine = null;
              });
              
              // Reset and run the animation again
              _animationController.reset();
              _animationController.forward();
            },
            style: TextButton.styleFrom(
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.zero,
            ),
          ),
          
          const SizedBox(height: AppDimensions.paddingM),
          
          // Medicine details card
          _buildElevatedCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Medicine name with pill icon
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.medication,
                        color: AppColors.primaryBlue,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            medicine.getTranslatedField('name', _selectedLanguage),
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Detailed Information',
                            style: TextStyle(
                              color: AppColors.textLight,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const Divider(height: 32),
                
                // Usage
                _buildMedicineDetailSection(
                  'Usage',
                  medicine.getTranslatedField('usage', _selectedLanguage),
                  Icons.healing,
                  AppColors.success,
                ),
                
                // Mechanism
                const SizedBox(height: AppDimensions.paddingL),
                _buildMedicineDetailSection(
                  'How it works',
                  medicine.getTranslatedField('mechanism', _selectedLanguage),
                  Icons.biotech,
                  AppColors.info,
                ),
                
                // Side Effects
                const SizedBox(height: AppDimensions.paddingL),
                _buildMedicineDetailSection(
                  'Side Effects',
                  medicine.getTranslatedField('sideEffects', _selectedLanguage),
                  Icons.warning_amber,
                  AppColors.warning,
                ),
                
                // Risks
                const SizedBox(height: AppDimensions.paddingL),
                _buildMedicineDetailSection(
                  'Risks',
                  medicine.getTranslatedField('risks', _selectedLanguage),
                  Icons.dangerous,
                  AppColors.error,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMedicineDetailSection(String title, String content, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: AppDimensions.paddingS),
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
          const SizedBox(height: 12),
          Text(
            content,
            style: AppTextStyles.body,
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _copySummaryToClipboard,
              icon: const Icon(Icons.copy, size: 18),
              label: const Text(AppStrings.copy),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.paddingM),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _shareSummary,
              icon: const Icon(Icons.share, size: 18),
              label: const Text(AppStrings.share),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 