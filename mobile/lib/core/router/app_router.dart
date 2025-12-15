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
import '../../features/team/presentation/screens/invite_player_screen.dart';
import '../../features/team/presentation/screens/join_team_screen.dart';

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
      // Invite Player (outside shell for fullscreen)
      GoRoute(
        path: '/invite-player',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return InvitePlayerScreen(
            teamId: extra?['teamId'] ?? '',
            teamName: extra?['teamName'] ?? 'Takım',
          );
        },
      ),
      // Join Team (outside shell for fullscreen)
      GoRoute(
        path: '/join-team',
        builder: (context, state) {
          final code = state.uri.queryParameters['code'];
          return JoinTeamScreen(initialCode: code);
        },
      ),
      // Create Team (outside shell for fullscreen)
      GoRoute(
        path: '/create-team',
        builder: (context, state) => const CreateTeamScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          // USER MODE BRANCHES (0-4)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/discover',
                builder: (context, state) => const DiscoverScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/ranking',
                builder: (context, state) => const RankingScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/chat',
                builder: (context, state) => const ChatScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => BlocProvider(
                  create: (context) => getIt<ProfileBloc>(),
                  child: const ProfileScreen(),
                ),
              ),
            ],
          ),
          
          // TEAM MODE BRANCHES (5-9)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/team-home',
                builder: (context, state) => const TeamHomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/team-matches',
                builder: (context, state) => const TeamMatchesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/team-squad',
                builder: (context, state) => const TeamSquadScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/team-chat',
                builder: (context, state) => const TeamChatScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/team-profile',
                builder: (context, state) => const TeamProfileScreen(),
              ),
            ],
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
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNavBar({
    required this.navigationShell,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ModeCubit, AppModeState>(
      builder: (context, modeState) {
        return Scaffold(
          body: navigationShell,
          bottomNavigationBar: _buildBottomNav(context, modeState),
        );
      },
    );
  }

  Widget _buildBottomNav(BuildContext context, AppModeState modeState) {
    if (modeState.isUserMode) {
      // Ensure we are showing a user tab (0-4)
      final currentIndex = navigationShell.currentIndex;
      final effectiveIndex = (currentIndex >= 0 && currentIndex <= 4) ? currentIndex : 0;

      return BottomNavigationBar(
        currentIndex: effectiveIndex,
        onTap: (int idx) => _onItemTapped(idx, context),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Anasayfa'),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Keşfet'),
          BottomNavigationBarItem(icon: Icon(Icons.leaderboard), label: 'Sıralama'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Mesajlar'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      );
    } else {
      // Ensure we are showing a team tab (5-9)
      // Map global index (5-9) to local index (0-4)
      final currentIndex = navigationShell.currentIndex;
      final effectiveIndex = (currentIndex >= 5 && currentIndex <= 9) ? currentIndex - 5 : 0;
      
      return BottomNavigationBar(
        currentIndex: effectiveIndex,
        onTap: (int idx) => _onItemTapped(idx + 5, context),
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

  void _onItemTapped(int index, BuildContext context) {
    // When switching branches, use goBranch.
    // This preserves `AutomaticKeepAliveClientMixin` state.
    navigationShell.goBranch(
      index,
      // A common pattern when clicking the bottom navigation bar is to support
      // navigating to the initial location when tapping the item that is
      // already active.
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
