import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';

// DÜZELTİLEN KISIM:
// Relative path (örn: 'core/...') yerine package path kullanıldı.
// Proje adınız pubspec.yaml'da 'mobile' olduğu için 'package:mobile/...' yapısı şarttır.
import 'package:mobile/core/router/app_router.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/di/service_locator.dart' as di;
import 'package:mobile/core/bloc/app_bloc_observer.dart';
import 'package:mobile/features/auth/presentation/bloc/auth_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Initialize Dependency Injection
  await di.init();
  
  // Initialize Bloc Observer
  Bloc.observer = AppBlocObserver();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => di.getIt<AuthBloc>()..add(AuthCheckRequested()),
        ),
      ],
      child: const ChallengerApp(),
    ),
  );
}

class ChallengerApp extends StatelessWidget {
  const ChallengerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Challenger',
      theme: AppTheme.darkTheme,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}