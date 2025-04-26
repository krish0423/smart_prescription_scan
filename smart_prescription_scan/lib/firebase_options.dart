import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    throw UnsupportedError(
      'This app is configured only for web platform',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'YOUR API KEY',
    appId: 'YOUR APP ID',
    messagingSenderId: 'YOURS',
    projectId: 'YOURS',
    authDomain: 'YOURS',
    storageBucket: 'YOURS',
    measurementId: 'YOURS',
  );
} 
