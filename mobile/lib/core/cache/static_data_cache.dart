import 'package:hive_flutter/hive_flutter.dart';
import 'package:mobile/core/models/static_data_model.dart';

class StaticDataCache {
  static const String _positionsBox = 'positions_box';
  static const String _matchTypesBox = 'match_types_box';
  static const String _reportReasonsBox = 'report_reasons_box';

  // Initialize all boxes
  Future<void> init() async {
    await Hive.openBox<Position>(_positionsBox);
    await Hive.openBox<MatchType>(_matchTypesBox);
    await Hive.openBox<ReportReason>(_reportReasonsBox);
  }

  // Positions
  Future<void> cachePositions(List<Position> positions) async {
    final box = Hive.box<Position>(_positionsBox);
    await box.clear();
    for (var position in positions) {
      await box.put(position.id, position);
    }
  }

  List<Position> getPositions() {
    final box = Hive.box<Position>(_positionsBox);
    return box.values.toList();
  }

  Position? getPositionById(String id) {
    final box = Hive.box<Position>(_positionsBox);
    return box.get(id);
  }

  bool hasPositions() {
    final box = Hive.box<Position>(_positionsBox);
    return box.isNotEmpty;
  }

  // Match Types
  Future<void> cacheMatchTypes(List<MatchType> matchTypes) async {
    final box = Hive.box<MatchType>(_matchTypesBox);
    await box.clear();
    for (var matchType in matchTypes) {
      await box.put(matchType.id, matchType);
    }
  }

  List<MatchType> getMatchTypes() {
    final box = Hive.box<MatchType>(_matchTypesBox);
    return box.values.toList();
  }

  MatchType? getMatchTypeById(String id) {
    final box = Hive.box<MatchType>(_matchTypesBox);
    return box.get(id);
  }

  bool hasMatchTypes() {
    final box = Hive.box<MatchType>(_matchTypesBox);
    return box.isNotEmpty;
  }

  // Report Reasons
  Future<void> cacheReportReasons(List<ReportReason> reportReasons) async {
    final box = Hive.box<ReportReason>(_reportReasonsBox);
    await box.clear();
    for (var reason in reportReasons) {
      await box.put(reason.id, reason);
    }
  }

  List<ReportReason> getReportReasons() {
    final box = Hive.box<ReportReason>(_reportReasonsBox);
    return box.values.toList();
  }

  ReportReason? getReportReasonById(String id) {
    final box = Hive.box<ReportReason>(_reportReasonsBox);
    return box.get(id);
  }

  bool hasReportReasons() {
    final box = Hive.box<ReportReason>(_reportReasonsBox);
    return box.isNotEmpty;
  }

  // Check if all static data is cached
  bool hasAllStaticData() {
    return hasPositions() && hasMatchTypes() && hasReportReasons();
  }

  // Clear all static data
  Future<void> clearAll() async {
    await Hive.box<Position>(_positionsBox).clear();
    await Hive.box<MatchType>(_matchTypesBox).clear();
    await Hive.box<ReportReason>(_reportReasonsBox).clear();
  }
}
