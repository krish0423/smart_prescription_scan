# iOS Firebase Configuration

To complete the Firebase setup for iOS, follow these steps:

1. Download the `GoogleService-Info.plist` file from your Firebase console
2. Add it to your Xcode project:
   - Open your Xcode project: `open ios/Runner.xcworkspace`
   - Right-click on the "Runner" folder in Xcode's Project Navigator
   - Select "Add Files to 'Runner'..."
   - Select the `GoogleService-Info.plist` file you downloaded
   - Make sure "Copy items if needed" is checked
   - Click "Add"

3. Update your `ios/Runner/Info.plist` to include Google Sign-In configuration:
   
```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <!-- Replace with your REVERSED_CLIENT_ID from GoogleService-Info.plist -->
      <string>com.googleusercontent.apps.342682518669-xxxxxxxxxxxxxxxxxx</string>
    </array>
  </dict>
</array>
```

4. If you haven't already, make sure your Podfile has a minimum deployment target of iOS 11.0 or higher:

```ruby
platform :ios, '11.0'
```

5. Run `pod install` from the `ios` directory:

```bash
cd ios
pod install
```

After completing these steps, your Firebase configuration for iOS should be ready. 