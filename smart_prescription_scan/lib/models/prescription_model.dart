import 'dart:convert';

class PrescriptionModel {
  final String id; // Unique identifier
  final String imagePath; // Local path to prescription image
  final String summary; // AI-generated summary
  final Map<String, String> translations; // Language code to translation mapping
  final DateTime dateScanned; // Date when prescription was scanned
  final bool isImportant; // Whether user marked it as important

  PrescriptionModel({
    required this.id,
    required this.imagePath,
    required this.summary,
    required this.translations,
    required this.dateScanned,
    this.isImportant = false,
  });

  // Create a copy of this prescription model with updated fields
  PrescriptionModel copyWith({
    String? id,
    String? imagePath,
    String? summary,
    Map<String, String>? translations,
    DateTime? dateScanned,
    bool? isImportant,
  }) {
    return PrescriptionModel(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      summary: summary ?? this.summary,
      translations: translations ?? this.translations,
      dateScanned: dateScanned ?? this.dateScanned,
      isImportant: isImportant ?? this.isImportant,
    );
  }

  // Convert model to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imagePath': imagePath,
      'summary': summary,
      'translations': translations,
      'dateScanned': dateScanned.millisecondsSinceEpoch,
      'isImportant': isImportant,
    };
  }

  // Create model from JSON
  factory PrescriptionModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> translationsMap = json['translations'];
    Map<String, String> translations = {};
    
    translationsMap.forEach((key, value) {
      translations[key] = value.toString();
    });
    
    return PrescriptionModel(
      id: json['id'],
      imagePath: json['imagePath'],
      summary: json['summary'],
      translations: translations,
      dateScanned: DateTime.fromMillisecondsSinceEpoch(json['dateScanned']),
      isImportant: json['isImportant'] ?? false,
    );
  }

  // For storing in Hive
  String serialize() {
    return jsonEncode(toJson());
  }

  // For retrieving from Hive
  static PrescriptionModel deserialize(String data) {
    return PrescriptionModel.fromJson(jsonDecode(data));
  }
} 