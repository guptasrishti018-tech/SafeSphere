class AppData {
  static String selectedLanguage = "English";
  static String userName = "Traveler";

  static List<String> languages = [
    "English",
    "हिन्दी",
    "Français",
    "Español",
    "Deutsch",
    "Italiano",
    "Português",
    "Русский",
    "中文",
    "日本語",
    "한국어",
    "العربية",
    "Türkçe",
    "Nederlands",
    "বাংলা",
    "ਪੰਜਾਬੀ",
    "اردو",
    "தமிழ்",
    "తెలుగు",
    "मराठी",
    "ગુજરાતી",
  ];

  static String tr(String english, Map<String, String> translations) {
    return translations[selectedLanguage] ?? english;
  }
}
