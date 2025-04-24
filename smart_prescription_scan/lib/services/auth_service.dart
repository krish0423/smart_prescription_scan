import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import '../models/user_model.dart';

class AuthResult {
  final bool success;
  final String? error;
  final UserModel? user;

  AuthResult({
    required this.success, 
    this.error, 
    this.user
  });
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // Adding clientId here provides a fallback if meta tag approach fails
    clientId: kIsWeb ? '342682518669-bjjuue0p31m3s75c4qu14sgipbpmm1ck.apps.googleusercontent.com' : null,
    scopes: ['email', 'profile'],
  );
  late final FirebaseFirestore _firestore;
  
  // Constructor with Firestore initialization
  AuthService() {
    _firestore = FirebaseFirestore.instance;
    
    // Enable offline persistence for web using recommended settings approach
    if (kIsWeb) {
      _firestore.settings = const Settings(
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        persistenceEnabled: true,
      );
      
      debugPrint('Firestore initialized with persistence for web');
    }
  }

  // Get current Firebase user
  User? get currentUser => _auth.currentUser;

  // Check if user is logged in
  bool get isLoggedIn => _auth.currentUser != null;

  // Stream of authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Helper method to safely access Firestore and handle connection errors
  Future<T> _safeFirestoreOperation<T>(Future<T> Function() operation, {T? defaultValue}) async {
    try {
      return await operation();
    } catch (e) {
      debugPrint('Firestore operation failed: ${e.toString()}');
      if (defaultValue != null) {
        return defaultValue;
      }
      rethrow;
    }
  }

  // Register with email and password
  Future<AuthResult> registerWithEmailAndPassword(String email, String password, String name) async {
    try {
      // Create user with email and password
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );
      
      // Get user
      final User? user = result.user;
      
      if (user != null) {
        // Create user document in Firestore
        await _safeFirestoreOperation(() => 
          _firestore.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'email': email,
            'name': name,
            'createdAt': FieldValue.serverTimestamp(),
          })
        );
        
        // Return user model
        return AuthResult(
          success: true,
          user: UserModel(
            uid: user.uid,
            email: email,
            name: name,
            isAuthenticated: true,
          )
        );
      }
      
      return AuthResult(
        success: false,
        error: 'Registration failed'
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(
        success: false,
        error: _handleAuthException(e)
      );
    } catch (e) {
      return AuthResult(
        success: false,
        error: e.toString()
      );
    }
  }

  // Sign in with email and password
  Future<AuthResult> signInWithEmailAndPassword(String email, String password) async {
    try {
      // Sign in user
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );
      
      // Get user
      final User? user = result.user;
      
      if (user != null) {
        // Get user data from Firestore
        DocumentSnapshot? userDoc;
        try {
          userDoc = await _safeFirestoreOperation(
            () => _firestore.collection('users').doc(user.uid).get(),
          );
        } catch (e) {
          // Continue with basic user data if Firestore is unreachable
          return AuthResult(
            success: true,
            user: UserModel(
              uid: user.uid,
              email: user.email,
              isAuthenticated: true,
            )
          );
        }
        
        if (userDoc != null && userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          
          // Return user model
          return AuthResult(
            success: true,
            user: UserModel(
              uid: user.uid,
              email: user.email,
              name: userData['name'] ?? '',
              isAuthenticated: true,
            )
          );
        }
        
        // If user doc doesn't exist, create it
        _safeFirestoreOperation(() => 
          _firestore.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'email': email,
            'createdAt': FieldValue.serverTimestamp(),
          })
        );
        
        return AuthResult(
          success: true,
          user: UserModel(
            uid: user.uid,
            email: user.email,
            isAuthenticated: true,
          )
        );
      }
      
      return AuthResult(
        success: false,
        error: 'Login failed'
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(
        success: false,
        error: _handleAuthException(e)
      );
    } catch (e) {
      return AuthResult(
        success: false,
        error: e.toString()
      );
    }
  }

  // Sign in with Google
  Future<AuthResult> signInWithGoogle() async {
    try {      
      // Start the Google sign-in process
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        return AuthResult(
          success: false,
          error: 'Google sign in cancelled'
        );
      }
      
      // Get authentication details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Create credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      // Sign in with Firebase
      final UserCredential result = await _auth.signInWithCredential(credential);
      final User? user = result.user;
      
      if (user != null) {
        // Check if user exists in Firestore
        DocumentSnapshot? userDoc;
        try {
          userDoc = await _safeFirestoreOperation(
            () => _firestore.collection('users').doc(user.uid).get(),
          );
        } catch (e) {
          // If Firestore is unavailable, continue with basic authentication
          return AuthResult(
            success: true,
            user: UserModel(
              uid: user.uid,
              email: user.email,
              name: user.displayName ?? '',
              profilePicturePath: user.photoURL,
              isAuthenticated: true,
            )
          );
        }
        
        if (userDoc == null || !userDoc.exists) {
          // Create user document if it doesn't exist
          _safeFirestoreOperation(() => 
            _firestore.collection('users').doc(user.uid).set({
              'uid': user.uid,
              'email': user.email,
              'name': user.displayName ?? '',
              'photoURL': user.photoURL,
              'createdAt': FieldValue.serverTimestamp(),
            })
          );
        }
        
        // Return user model
        return AuthResult(
          success: true,
          user: UserModel(
            uid: user.uid,
            email: user.email,
            name: user.displayName ?? '',
            profilePicturePath: user.photoURL,
            isAuthenticated: true,
          )
        );
      }
      
      return AuthResult(
        success: false,
        error: 'Google sign in failed'
      );
    } catch (e) {
      debugPrint('Error during Google sign in: ${e.toString()}');
      return AuthResult(
        success: false,
        error: e.toString()
      );
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // Sign out from Google
      await _googleSignIn.signOut().catchError((e) {
        // Log error but continue
        debugPrint('Error signing out from Google: $e');
      });
      
      // Sign out from Firebase
      await _auth.signOut();
      
      debugPrint('User signed out successfully');
    } catch (e) {
      debugPrint('Error during sign out: $e');
      // Rethrow to handle in UI
      rethrow;
    }
  }

  // Reset password
  Future<AuthResult> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return AuthResult(success: true);
    } on FirebaseAuthException catch (e) {
      return AuthResult(
        success: false,
        error: _handleAuthException(e)
      );
    } catch (e) {
      return AuthResult(
        success: false,
        error: e.toString()
      );
    }
  }

  // Get user data from Firestore
  Future<UserModel?> getUserData() async {
    try {
      final User? currentUser = _auth.currentUser;
      
      if (currentUser != null) {
        final DocumentSnapshot userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
        
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          
          return UserModel(
            uid: currentUser.uid,
            email: currentUser.email,
            name: userData['name'] ?? '',
            profilePicturePath: userData['photoURL'],
            isAuthenticated: true,
          );
        }
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  // Update user profile
  Future<bool> updateUserProfile({String? name, String? photoURL}) async {
    try {
      final User? user = _auth.currentUser;
      
      if (user != null) {
        final Map<String, dynamic> data = {};
        
        if (name != null) data['name'] = name;
        if (photoURL != null) data['photoURL'] = photoURL;
        
        await _firestore.collection('users').doc(user.uid).update(data);
        return true;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already registered';
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'weak-password':
        return 'Password is too weak';
      case 'operation-not-allowed':
        return 'Operation not allowed';
      case 'invalid-credential':
        return 'Invalid credentials';
      case 'account-exists-with-different-credential':
        return 'An account already exists with this email';
      default:
        return e.message ?? 'An error occurred';
    }
  }
} 