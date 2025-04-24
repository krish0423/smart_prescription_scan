import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

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
}
