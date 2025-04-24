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
    apiKey: 'AIzaSyBkzQalJ5GXxWGKPE09-wlZYgLhTJYdIYM',
    appId: '1:342682518669:web:df1a4707dff1f551b68ec4',
    messagingSenderId: '342682518669',
    projectId: 'smartprescriptionscan-8684f',
    authDomain: 'smartprescriptionscan-8684f.firebaseapp.com',
    storageBucket: 'smartprescriptionscan-8684f.firebasestorage.app',
    measurementId: 'G-2TSBQ836RH',
  );
} 