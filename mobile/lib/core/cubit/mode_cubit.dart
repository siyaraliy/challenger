import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/app_mode_state.dart';

class ModeCubit extends Cubit<AppModeState> {
  static const String _boxName = 'mode_box';
  static const String _modeKey = 'current_mode';
  static const String _teamIdKey = 'team_id';
  static const String _teamNameKey = 'team_name';

  ModeCubit() : super(const AppModeState.user());

  /// Load saved mode from Hive
  Future<void> loadSavedMode() async {
    try {
      final box = await Hive.openBox(_boxName);
      final modeString = box.get(_modeKey, defaultValue: 'user') as String;
      
      if (modeString == 'team') {
        final teamId = box.get(_teamIdKey) as String?;
        final teamName = box.get(_teamNameKey) as String?;
        
        if (teamId != null && teamName != null) {
          emit(AppModeState.team(teamId: teamId, teamName: teamName));
          return;
        }
      }
      
      emit(const AppModeState.user());
    } catch (e) {
      // If error, default to user mode
      emit(const AppModeState.user());
    }
  }

  /// Switch to user mode
  Future<void> switchToUser() async {
    emit(const AppModeState.user());
    await _persistMode();
  }

  /// Switch to team mode
  Future<void> switchToTeam(String teamId, String teamName) async {
    emit(AppModeState.team(teamId: teamId, teamName: teamName));
    await _persistMode();
  }

  /// Persist current mode to Hive
  Future<void> _persistMode() async {
    try {
      final box = await Hive.openBox(_boxName);
      
      if (state.isTeamMode) {
        await box.put(_modeKey, 'team');
        await box.put(_teamIdKey, state.teamId);
        await box.put(_teamNameKey, state.teamName);
      } else {
        await box.put(_modeKey, 'user');
        await box.delete(_teamIdKey);
        await box.delete(_teamNameKey);
      }
    } catch (e) {
      // Silently fail - mode will reset on restart
    }
  }

  @override
  Future<void> close() async {
    final box = await Hive.openBox(_boxName);
    await box.close();
    return super.close();
  }
}
