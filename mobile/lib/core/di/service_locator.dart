import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/data/repositories/mock_auth_repository.dart';
import '../../features/auth/data/repositories/supabase_auth_repository.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/profile/data/repositories/profile_repository.dart';
import '../../features/team/data/repositories/team_repository.dart';

final getIt = GetIt.instance;

Future<void> init() async {
  // External
  
  // Data sources
  
  // Repositories
  // Use SupabaseAuthRepository if configured, otherwise fallback to Mock
  if (SupabaseConfig.isConfigured) {
    final supabaseClient = Supabase.instance.client;
    
    getIt.registerLazySingleton<AuthRepository>(
      () => SupabaseAuthRepository(supabaseClient),
    );
    
    // Profile Repository
    getIt.registerLazySingleton<ProfileRepository>(
      () => ProfileRepository(supabaseClient),
    );
    
    // Team Repository
    getIt.registerLazySingleton<TeamRepository>(
      () => TeamRepository(supabaseClient),
    );
  } else {
    getIt.registerLazySingleton<AuthRepository>(() => MockAuthRepository());
  }
  
  // Blocs
  getIt.registerLazySingleton(() => AuthBloc(authRepository: getIt()));
}
