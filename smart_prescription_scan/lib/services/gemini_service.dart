import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../models/medicine_model.dart';

class GeminiService {
  static const String _apiKey = 'AIzaSyBy3UPJiZ1-WUc_6u2bqSienwtFqGeXMbg';
  late final GenerativeModel _model;

  GeminiService() {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
    );
  }

  Future<String> generatePrescriptionSummary(File imageFile) async {
    try {
      final Uint8List imageBytes = await imageFile.readAsBytes();
      return await generatePrescriptionSummaryFromBytes(imageBytes);
    } catch (e) {
      if (kDebugMode) {
        print('Error generating summary: $e');
      }
      throw Exception('Failed to generate prescription summary. Please try again. Error: $e');
    }
  }

  Future<String> generatePrescriptionSummaryFromBytes(Uint8List imageBytes) async {
    try {
      final prompt = '''
Please analyze this medical prescription image and provide a structured summary including:
1. Patient information (if present)
2. Doctor's name and details (if present)
3. Date of prescription
4. Medications prescribed (name, dosage, frequency)
5. Additional instructions or notes

For each medication listed, also include:
6. Purpose/Uses : What is this medicine typically used for?
7. How it works : A brief, patient-friendly explanation.
8. Side Effects : Common side effects.
9. Risks of Overconsumption : What could happen if this medicine is taken in excess?
Format your response in an organized way that's easy to read. Do not include any disclaimers or additional text in your response.
''';

      final parts = [
        TextPart(prompt),
        DataPart('image/jpeg', imageBytes),
      ];

      final response = await _model.generateContent(
        [Content('user', parts)],
        generationConfig: GenerationConfig(temperature: 0.2),
      );

      final responseText = response.text;
      if (responseText == null || responseText.isEmpty) {
        throw Exception('Empty response from Gemini API');
      }
      return responseText;
    } catch (e) {
      if (kDebugMode) {
        print('Error generating summary from bytes: $e');
      }
      throw Exception('Failed to generate prescription summary. Please try again. Error: $e');
    }
  }

  Future<String> translateSummary(String summary, String targetLanguage) async {
    try {
      final textModel = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _apiKey,
      );

      final prompt = '''
Translate the following medical prescription summary to $targetLanguage. 
Keep the formatting intact and ensure medical terms are accurately translated:

$summary
''';

      final response = await textModel.generateContent(
        [Content('user', [TextPart(prompt)])],
      );

      final responseText = response.text;
      if (responseText == null || responseText.isEmpty) {
        throw Exception('Empty translation response from Gemini API');
      }
      return responseText;
    } catch (e) {
      if (kDebugMode) {
        print('Error translating summary: $e');
      }
      throw Exception('Failed to translate the summary. Please try again.');
    }
  }
  
  Future<List<MedicineModel>> extractMedicinesFromSummary(String summary) async {
    try {
      final textModel = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _apiKey,
      );

      final prompt = '''
Extract all medications from the following prescription summary. For each medicine, provide:
1. Name of the medicine
2. Usage: What the medicine is used for
3. Mechanism: How the medicine works
4. Side Effects: Common side effects
5. Risks: Risks of overconsumption or improper use

Format the response as JSON array with each medicine having these fields: name, usage, mechanism, sideEffects, risks.
ONLY return the JSON array, nothing else. Do not wrap the JSON in markdown code blocks.

Here's the prescription summary:
$summary
''';

      final response = await textModel.generateContent(
        [Content('user', [TextPart(prompt)])],
        generationConfig: GenerationConfig(temperature: 0.2),
      );

      String responseText = response.text ?? '';
      if (responseText.isEmpty) {
        throw Exception('Empty response when extracting medicines');
      }
      
      // Clean up any markdown formatting that might be around the JSON
      // Remove markdown code block syntax if present (```json or just ```)
      if (responseText.startsWith('```')) {
        // Find the first newline after the opening backticks
        int startIndex = responseText.indexOf('\n');
        if (startIndex != -1) {
          // Find the closing backticks
          int endIndex = responseText.lastIndexOf('```');
          if (endIndex != -1) {
            // Extract just the JSON content between the backticks
            responseText = responseText.substring(startIndex + 1, endIndex).trim();
          } else {
            // If no closing backticks, just remove the opening part
            responseText = responseText.substring(startIndex + 1).trim();
          }
        }
      }
      
      // Parse the JSON response
      final List<dynamic> medicinesJson = jsonDecode(responseText);
      return medicinesJson.map((json) => MedicineModel.fromJson(json)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error extracting medicines: $e');
      }
      throw Exception('Failed to extract medicines from the summary. Please try again.');
    }
  }
  
  Future<MedicineModel> getMedicineDetails(String medicineName) async {
    try {
      final textModel = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _apiKey,
      );

      final prompt = '''
Provide detailed information about the medicine "$medicineName" including:
1. Usage: What the medicine is used for
2. Mechanism: How the medicine works
3. Side Effects: Common side effects
4. Risks: Risks of overconsumption or improper use

Format the response as a JSON object with these fields: name, usage, mechanism, sideEffects, risks.
ONLY return the JSON object, nothing else. Do not wrap the JSON in markdown code blocks.
''';

      final response = await textModel.generateContent(
        [Content('user', [TextPart(prompt)])],
        generationConfig: GenerationConfig(temperature: 0.2),
      );

      String responseText = response.text ?? '';
      if (responseText.isEmpty) {
        throw Exception('Empty response when getting medicine details');
      }
      
      // Clean up any markdown formatting that might be around the JSON
      // Remove markdown code block syntax if present (```json or just ```)
      if (responseText.startsWith('```')) {
        // Find the first newline after the opening backticks
        int startIndex = responseText.indexOf('\n');
        if (startIndex != -1) {
          // Find the closing backticks
          int endIndex = responseText.lastIndexOf('```');
          if (endIndex != -1) {
            // Extract just the JSON content between the backticks
            responseText = responseText.substring(startIndex + 1, endIndex).trim();
          } else {
            // If no closing backticks, just remove the opening part
            responseText = responseText.substring(startIndex + 1).trim();
          }
        }
      }
      
      // Parse the JSON response
      final Map<String, dynamic> medicineJson = jsonDecode(responseText);
      return MedicineModel.fromJson(medicineJson);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting medicine details: $e');
      }
      throw Exception('Failed to get medicine details. Please try again.');
    }
  }

  Future<MedicineModel> translateMedicine(MedicineModel medicine, String languageCode, String languageName) async {
    try {
      if (medicine.translations.containsKey(languageCode)) {
        // Translation already exists
        return medicine;
      }

      final textModel = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _apiKey,
      );

      final prompt = '''
Translate the following medicine details to $languageName. Keep medical terms accurate.

Name: ${medicine.name}
Usage: ${medicine.usage}
Mechanism: ${medicine.mechanism}
Side Effects: ${medicine.sideEffects}
Risks: ${medicine.risks}

Format your response as a JSON object with these fields: name, usage, mechanism, sideEffects, risks.
Return ONLY the JSON object, nothing else. Do not wrap the JSON in markdown code blocks.
''';

      final response = await textModel.generateContent(
        [Content('user', [TextPart(prompt)])],
        generationConfig: GenerationConfig(temperature: 0.2),
      );

      String responseText = response.text ?? '';
      if (responseText.isEmpty) {
        throw Exception('Empty response when translating medicine');
      }
      
      // Clean up any markdown formatting that might be around the JSON
      if (responseText.startsWith('```')) {
        // Find the first newline after the opening backticks
        int startIndex = responseText.indexOf('\n');
        if (startIndex != -1) {
          // Find the closing backticks
          int endIndex = responseText.lastIndexOf('```');
          if (endIndex != -1) {
            // Extract just the JSON content
            responseText = responseText.substring(startIndex + 1, endIndex).trim();
          } else {
            // If no closing backticks, just remove the opening part
            responseText = responseText.substring(startIndex + 1).trim();
          }
        }
      }
      
      // Parse the JSON response
      final Map<String, dynamic> translatedFields = jsonDecode(responseText);
      
      // Create a new translations map with the existing translations
      final Map<String, Map<String, String>> updatedTranslations = 
          Map<String, Map<String, String>>.from(medicine.translations);
      
      // Add the new translation
      updatedTranslations[languageCode] = {
        'name': translatedFields['name'] ?? medicine.name,
        'usage': translatedFields['usage'] ?? medicine.usage,
        'mechanism': translatedFields['mechanism'] ?? medicine.mechanism,
        'sideEffects': translatedFields['sideEffects'] ?? medicine.sideEffects,
        'risks': translatedFields['risks'] ?? medicine.risks,
      };
      
      // Return a new medicine model with the updated translations
      return medicine.copyWith(translations: updatedTranslations);
    } catch (e) {
      if (kDebugMode) {
        print('Error translating medicine: $e');
      }
      throw Exception('Failed to translate medicine details. Please try again.');
    }
  }
}
