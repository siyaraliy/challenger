import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/di/service_locator.dart';
import '../cubit/mode_cubit.dart';
import '../models/app_mode_state.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/home/presentation/screens/create_post_screen.dart';
import '../../features/discover/presentation/screens/discover_screen.dart';
import '../../features/ranking/presentation/screens/ranking_screen.dart';
import '../../features/chat/presentation/screens/chat_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/team/presentation/screens/create_team_screen.dart';
import '../../features/team/presentation/screens/team_detail_screen.dart';
import '../../features/team/presentation/screens/team_home_screen.dart';
import '../../features/team/presentation/screens/team_matches_screen.dart';
import '../../features/team/presentation/screens/team_squad_screen.dart';
import '../../features/team/presentation/screens/team_chat_screen.dart';
import '../../features/team/presentation/screens/team_settings_screen.dart';
import '../../features/team/presentation/screens/team_profile_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

// ... (Other imports remain, ensure they are compatible)

class AppRouter {
  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    refreshListenable: _GoRouterRefreshStream(getIt<AuthBloc>().stream),
    redirect: (context, state) {
      final authState = getIt<AuthBloc>().state;
      final path = state.uri.path;
      
      // Both authenticated and guest users can access app
      final isAuthenticated = authState is AuthAuthenticated || authState is AuthGuest;
      final isLoggingIn = path == '/login' || path == '/register';
      final isTeamRoute = path.startsWith('/team-') || path.startsWith('/team/');

      if (!isAuthenticated && !isLoggingIn) {
        return '/login';
      }

      // Don't redirect if already on a team route
      if (isAuthenticated && isLoggingIn && !isTeamRoute) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      // Create Post (outside shell for fullscreen)
      GoRoute(
        path: '/create-post',
        builder: (context, state) => const CreatePostScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return ScaffoldWithNavBar(child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/discover',
            builder: (context, state) => const DiscoverScreen(),
          ),
          GoRoute(
            path: '/ranking',
            builder: (context, state) => const RankingScreen(),
          ),
          GoRoute(
            path: '/chat',
            builder: (context, state) => const ChatScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => BlocProvider(
              create: (context) => getIt<ProfileBloc>(),
              child: const ProfileScreen(),
            ),
          ),
          GoRoute(
            path: '/create-team',
            builder: (context, state) => const CreateTeamScreen(),
          ),
          GoRoute(
            path: '/team/:teamId',
            builder: (context, state) {
              final teamId = state.pathParameters['teamId']!;
              return TeamDetailScreen(teamId: teamId);
            },
          ),
          // TEAM MODE ROUTES
          GoRoute(
            path: '/team-home',
            builder: (context, state) => const TeamHomeScreen(),
          ),
          GoRoute(
            path: '/team-matches',
            builder: (context, state) => const TeamMatchesScreen(),
          ),
          GoRoute(
            path: '/team-squad',
            builder: (context, state) => const TeamSquadScreen(),
          ),
          GoRoute(
            path: '/team-chat',
            builder: (context, state) => const TeamChatScreen(),
          ),
          GoRoute(
            path: '/team-settings',
            builder: (context, state) => const TeamSettingsScreen(),
          ),
          GoRoute(
            path: '/team-profile',
            builder: (context, state) => const TeamProfileScreen(),
          ),
        ],
      ),
    ],
  );
}

// Convert Stream to Listenable for GoRouter
class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final dynamic _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class ScaffoldWithNavBar extends StatelessWidget {
  final Widget child;

  const ScaffoldWithNavBar({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ModeCubit, AppModeState>(
      builder: (context, modeState) {
        return Scaffold(
          body: child,
          bottomNavigationBar: _buildBottomNav(context, modeState),
        );
      },
    );
  }

  Widget _buildBottomNav(BuildContext context, AppModeState modeState) {
    if (modeState.isUserMode) {
      return BottomNavigationBar(
        currentIndex: _calculateSelectedIndexUser(context),
        onTap: (int idx) => _onUserItemTapped(idx, context),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Anasayfa'),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Keşfet'),
          BottomNavigationBarItem(icon: Icon(Icons.leaderboard), label: 'Sıralama'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Mesajlar'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      );
    } else {
      // Team mode nav
      return BottomNavigationBar(
        currentIndex: _calculateSelectedIndexTeam(context),
        onTap: (int idx) => _onTeamItemTapped(idx, context),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Takım'),
          BottomNavigationBarItem(icon: Icon(Icons.sports_soccer), label: 'Maçlar'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Kadro'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Sohbet'),
          BottomNavigationBarItem(icon: Icon(Icons.shield_outlined), label: 'Profil'),
        ],
      );
    }
  }

  static int _calculateSelectedIndexUser(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/discover')) return 1;
    if (location.startsWith('/ranking')) return 2;
    if (location.startsWith('/chat')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  static int _calculateSelectedIndexTeam(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/team-home')) return 0;
    if (location.startsWith('/team-matches')) return 1;
    if (location.startsWith('/team-squad')) return 2;
    if (location.startsWith('/team-chat')) return 3;
    if (location.startsWith('/team-profile')) return 4;
    return 0;
  }

  void _onUserItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        GoRouter.of(context).go('/home');
        break;
      case 1:
        GoRouter.of(context).go('/discover');
        break;
      case 2:
        GoRouter.of(context).go('/ranking');
        break;
      case 3:
        GoRouter.of(context).go('/chat');
        break;
      case 4:
        GoRouter.of(context).go('/profile');
        break;
    }
  }

  void _onTeamItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        GoRouter.of(context).go('/team-home');
        break;
      case 1:
        GoRouter.of(context).go('/team-matches');
        break;
      case 2:
        GoRouter.of(context).go('/team-squad');
        break;
      case 3:
        GoRouter.of(context).go('/team-chat');
        break;
      case 4:
        GoRouter.of(context).go('/team-profile');
        break;
    }
  }
}
