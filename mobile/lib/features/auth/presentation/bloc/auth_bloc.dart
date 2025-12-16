import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User;
import 'package:supabase_flutter/supabase_flutter.dart' as supabase show AuthState;
import '../../domain/repositories/auth_repository.dart';
import '../../data/repositories/supabase_auth_repository.dart';

// Events
abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;
  const AuthLoginRequested(this.email, this.password);
  @override
  List<Object> get props => [email, password];
}

class AuthRegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String fullName;
  const AuthRegisterRequested(this.email, this.password, this.fullName);
  @override
  List<Object> get props => [email, password, fullName];
}

class AuthGuestLoginRequested extends AuthEvent {}

class AuthLogoutRequested extends AuthEvent {}

class AuthStateChanged extends AuthEvent {
  final AuthState authState;
  const AuthStateChanged(this.authState);
  @override
  List<Object> get props => [authState];
}

// States
abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final User user;
  const AuthAuthenticated(this.user);
  @override
  List<Object?> get props => [user.id];
}

class AuthGuest extends AuthState {
  final User? user;
  const AuthGuest([this.user]);
  @override
  List<Object?> get props => [user?.id];
}

class Unauthenticated extends AuthState {}

class AuthFailure extends AuthState {
  final String message;
  const AuthFailure(this.message);
  @override
  List<Object?> get props => [message];
}

// Bloc
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  StreamSubscription<supabase.AuthState>? _authStateSubscription;

  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthGuestLoginRequested>(_onGuestLoginRequested);
    on<AuthStateChanged>(_onAuthStateChanged);

    // Listen to Supabase auth state changes (if using SupabaseAuthRepository)
    if (_authRepository is SupabaseAuthRepository) {
      _initAuthStateListener();
    }
  }

  void _initAuthStateListener() {
    final supabaseRepo = _authRepository as SupabaseAuthRepository;
    _authStateSubscription = supabaseRepo.authStateChanges.listen((authState) {
      final session = authState.session;
      final user = session?.user;

      if (user != null) {
        if (user.isAnonymous) {
          add(AuthStateChanged(AuthGuest(user)));
        } else {
          add(AuthStateChanged(AuthAuthenticated(user)));
        }
      } else {
        add(AuthStateChanged(Unauthenticated()));
      }
    });
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final isAuthenticated = await _authRepository.isAuthenticated();
      if (isAuthenticated) {
        // Try to get Supabase user if available
        if (_authRepository is SupabaseAuthRepository) {
          final supabaseRepo = _authRepository as SupabaseAuthRepository;
          final user = supabaseRepo.currentUser;
          
          if (user != null) {
            if (user.isAnonymous) {
              emit(AuthGuest(user));
            } else {
              emit(AuthAuthenticated(user));
            }
          } else {
            emit(Unauthenticated());
          }
        } else {
          // Fallback for MockAuthRepository
          emit(Unauthenticated());
        }
      } else {
        emit(Unauthenticated());
      }
    } catch (e) {
      emit(AuthFailure('Oturum kontrolü başarısız: ${e.toString()}'));
      emit(Unauthenticated());
    }
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _authRepository.login(event.email, event.password);
      
      // Get user info
      if (_authRepository is SupabaseAuthRepository) {
        final supabaseRepo = _authRepository as SupabaseAuthRepository;
        final user = supabaseRepo.currentUser;
        if (user != null) {
          emit(AuthAuthenticated(user));
        } else {
          emit(AuthFailure('Kullanıcı bilgisi alınamadı'));
        }
      }
    } catch (e) {
      emit(AuthFailure(e.toString()));
      emit(Unauthenticated());
    }
  }

  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _authRepository.register(event.email, event.password, event.fullName);
      
      // Get user info
      if (_authRepository is SupabaseAuthRepository) {
        final supabaseRepo = _authRepository as SupabaseAuthRepository;
        final user = supabaseRepo.currentUser;
        if (user != null) {
          emit(AuthAuthenticated(user));
        } else {
          emit(AuthFailure('Kullanıcı bilgisi alınamadı'));
        }
      }
    } catch (e) {
      emit(AuthFailure(e.toString()));
      emit(Unauthenticated());
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _authRepository.logout();
      emit(Unauthenticated());
    } catch (e) {
      emit(AuthFailure('Çıkış başarısız: ${e.toString()}'));
    }
  }

  Future<void> _onGuestLoginRequested(
    AuthGuestLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _authRepository.loginAsGuest();
      
      // Get anonymous user info
      if (_authRepository is SupabaseAuthRepository) {
        final supabaseRepo = _authRepository as SupabaseAuthRepository;
        final user = supabaseRepo.currentUser;
        if (user != null) {
          emit(AuthGuest(user));
        } else {
          emit(AuthFailure('Misafir girişi başarısız'));
        }
      } else {
        // Fallback for MockAuthRepository
        emit(AuthGuest());
      }
    } catch (e) {
      emit(AuthFailure(e.toString()));
      emit(Unauthenticated());
    }
  }

  void _onAuthStateChanged(
    AuthStateChanged event,
    Emitter<AuthState> emit,
  ) {
    emit(event.authState);
  }

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    return super.close();
  }
}
