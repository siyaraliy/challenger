import 'dart:io' show Platform;

class ApiConfig {
  // Backend API URL - Android emulator uses 10.0.2.2, others use localhost
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
  }
  
  // Auth endpoints
  static const String authTeamRegister = '/auth/team/register';
  static const String authTeamLogin = '/auth/team/login';
  static const String authTeamLogout = '/auth/team/logout';
  static const String authTeamSessions = '/auth/team/sessions';
}
