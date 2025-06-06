import 'dart:convert';

class MedicineModel {
  final String name;
  final String usage;
  final String mechanism;
  final String sideEffects;
  final String risks;
  final String dosage;
  final String category;
  final String interactions;
  final Map<String, Map<String, String>> translations; // Language code to field translations mapping

  MedicineModel({
    required this.name,
    required this.usage,
    required this.mechanism,
    required this.sideEffects,
    required this.risks,
    this.dosage = '',
    this.category = '',
    this.interactions = '',
    this.translations = const {},
  });

  // Create a copy of this medicine model with updated fields
  MedicineModel copyWith({
    String? name,
    String? usage,
    String? mechanism,
    String? sideEffects,
    String? risks,
    String? dosage,
    String? category,
    String? interactions,
    Map<String, Map<String, String>>? translations,
  }) {
    return MedicineModel(
      name: name ?? this.name,
      usage: usage ?? this.usage,
      mechanism: mechanism ?? this.mechanism,
      sideEffects: sideEffects ?? this.sideEffects,
      risks: risks ?? this.risks,
      dosage: dosage ?? this.dosage,
      category: category ?? this.category,
      interactions: interactions ?? this.interactions,
      translations: translations ?? this.translations,
    );
  }

  // Get a translated field value
  String getTranslatedField(String field, String languageCode) {
    if (languageCode == 'en') {
      switch (field) {
        case 'name': return name;
        case 'usage': return usage;
        case 'mechanism': return mechanism;
        case 'sideEffects': return sideEffects;
        case 'risks': return risks;
        case 'dosage': return dosage;
        case 'category': return category;
        case 'interactions': return interactions;
        default: return '';
      }
    }

    if (translations.containsKey(languageCode) && 
        translations[languageCode]!.containsKey(field)) {
      return translations[languageCode]![field]!;
    }

    // Fall back to English if translation is not available
    switch (field) {
      case 'name': return name;
      case 'usage': return usage;
      case 'mechanism': return mechanism;
      case 'sideEffects': return sideEffects;
      case 'risks': return risks;
      case 'dosage': return dosage;
      case 'category': return category;
      case 'interactions': return interactions;
      default: return '';
    }
  }

  // Convert model to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'usage': usage,
      'mechanism': mechanism,
      'sideEffects': sideEffects,
      'risks': risks,
      'dosage': dosage,
      'category': category,
      'interactions': interactions,
      'translations': translations,
    };
  }

  // Create model from JSON
  factory MedicineModel.fromJson(Map<String, dynamic> json) {
    Map<String, Map<String, String>> translations = {};
    
    if (json['translations'] != null) {
      final translationsMap = json['translations'] as Map<String, dynamic>;
      translationsMap.forEach((langCode, fields) {
        translations[langCode] = Map<String, String>.from(fields as Map);
      });
    }
    
    return MedicineModel(
      name: json['name'] ?? '',
      usage: json['usage'] ?? '',
      mechanism: json['mechanism'] ?? '',
      sideEffects: json['sideEffects'] ?? '',
      risks: json['risks'] ?? '',
      dosage: json['dosage'] ?? '',
      category: json['category'] ?? '',
      interactions: json['interactions'] ?? '',
      translations: translations,
    );
  }

  // For storing in storage if needed
  String serialize() {
    return jsonEncode(toJson());
  }

  // For retrieving from storage if needed
  static MedicineModel deserialize(String data) {
    return MedicineModel.fromJson(jsonDecode(data));
  }
} 