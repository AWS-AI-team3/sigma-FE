import 'dart:developer' as developer;

enum LogLevel {
  debug(0),
  info(1),
  warning(2),
  error(3),
  none(4);

  const LogLevel(this.value);
  final int value;
}

class Logger {
  static LogLevel _currentLevel = LogLevel.info; // 기본 레벨: info
  
  // 환경별 로그 레벨 설정
  static void setLevel(LogLevel level) {
    _currentLevel = level;
  }
  
  // 개발 환경에서는 모든 로그, 프로덕션에서는 error만
  static void setEnvironment({bool isProduction = false}) {
    _currentLevel = isProduction ? LogLevel.error : LogLevel.debug;
  }
  
  static void debug(String message, [String? tag]) {
    _log(LogLevel.debug, message, tag, '🔍');
  }
  
  static void info(String message, [String? tag]) {
    _log(LogLevel.info, message, tag, 'ℹ️');
  }
  
  static void warning(String message, [String? tag]) {
    _log(LogLevel.warning, message, tag, '⚠️');
  }
  
  static void error(String message, [String? tag, Object? error]) {
    _log(LogLevel.error, message, tag, '❌');
    if (error != null) {
      _log(LogLevel.error, 'Error details: $error', tag, '❌');
    }
  }
  
  // 성공 메시지 (info 레벨)
  static void success(String message, [String? tag]) {
    _log(LogLevel.info, message, tag, '✅');
  }
  
  // 진행 상황 (info 레벨)
  static void progress(String message, [String? tag]) {
    _log(LogLevel.info, message, tag, '🔄');
  }
  
  // 네트워크 관련 (debug 레벨)
  static void network(String message, [String? tag]) {
    _log(LogLevel.debug, message, tag, '🌐');
  }
  
  // 토큰 관련 (info 레벨, 보안상 상세 내용은 debug만)
  static void token(String message, [String? tag]) {
    _log(LogLevel.info, message, tag, '🔑');
  }
  
  static void _log(LogLevel level, String message, String? tag, String emoji) {
    if (level.value < _currentLevel.value) return;
    
    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    final tagStr = tag != null ? '[$tag] ' : '';
    final formattedMessage = '$emoji $timestamp $tagStr$message';
    
    // Flutter에서는 developer.log 사용 권장
    developer.log(
      formattedMessage,
      name: tag ?? 'SIGMA',
      level: _getLogLevelValue(level),
    );
  }
  
  static int _getLogLevelValue(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 500;
      case LogLevel.info:
        return 800;
      case LogLevel.warning:
        return 900;
      case LogLevel.error:
        return 1000;
      case LogLevel.none:
        return 2000;
    }
  }
}

// 태그별 로거 클래스들
class AuthLogger {
  static void success(String message) => Logger.success(message, 'AUTH');
  static void error(String message, [Object? error]) => Logger.error(message, 'AUTH', error);
  static void token(String message) => Logger.token(message, 'AUTH');
  static void debug(String message) => Logger.debug(message, 'AUTH');
}

class ApiLogger {
  static void request(String method, String endpoint) => 
      Logger.network('$method $endpoint', 'API');
  static void response(int statusCode, String endpoint) => 
      Logger.network('$statusCode $endpoint', 'API');
  static void error(String message, [Object? error]) => 
      Logger.error(message, 'API', error);
}

class CameraLogger {
  static void info(String message) => Logger.info(message, 'CAMERA');
  static void error(String message, [Object? error]) => Logger.error(message, 'CAMERA', error);
  static void debug(String message) => Logger.debug(message, 'CAMERA');
}

class PythonLogger {
  static void info(String message) => Logger.info(message, 'PYTHON');
  static void error(String message, [Object? error]) => Logger.error(message, 'PYTHON', error);
  static void debug(String message) => Logger.debug(message, 'PYTHON');
}