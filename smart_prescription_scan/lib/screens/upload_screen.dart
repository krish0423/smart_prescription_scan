import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../constants/app_constants.dart';
import '../main.dart';
import '../models/prescription_model.dart';
import '../services/gemini_service.dart';
import '../services/storage_service.dart';
import 'result_screen.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  final GeminiService _geminiService = GeminiService();
  final StorageService _storageService = StorageService();
  
  File? _selectedImage;
  Uint8List? _webImage;
  bool _isProcessing = false;
  String _processingStatus = '';
  String? _errorMessage;
  
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
      );
      
      if (pickedFile != null) {
        if (kIsWeb) {
          // For web platform
          final bytes = await pickedFile.readAsBytes();
          setState(() {
            _webImage = bytes;
            _selectedImage = null;
            _errorMessage = null;
          });
        } else {
          // For mobile platforms
          setState(() {
            _selectedImage = File(pickedFile.path);
            _webImage = null;
            _errorMessage = null;
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to pick image. Please try again.';
      });
    }
  }
  
  Future<void> _processImage() async {
    if (_selectedImage == null && _webImage == null) {
      setState(() {
        _errorMessage = 'Please select an image first.';
      });
      return;
    }
    
    setState(() {
      _isProcessing = true;
      _processingStatus = AppStrings.uploading;
      _errorMessage = null;
    });
    
    try {
      // Save the image to app's documents directory
      setState(() {
        _processingStatus = AppStrings.uploading;
      });
      
      String savedImagePath;
      if (kIsWeb) {
        // For web platform, we can't save to local storage as usual
        // Just use a placeholder path or handle it differently
        savedImagePath = 'web_image_${DateTime.now().millisecondsSinceEpoch}';
      } else {
        savedImagePath = await _storageService.saveImage(_selectedImage!);
      }
      
      // Generate summary using Gemini API
      setState(() {
        _processingStatus = AppStrings.summarizing;
      });
      
      String summary;
      if (kIsWeb && _webImage != null) {
        // Create a temp file from bytes for web
        summary = await _geminiService.generatePrescriptionSummaryFromBytes(_webImage!);
      } else if (_selectedImage != null) {
        summary = await _geminiService.generatePrescriptionSummary(_selectedImage!);
      } else {
        throw Exception('No valid image selected');
      }
      
      // Extract medicines from the summary
      setState(() {
        _processingStatus = 'Extracting medicines...';
      });
      
      var medicines = await _geminiService.extractMedicinesFromSummary(summary);
      
      // Create a new prescription model
      final String id = _storageService.generateUniqueId();
      final PrescriptionModel prescription = PrescriptionModel(
        id: id,
        imagePath: savedImagePath,
        summary: summary,
        translations: {'en': summary}, // Store original summary as English translation
        dateScanned: DateTime.now(),
        medicines: medicines,
      );
      
      // Save the prescription to local storage
      await _storageService.savePrescription(prescription);
      
      // Navigate to result screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ResultScreen(prescription: prescription),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = e.toString();
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final userPreferences = Provider.of<AppStateProvider>(context).userPreferences;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.uploadNewPrescription),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Image selection area
            Expanded(
              child: hasSelectedImage()
                  ? _buildSelectedImagePreview()
                  : _buildImageSelectionPlaceholder(),
            ),
            
            // Error message (if any)
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingM),
                child: Text(
                  _errorMessage!,
                  style: AppTextStyles.body.copyWith(color: AppColors.error),
                  textAlign: TextAlign.center,
                ),
              ),
            
            // Action buttons
            const SizedBox(height: AppDimensions.paddingL),
            _isProcessing
                ? _buildProcessingIndicator()
                : _buildActionButtons(),
          ],
        ),
      ),
    );
  }
  
  bool hasSelectedImage() {
    return _selectedImage != null || _webImage != null;
  }
  
  Widget _buildImageSelectionPlaceholder() {
    return GestureDetector(
      onTap: _showImageSourceSelection,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          border: Border.all(
            color: AppColors.divider,
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate,
              size: 64,
              color: AppColors.primaryBlue.withOpacity(0.7),
            ),
            const SizedBox(height: AppDimensions.paddingL),
            const Text(
              AppStrings.selectImage,
              style: AppTextStyles.subtitle,
            ),
            const SizedBox(height: AppDimensions.paddingM),
            ElevatedButton(
              onPressed: _showImageSourceSelection,
              child: const Text(AppStrings.selectImage),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSelectedImagePreview() {
    return Column(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            child: _buildImageWidget(),
          ),
        ),
        const SizedBox(height: AppDimensions.paddingM),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            OutlinedButton.icon(
              onPressed: _showImageSourceSelection,
              icon: const Icon(Icons.refresh),
              label: const Text('Change Image'),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildImageWidget() {
    if (kIsWeb && _webImage != null) {
      return Image.memory(
        _webImage!,
        fit: BoxFit.contain,
      );
    } else if (_selectedImage != null) {
      return Image.file(
        _selectedImage!,
        fit: BoxFit.contain,
      );
    } else {
      return const Icon(
        Icons.image_not_supported,
        size: 100,
        color: AppColors.divider,
      );
    }
  }
  
  Widget _buildProcessingIndicator() {
    return Column(
      children: [
        LoadingAnimationWidget.staggeredDotsWave(
          color: AppColors.primaryBlue,
          size: 50,
        ),
        const SizedBox(height: AppDimensions.paddingM),
        Text(
          _processingStatus,
          style: AppTextStyles.subtitle,
        ),
      ],
    );
  }
  
  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: AppDimensions.buttonHeight,
          child: ElevatedButton.icon(
            onPressed: hasSelectedImage() ? _processImage : null,
            icon: const Icon(Icons.document_scanner),
            label: const Text('Process Prescription'),
          ),
        ),
        const SizedBox(height: AppDimensions.paddingM),
        SizedBox(
          width: double.infinity,
          height: AppDimensions.buttonHeight,
          child: OutlinedButton.icon(
            onPressed: _showImageSourceSelection,
            icon: const Icon(Icons.photo_library),
            label: Text(hasSelectedImage()
                ? 'Change Image'
                : AppStrings.selectImage),
          ),
        ),
      ],
    );
  }
  
  void _showImageSourceSelection() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusL),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingL),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  AppStrings.selectImage,
                  style: AppTextStyles.heading3,
                ),
                const SizedBox(height: AppDimensions.paddingL),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildImageSourceOption(
                      icon: Icons.camera_alt,
                      label: AppStrings.camera,
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.camera);
                      },
                    ),
                    _buildImageSourceOption(
                      icon: Icons.photo_library,
                      label: AppStrings.gallery,
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.gallery);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingL),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: AppColors.primaryBlue,
              size: 32,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingS),
          Text(
            label,
            style: AppTextStyles.subtitle,
          ),
        ],
      ),
    );
  }
} 