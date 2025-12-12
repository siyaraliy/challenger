import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/mode_cubit.dart';
import '../models/app_mode_state.dart';

class ModeSwitcherButton extends StatelessWidget {
  const ModeSwitcherButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ModeCubit, AppModeState>(
      builder: (context, state) {
        return IconButton(
          icon: Icon(
            state.isUserMode ? Icons.person : Icons.shield,
            color: state.isTeamMode ? Theme.of(context).colorScheme.primary : null,
          ),
          tooltip: state.isUserMode ? 'User Mode' : 'Team Mode',
          onPressed: () {
            // TODO: Show switch dialog
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.isUserMode 
                    ? 'User Mode Active' 
                    : 'Team Mode: ${state.teamName}',
                ),
              ),
            );
          },
        );
      },
    );
  }
}
