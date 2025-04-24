# Firebase Setup Instructions

To properly set up Firebase authentication in your Smart Prescription Scan app, follow these steps:

## 1. Create a Firebase Project

1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Click on "Add project" and follow the setup wizard
3. Enter a name for your project (e.g., "Smart Prescription Scan")
4. Enable Google Analytics if desired
5. Click "Create project"

## 2. Register your Flutter app with Firebase

### For Android:

1. In Firebase Console, click "Add app" and select Android
2. Enter your app's package name (found in `android/app/build.gradle` - applicationId)
3. Enter a nickname for your app (optional)
4. Enter your SHA-1 signing certificate (for Google Sign-In)
   ```bash
   cd android && ./gradlew signingReport
   ```
5. Click "Register app"
6. Download the `google-services.json` file
7. Move the downloaded file to the `android/app` directory of your Flutter project

### For iOS:

1. In Firebase Console, click "Add app" and select iOS
2. Enter your app's Bundle ID (found in Xcode project settings)
3. Enter a nickname for your app (optional)
4. Click "Register app"
5. Download the `GoogleService-Info.plist` file
6. Move the downloaded file to the `ios/Runner` directory of your Flutter project
7. Open the Xcode project, right-click on the Runner directory, and select "Add Files to 'Runner'"
8. Select the `GoogleService-Info.plist` file and make sure "Copy items if needed" is checked

## 3. Configure Firebase in your Flutter project

### For Android:

1. Ensure your `android/build.gradle` file has Google services plugin dependency:
   ```gradle
   buildscript {
     dependencies {
       // ... other dependencies
       classpath 'com.google.gms:google-services:4.3.15'
     }
   }
   ```

2. Ensure your `android/app/build.gradle` file has Google services plugin applied:
   ```gradle
   apply plugin: 'com.android.application'
   apply plugin: 'kotlin-android'
   apply plugin: 'com.google.gms.google-services'  // Add this line
   ```

### For iOS:

1. In your Xcode project, ensure you've added the `GoogleService-Info.plist` file
2. Update your `ios/Podfile` to include Firebase pods (should be automatically handled by Flutter's Firebase packages)

## 4. Enable Authentication Methods

1. In Firebase Console, go to "Authentication" in the left sidebar
2. Click on "Get started"
3. Enable "Email/Password" authentication:
   - Click on "Email/Password"
   - Toggle the "Enable" switch
   - Click "Save"
4. Enable "Google" authentication:
   - Click on "Google"
   - Toggle the "Enable" switch
   - Enter your support email
   - Click "Save"

## 5. Configure Google Sign-In (Additional Steps)

### For Android:
1. Make sure you've added the SHA-1 fingerprint to your Firebase project
2. Update your `android/app/build.gradle` file to include the required dependencies

### For iOS:
1. Add your app's reverse client ID to the Info.plist:
   - Open the `GoogleService-Info.plist` and find the REVERSED_CLIENT_ID value
   - Add it to your `Info.plist` under `CFBundleURLTypes`

## 6. Test Authentication

Once you've completed these steps, you should be able to test authentication by:
1. Building and running your app
2. Navigating to the Login screen
3. Testing both Email/Password login and Google Sign-In

## Troubleshooting

- If you encounter issues with Google Sign-In on Android, double-check your SHA-1 fingerprint
- For iOS issues, ensure the `GoogleService-Info.plist` is properly added to your project
- Check Firebase Console for authentication issues in the "Authentication" section
- Review error messages in your app's logs for specific issues

## Next Steps

After setting up authentication, you may want to:
1. Set up Firebase security rules for your database
2. Implement user-specific data storage
3. Configure email verification or password reset functionality 