import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../cubit/mode_cubit.dart';
import '../models/app_mode_state.dart';
import '../di/service_locator.dart';
import '../../features/auth/data/repositories/supabase_auth_repository.dart';

class ModeSwitcherButton extends StatelessWidget {
  const ModeSwitcherButton({super.key});

  Future<void> _handleSwitch(BuildContext context, AppModeState state) async {
    final modeCubit = context.read<ModeCubit>();
    
    if (state.isUserMode) {
      // Show team login dialog
      final result = await showDialog<Map<String, String>>(
        context: context,
        builder: (context) => const TeamLoginDialog(),
      );

      if (result == null) return; // User cancelled

      // Store references before async operations
      final navigator = Navigator.of(context, rootNavigator: true);
      final router = GoRouter.of(context);

      try {
        // Show loading with rootNavigator to avoid context issues
        showDialog(
          context: context,
          barrierDismissible: false,
          useRootNavigator: true,
          builder: (dialogContext) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        final authRepo = getIt<SupabaseAuthRepository>();
        final teamAuthResult = await authRepo.teamLogin(
          result['email']!,
          result['password']!,
        );

        // Close loading dialog
        navigator.pop();

        // Switch to team mode and navigate
        modeCubit.switchToTeam(
          teamAuthResult.team.id,
          teamAuthResult.team.name,
        );
        
        // Small delay to ensure state is updated
        await Future.delayed(const Duration(milliseconds: 100));
        router.go('/team-home');
      } catch (e) {
        // Try to close loading dialog if it's open
        try {
          navigator.pop();
        } catch (_) {}
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Giriş hatası: ${e.toString()}')),
          );
        }
      }
    } else {
      // Switch to user mode
      final router = GoRouter.of(context);
      
      try {
        final authRepo = getIt<SupabaseAuthRepository>();
        await authRepo.teamLogout();
      } catch (e) {
        // Continue even if logout API fails
        print('Team logout error (continuing anyway): $e');
      }
      
      modeCubit.switchToUser();
      
      // Small delay to ensure state is updated
      await Future.delayed(const Duration(milliseconds: 100));
      router.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ModeCubit, AppModeState>(
      builder: (context, state) {
        return IconButton(
          icon: Icon(
            state.isUserMode ? Icons.person : Icons.shield,
            color: state.isTeamMode ? Theme.of(context).colorScheme.primary : null,
          ),
          tooltip: state.isUserMode ? 'Takım Moduna Geç' : 'Kullanıcı Moduna Geç',
          onPressed: () => _handleSwitch(context, state),
        );
      },
    );
  }
}

class TeamLoginDialog extends StatefulWidget {
  const TeamLoginDialog({super.key});

  @override
  State<TeamLoginDialog> createState() => _TeamLoginDialogState();
}

class _TeamLoginDialogState extends State<TeamLoginDialog> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Takım Girişi'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Takım Email',
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Email gerekli';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Şifre',
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Şifre gerekli';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'email': _emailController.text,
                'password': _passwordController.text,
              });
            }
          },
          child: const Text('Giriş Yap'),
        ),
      ],
    );
  }
}
