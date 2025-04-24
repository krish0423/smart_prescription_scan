# Smart Prescription Scan

A Flutter application that allows users to upload or capture medical prescriptions, extract and summarize the content using the Gemini API, and translate the summary into multiple languages.

## Features

- **Prescription Scanning**: Capture or upload images of medical prescriptions.
- **AI-Powered Summaries**: Extract key information from prescriptions using Google's Gemini API.
- **Translation**: Translate summaries to multiple languages.
- **Local Storage**: Store prescription data locally on the device.
- **Search & Filter**: Search through your prescription history and filter by importance.
- **User Profile**: Set user preferences including default language.

## Tech Stack

- **Flutter & Dart**: For cross-platform mobile development
- **Google Gemini API**: For AI-powered image analysis and text generation
- **Hive & SharedPreferences**: For local data storage
- **Provider**: For state management

## Screenshots

*Coming soon*

## Getting Started

### Prerequisites

- Flutter (Latest stable version)
- Dart (Latest stable version)
- A Google Gemini API key

### Installation

1. Clone this repository:
```
git clone https://github.com/yourusername/smart_prescription_scan.git
cd smart_prescription_scan
```

2. Install dependencies:
```
flutter pub get
```

3. Add your Gemini API key:
   - Open `lib/services/gemini_service.dart`
   - Replace `YOUR_GEMINI_API_KEY` with your actual API key

4. Run the app:
```
flutter run
```

## Project Structure

```
lib/
├── constants/       # App constants, colors, themes, strings
├── models/          # Data models
├── screens/         # UI screens
├── services/        # Business logic and API services
├── utils/           # Utility functions
├── widgets/         # Reusable UI components
└── main.dart        # Entry point
```

## Future Enhancements

- Cloud synchronization
- OCR for better prescription scanning
- Medication reminders
- Export to PDF
- Dark mode support

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Google Gemini API for providing the AI capabilities
- The Flutter team for the amazing framework
