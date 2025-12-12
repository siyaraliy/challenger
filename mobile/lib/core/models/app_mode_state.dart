import 'package:equatable/equatable.dart';

enum AppMode { user, team }

class AppModeState extends Equatable {
  final AppMode mode;
  final String? teamId;
  final String? teamName;

  const AppModeState({
    required this.mode,
    this.teamId,
    this.teamName,
  });

  const AppModeState.user()
      : mode = AppMode.user,
        teamId = null,
        teamName = null;

  AppModeState.team({
    required String teamId,
    required String teamName,
  })  : mode = AppMode.team,
        teamId = teamId,
        teamName = teamName;

  bool get isTeamMode => mode == AppMode.team;
  bool get isUserMode => mode == AppMode.user;

  AppModeState copyWith({
    AppMode? mode,
    String? teamId,
    String? teamName,
  }) {
    return AppModeState(
      mode: mode ?? this.mode,
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
    );
  }

  @override
  List<Object?> get props => [mode, teamId, teamName];
}
