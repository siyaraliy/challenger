import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/leaderboard_repository.dart';

// Events
abstract class LeaderboardEvent extends Equatable {
  const LeaderboardEvent();

  @override
  List<Object?> get props => [];
}

class LoadLeaderboard extends LeaderboardEvent {
  final int limit;

  const LoadLeaderboard({this.limit = 50});

  @override
  List<Object?> get props => [limit];
}

class RefreshLeaderboard extends LeaderboardEvent {
  const RefreshLeaderboard();
}

// States
abstract class LeaderboardState extends Equatable {
  const LeaderboardState();

  @override
  List<Object?> get props => [];
}

class LeaderboardInitial extends LeaderboardState {}

class LeaderboardLoading extends LeaderboardState {}

class LeaderboardLoaded extends LeaderboardState {
  final List<TeamRanking> rankings;

  const LeaderboardLoaded(this.rankings);

  @override
  List<Object?> get props => [rankings];
}

class LeaderboardError extends LeaderboardState {
  final String message;

  const LeaderboardError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class LeaderboardBloc extends Bloc<LeaderboardEvent, LeaderboardState> {
  final LeaderboardRepository _repository;

  LeaderboardBloc(this._repository) : super(LeaderboardInitial()) {
    on<LoadLeaderboard>(_onLoadLeaderboard);
    on<RefreshLeaderboard>(_onRefreshLeaderboard);
  }

  Future<void> _onLoadLeaderboard(
    LoadLeaderboard event,
    Emitter<LeaderboardState> emit,
  ) async {
    emit(LeaderboardLoading());
    try {
      final rankings = await _repository.getTeamLeaderboard(limit: event.limit);
      emit(LeaderboardLoaded(rankings));
    } catch (e) {
      emit(LeaderboardError(e.toString()));
    }
  }

  Future<void> _onRefreshLeaderboard(
    RefreshLeaderboard event,
    Emitter<LeaderboardState> emit,
  ) async {
    try {
      final rankings = await _repository.getTeamLeaderboard();
      emit(LeaderboardLoaded(rankings));
    } catch (e) {
      emit(LeaderboardError(e.toString()));
    }
  }
}
