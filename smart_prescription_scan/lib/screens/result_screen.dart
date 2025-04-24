import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../constants/app_constants.dart';
import '../main.dart';
import '../models/language_model.dart';
import '../models/prescription_model.dart';
import '../services/gemini_service.dart';
import '../services/storage_service.dart';

class ResultScreen extends StatefulWidget {
  final PrescriptionModel prescription;
  
  const ResultScreen({super.key, required this.prescription});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final StorageService _storageService = StorageService();
  final GeminiService _geminiService = GeminiService();
  
  late PrescriptionModel _prescription;
  bool _isTranslating = false;
  String _selectedLanguage = 'en'; // Default to English
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _prescription = widget.prescription;
    
    // Set default language from user preferences
    final userPreferences = Provider.of<AppStateProvider>(context, listen: false).userPreferences;
    _selectedLanguage = userPreferences.defaultLanguage;
    
    // If the default language is not English and we don't have a translation yet,
    // translate automatically
    if (_selectedLanguage != 'en' && !_prescription.translations.containsKey(_selectedLanguage)) {
      _translateSummary(_selectedLanguage);
    }
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
      
      final updatedPrescription = _prescription.copyWith(
        translations: updatedTranslations,
      );
      
      // Save the updated prescription
      await _storageService.savePrescription(updatedPrescription);
      
      // Update the local state
      setState(() {
        _prescription = updatedPrescription;
        _selectedLanguage = languageCode;
        _isTranslating = false;
      });
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
      const SnackBar(content: Text('Summary copied to clipboard')),
    );
  }
  
  void _shareSummary() {
    final summary = _prescription.translations[_selectedLanguage] ?? _prescription.summary;
    Share.share(summary, subject: 'Prescription Summary');
  }

  @override
  Widget build(BuildContext context) {
    final summary = _prescription.translations[_selectedLanguage] ?? _prescription.summary;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.summary),
        actions: [
          // Star/Unstar button
          IconButton(
            icon: Icon(
              _prescription.isImportant ? Icons.star : Icons.star_border,
              color: _prescription.isImportant ? AppColors.warning : null,
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
          // Image preview
          SizedBox(
            height: 200,
            width: double.infinity,
            child: _buildImagePreview(),
          ),
          
          // Divider
          const Divider(),
          
          // Language selector
          Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            child: Row(
              children: [
                const Icon(
                  Icons.translate,
                  color: AppColors.primaryBlue,
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
            Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              child: Text(
                _errorMessage!,
                style: AppTextStyles.body.copyWith(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
            ),
          
          // Summary content
          Expanded(
            child: _isTranslating
                ? _buildLoadingIndicator()
                : _buildSummaryContent(summary),
          ),
          
          // Action buttons
          _buildActionButtons(),
        ],
      ),
    );
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
        fit: BoxFit.contain,
      );
    }
  }
  
  Widget _buildLanguageDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedLanguage,
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingM,
          vertical: AppDimensions.paddingS,
        ),
      ),
      items: LanguageModel.supportedLanguages().map((language) {
        return DropdownMenuItem<String>(
          value: language.code,
          child: Text(language.name),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          _translateSummary(value);
        }
      },
    );
  }
  
  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LoadingAnimationWidget.staggeredDotsWave(
            color: AppColors.primaryBlue,
            size: 50,
          ),
          const SizedBox(height: AppDimensions.paddingM),
          const Text(
            AppStrings.translating,
            style: AppTextStyles.subtitle,
          ),
        ],
      ),
    );
  }
  
  Widget _buildSummaryContent(String summary) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          child: Text(
            summary,
            style: AppTextStyles.body,
          ),
        ),
      ),
    );
  }
  
  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _copySummaryToClipboard,
              icon: const Icon(Icons.copy),
              label: const Text(AppStrings.copy),
            ),
          ),
          const SizedBox(width: AppDimensions.paddingM),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _shareSummary,
              icon: const Icon(Icons.share),
              label: const Text(AppStrings.share),
            ),
          ),
        ],
      ),
    );
  }
} 