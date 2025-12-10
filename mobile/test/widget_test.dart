// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mobile/core/di/service_locator.dart';
import 'package:mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:mobile/main.dart';
import 'package:mocktail/mocktail.dart';

// Mock dependencies
class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  setUpAll(() {
    // Register dependencies for testing
    final getIt = GetIt.instance;
    getIt.registerLazySingleton<AuthRepository>(() => MockAuthRepository());
    getIt.registerFactory(() => AuthBloc(authRepository: getIt()));
  });

  testWidgets('App starts at Login Screen', (WidgetTester tester) async {
    // Provide the Bloc directly since main.dart does it in runApp not inside ChallengerApp
    // Wait, ChallengerApp is just MaterialApp.router.
    // But main.dart wraps it in MultiBlocProvider.
    // So we need to wrap it here too.

    final authBloc = AuthBloc(authRepository: GetIt.I<AuthRepository>());
    authBloc.add(AuthCheckRequested()); // Initialize state

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: authBloc),
        ],
        child: const ChallengerApp(),
      ),
    );

    // Initial navigation might take a frame
    await tester.pumpAndSettle();

    // Verify we are on Login Screen
    expect(find.text('GİRİŞ YAP'), findsOneWidget);
    expect(find.text('CHALLENGER'), findsOneWidget);
  });
}
