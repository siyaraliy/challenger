import 'package:get_it/get_it.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/data/repositories/mock_auth_repository.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';

final getIt = GetIt.instance;

Future<void> init() async {
  // External
  
  // Data sources
  
  // Repositories
  getIt.registerLazySingleton<AuthRepository>(() => MockAuthRepository());
  
  // Blocs
  getIt.registerFactory(() => AuthBloc(authRepository: getIt()));
}
