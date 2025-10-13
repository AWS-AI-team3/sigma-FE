class ApiLogger {
  static void request(String method, String endpoint) {
    print('📤 API Request: $method $endpoint');
  }

  static void response(int statusCode, String endpoint) {
    final emoji = statusCode >= 200 && statusCode < 300 ? '✅' : '❌';
    print('$emoji API Response: $statusCode $endpoint');
  }

  static void error(String message, dynamic error) {
    print('❌ API Error: $message - $error');
  }
}
