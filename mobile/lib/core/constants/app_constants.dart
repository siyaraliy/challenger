class AppConstants {
  // Position constants (fallback if cache is empty)
  static const List<Map<String, String>> positions = [
    {'id': 'goalkeeper', 'name': 'Kaleci', 'abbreviation': 'KL'},
    {'id': 'defender', 'name': 'Defans', 'abbreviation': 'DF'},
    {'id': 'midfielder', 'name': 'Orta Saha', 'abbreviation': 'OS'},
    {'id': 'forward', 'name': 'Forvet', 'abbreviation': 'FW'},
  ];

  static List<String> get positionNames => positions.map((p) => p['name']!).toList();
  
  static String? getPositionId(String name) {
    final position = positions.firstWhere(
      (p) => p['name'] == name,
      orElse: () => {'id': ''},
    );
    return position['id'];
  }
  
  static String? getPositionName(String id) {
    final position = positions.firstWhere(
      (p) => p['id'] == id,
      orElse: () => {'name': ''},
    );
    return position['name'];
  }
}
