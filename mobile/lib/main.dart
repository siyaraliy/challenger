import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:mobile/core/router/app_router.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/di/service_locator.dart' as di;
import 'package:mobile/core/bloc/app_bloc_observer.dart';
import 'package:mobile/core/config/supabase_config.dart';
import 'package:mobile/core/cache/static_data_cache.dart';
import 'package:mobile/core/models/static_data_model.dart';
import 'package:mobile/features/auth/presentation/bloc/auth_bloc.dart';

import 'package:mobile/core/cubit/mode_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive Adapters for Static Data
  Hive.registerAdapter(PositionAdapter());
  Hive.registerAdapter(MatchTypeAdapter());
  Hive.registerAdapter(ReportReasonAdapter());

  // Initialize Static Data Cache
  final staticDataCache = StaticDataCache();
  await staticDataCache.init();

  // Initialize Supabase (if configured)
  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
    debugPrint('✅ Supabase initialized successfully');
  } else {
    debugPrint('⚠️ Supabase not configured. Running in offline mode.');
  }

  // Initialize Dependency Injection
  await di.init();

  // Initialize Bloc Observer
  Bloc.observer = AppBlocObserver();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => di.getIt<AuthBloc>(),
        ),
        BlocProvider(
          create: (context) => di.getIt<ModeCubit>(),
        ),
      ],
      child: const ChallengerApp(),
    ),
  );
}

class ChallengerApp extends StatefulWidget {
  const ChallengerApp({super.key});

  @override
  State<ChallengerApp> createState() => _ChallengerAppState();
}

class _ChallengerAppState extends State<ChallengerApp> {
  @override
  void initState() {
    super.initState();
    // Load saved mode after widget tree is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ModeCubit>().loadSavedMode();
    });
  }

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