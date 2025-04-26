class LanguageModel {
  final String code;
  final String name;
  final String nativeName;

  LanguageModel({
    required this.code,
    required this.name,
    required this.nativeName,
  });

  // Return a list of supported languages
  static List<LanguageModel> supportedLanguages() {
    return [
      LanguageModel(
        code: 'en',
        name: 'English',
        nativeName: 'English',
      ),
      LanguageModel(
        code: 'es',
        name: 'Spanish',
        nativeName: 'Español',
      ),
      LanguageModel(
        code: 'fr',
        name: 'French',
        nativeName: 'Français',
      ),
      LanguageModel(
        code: 'de',
        name: 'German',
        nativeName: 'Deutsch',
      ),
      LanguageModel(
        code: 'it',
        name: 'Italian',
        nativeName: 'Italiano',
      ),
      LanguageModel(
        code: 'pt',
        name: 'Portuguese',
        nativeName: 'Português',
      ),
      LanguageModel(
        code: 'ru',
        name: 'Russian',
        nativeName: 'Русский',
      ),
      LanguageModel(
        code: 'zh',
        name: 'Chinese',
        nativeName: '中文',
      ),
      LanguageModel(
        code: 'ja',
        name: 'Japanese',
        nativeName: '日本語',
      ),
      LanguageModel(
        code: 'hi',
        name: 'Hindi',
        nativeName: 'हिन्दी',
      ),
      LanguageModel(
        code: 'ar',
        name: 'Arabic',
        nativeName: 'العربية',
      ),
      LanguageModel(
        code: 'gu',
        name: 'Gujarati',
        nativeName: 'ગુજરાતી',
      ),
    ];
  }

  // Find a language by its code
  static LanguageModel? findByCode(String code) {
    try {
      return supportedLanguages().firstWhere((lang) => lang.code == code);
    } catch (e) {
      return null;
    }
  }
} 