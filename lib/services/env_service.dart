import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvService {
  static bool _isLoaded = false;
  
  /// Initialize environment variables
  static Future<void> load() async {
    if (!_isLoaded) {
      await dotenv.load(fileName: ".env");
      _isLoaded = true;
    }
  }
  
  /// Get Google Client ID from environment
  static String get googleClientId {
    return dotenv.env['GOOGLE_CLIENT_ID'] ?? '';
  }
  
  /// Get Google Client Secret from environment
  static String get googleClientSecret {
    return dotenv.env['GOOGLE_CLIENT_SECRET'] ?? '';
  }
  
  /// Check if environment variables are properly loaded
  static bool get isConfigured {
    return googleClientId.isNotEmpty && googleClientSecret.isNotEmpty;
  }
}