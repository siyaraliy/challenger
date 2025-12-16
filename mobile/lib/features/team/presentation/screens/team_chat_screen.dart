import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/cubit/mode_cubit.dart';
import '../../../../core/models/app_mode_state.dart';
import '../../../../core/di/service_locator.dart';
import '../../../chat/data/chat_repository.dart';
import '../../../chat/presentation/bloc/chat_room_bloc.dart';
import '../../../chat/presentation/screens/chat_room_screen.dart';

class TeamChatScreen extends StatefulWidget {
  const TeamChatScreen({super.key});

  @override
  State<TeamChatScreen> createState() => _TeamChatScreenState();
}

class _TeamChatScreenState extends State<TeamChatScreen> {
  String? _roomId;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTeamChatRoom();
  }

  Future<void> _loadTeamChatRoom() async {
    print('DEBUG: _loadTeamChatRoom called');
    try {
      final modeState = context.read<ModeCubit>().state;
      print('DEBUG: isTeamMode=${modeState.isTeamMode}, teamId=${modeState.teamId}');
      
      if (modeState.isTeamMode && modeState.teamId != null) {
        final teamId = modeState.teamId!;
        print('DEBUG: Getting chat room for teamId: $teamId');
        
        final chatRepository = getIt<ChatRepository>();
        final roomId = await chatRepository.getTeamChatRoom(teamId);
        
        print('DEBUG: Got roomId: $roomId');
        
        if (mounted) {
          if (roomId != null) {
            setState(() {
              _roomId = roomId;
              _isLoading = false;
            });
          } else {
            setState(() {
              _error = 'Sohbet odası oluşturulamadı. Lütfen tekrar deneyin.';
              _isLoading = false;
            });
          }
        }
      } else {
        print('DEBUG: Not in team mode or no teamId');
        setState(() {
          _error = 'Takım modu aktif değil';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('DEBUG: _loadTeamChatRoom error: $e');
      if (mounted) {
        setState(() {
          _error = 'Sohbet odası yüklenemedi: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Takım Sohbeti'),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _roomId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Takım Sohbeti'),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 80,
                color: Colors.grey[600],
              ),
              const SizedBox(height: 24),
              Text(
                _error ?? 'Sohbet odası bulunamadı',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() => _isLoading = true);
                  _loadTeamChatRoom();
                },
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      );
    }

    final modeState = context.read<ModeCubit>().state;
    final teamId = modeState.teamId;

    return BlocProvider(
      create: (context) => ChatRoomBloc(getIt<ChatRepository>())
        ..add(LoadChatRoom(
          _roomId!,
          contextType: 'team',
          contextId: teamId,
        )),
      child: BlocBuilder<ModeCubit, AppModeState>(
        builder: (context, modeState) {
          return ChatRoomScreen(
            roomId: _roomId!,
            roomName: modeState.teamName != null 
                ? '${modeState.teamName} Sohbeti' 
                : 'Takım Sohbeti',
            contextType: 'team',
            contextId: modeState.teamId,
          );
        },
      ),
    );
  }
}

