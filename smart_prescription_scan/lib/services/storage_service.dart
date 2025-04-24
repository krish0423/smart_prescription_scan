import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/prescription_model.dart';
import '../models/user_model.dart';

class StorageService {
  // Box names for Hive storage
  static const String _prescriptionsBoxName = 'prescriptions';
  
  // Keys for SharedPreferences
  static const String _userPrefsKey = 'user_preferences';
  
  late Box<String> _prescriptionsBox;
  late SharedPreferences _prefs;
  final _uuid = const Uuid();
  
  // Singleton instance
  static final StorageService _instance = StorageService._internal();
  
  // Factory constructor
  factory StorageService() {
    return _instance;
  }
  
  StorageService._internal();
  
  // Initialize storage
  Future<void> init() async {
    // Initialize Hive
    await Hive.initFlutter();
    
    // Open boxes
    _prescriptionsBox = await Hive.openBox<String>(_prescriptionsBoxName);
    
    // Initialize SharedPreferences
    _prefs = await SharedPreferences.getInstance();
  }
  
  // Save a prescription
  Future<void> savePrescription(PrescriptionModel prescription) async {
    await _prescriptionsBox.put(prescription.id, prescription.serialize());
  }
  
  // Get a prescription by ID
  PrescriptionModel? getPrescription(String id) {
    final data = _prescriptionsBox.get(id);
    if (data == null) return null;
    return PrescriptionModel.deserialize(data);
  }
  
  // Get all prescriptions
  List<PrescriptionModel> getAllPrescriptions() {
    return _prescriptionsBox.values
        .map((data) => PrescriptionModel.deserialize(data))
        .toList();
  }
  
  // Delete a prescription
  Future<void> deletePrescription(String id) async {
    await _prescriptionsBox.delete(id);
  }
  
  // Generate a unique ID for new prescriptions
  String generateUniqueId() {
    return _uuid.v4();
  }
  
  // Save an image to local storage and return the path
  Future<String> saveImage(File imageFile) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/images';
    
    // Create the directory if it doesn't exist
    final imageDir = Directory(path);
    if (!await imageDir.exists()) {
      await imageDir.create(recursive: true);
    }
    
    // Generate a unique filename
    final filename = '${generateUniqueId()}.jpg';
    final imagePath = '$path/$filename';
    
    // Copy the image file to the new path
    await imageFile.copy(imagePath);
    
    return imagePath;
  }
  
  // Save user preferences
  Future<void> saveUserPreferences(UserModel user) async {
    await _prefs.setString(_userPrefsKey, user.serialize());
  }
  
  // Get user preferences
  UserModel getUserPreferences() {
    final data = _prefs.getString(_userPrefsKey);
    if (data == null) {
      // Return default user preferences
      return UserModel();
    }
    return UserModel.deserialize(data);
  }
} 