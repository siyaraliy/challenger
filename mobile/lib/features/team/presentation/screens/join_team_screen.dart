import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/models/team_invitation.dart';
import '../../data/repositories/invitation_repository.dart';

/// Screen for joining a team using an invite code
class JoinTeamScreen extends StatefulWidget {
  final String? initialCode;

  const JoinTeamScreen({super.key, this.initialCode});

  @override
  State<JoinTeamScreen> createState() => _JoinTeamScreenState();
}

class _JoinTeamScreenState extends State<JoinTeamScreen> {
  final InvitationRepository _invitationRepo = getIt<InvitationRepository>();
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  TeamInvitation? _invitation;
  bool _isLoading = false;
  bool _isJoining = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialCode != null) {
      _codeController.text = widget.initialCode!;
      _lookupCode();
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _lookupCode() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.length != 8) {
      setState(() {
        _error = 'Davet kodu 8 karakter olmalıdır';
        _invitation = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _invitation = null;
    });

    try {
      final invitation = await _invitationRepo.getInvitationByCode(code);
      
      if (invitation == null) {
        setState(() {
          _error = 'Davet kodu bulunamadı';
        });
      } else if (invitation.status != InvitationStatus.pending) {
        setState(() {
          _error = 'Bu davet kodu artık geçerli değil (${invitation.status.displayName})';
        });
      } else if (invitation.isExpired) {
        setState(() {
          _error = 'Bu davet kodunun süresi dolmuş';
        });
      } else {
        setState(() {
          _invitation = invitation;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _joinTeam() async {
    if (_invitation == null) return;

    setState(() {
      _isJoining = true;
      _error = null;
    });

    try {
      final team = await _invitationRepo.acceptInvitation(_invitation!.inviteCode);
      
      if (mounted) {
        // Show success dialog
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[400], size: 28),
                const SizedBox(width: 12),
                const Text('Hoş Geldin!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (team.logoUrl != null)
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: NetworkImage(team.logoUrl!),
                  )
                else
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: const Icon(Icons.shield, size: 40, color: Colors.white),
                  ),
                const SizedBox(height: 16),
                Text(
                  'Artık ${team.name} takımının bir üyesisin!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.go('/team-home');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.black,
                ),
                child: const Text('Takıma Git'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        _isJoining = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Takıma Katıl'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.green.withValues(alpha: 0.2),
                      Colors.green.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.group_add,
                      size: 64,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Bir Takıma Katıl',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Davet kodunu girerek takıma katıl',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Code input
              Text(
                'Davet Kodu',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _codeController,
                textCapitalization: TextCapitalization.characters,
                maxLength: 8,
                style: const TextStyle(
                  fontSize: 24,
                  letterSpacing: 8,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: 'ABCD1234',
                  hintStyle: TextStyle(
                    color: Colors.grey[600],
                    letterSpacing: 8,
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  counterText: '',
                ),
                onChanged: (value) {
                  if (value.length == 8) {
                    _lookupCode();
                  } else {
                    setState(() {
                      _invitation = null;
                      _error = null;
                    });
                  }
                },
              ),

              const SizedBox(height: 16),

              // Lookup button
              if (_invitation == null && !_isLoading)
                OutlinedButton.icon(
                  onPressed: _codeController.text.length == 8 ? _lookupCode : null,
                  icon: const Icon(Icons.search),
                  label: const Text('Kodu Ara'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),

              // Loading
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),

              // Error
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Team preview
              if (_invitation != null && _invitation!.team != null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Team logo
                      if (_invitation!.team!.logoUrl != null)
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: NetworkImage(_invitation!.team!.logoUrl!),
                        )
                      else
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: theme.colorScheme.primary,
                          child: const Icon(Icons.shield, size: 40, color: Colors.white),
                        ),
                      const SizedBox(height: 16),
                      
                      // Team name
                      Text(
                        _invitation!.team!.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Expiry info
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _invitation!.remainingTime,
                          style: const TextStyle(color: Colors.green, fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Join button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: _isJoining ? null : _joinTeam,
                          icon: _isJoining
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.login),
                          label: Text(_isJoining ? 'Katılıyor...' : 'Takıma Katıl'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Help text
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.help_outline, color: Colors.grey[400], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Davet kodu nasıl alınır?',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Takım kaptanından 8 karakterlik bir davet kodu iste. '
                      'Kodu yukarıya girerek takıma katılabilirsin.',
                      style: TextStyle(color: Colors.grey[500], fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
