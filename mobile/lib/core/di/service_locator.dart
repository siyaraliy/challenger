import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../../core/cubit/mode_cubit.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/data/repositories/mock_auth_repository.dart';
import '../../features/auth/data/repositories/supabase_auth_repository.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/profile/data/repositories/profile_repository.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';
import '../../features/team/data/repositories/team_repository.dart';

final getIt = GetIt.instance;

Future<void> init() async {
  // Core Services (always available)
  getIt.registerLazySingleton(() => ModeCubit());
  
  // External
  
  // Data sources
  
  // Repositories
  // Use SupabaseAuthRepository if configured, otherwise fallback to Mock
  if (SupabaseConfig.isConfigured) {
    final supabaseClient = Supabase.instance.client;
    
    // Register as both interface and concrete type
    final authRepo = SupabaseAuthRepository(supabaseClient);
    getIt.registerLazySingleton<AuthRepository>(() => authRepo);
    getIt.registerLazySingleton<SupabaseAuthRepository>(() => authRepo);
    
    // Profile Repository
    getIt.registerLazySingleton<ProfileRepository>(
      () => ProfileRepository(supabaseClient),
    );
    
    // Team Repository
    getIt.registerLazySingleton<TeamRepository>(
      () => TeamRepository(supabaseClient),
    );
    
    // Blocs (Supabase-dependent)
    getIt.registerFactory(() => ProfileBloc(getIt<ProfileRepository>()));
  } else {
    getIt.registerLazySingleton<AuthRepository>(() => MockAuthRepository());
  }
  
  // Blocs (Always available)
  getIt.registerLazySingleton(() => AuthBloc(authRepository: getIt()));
}
