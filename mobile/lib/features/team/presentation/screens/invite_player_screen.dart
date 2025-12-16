import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/models/team_invitation.dart';
import '../../data/repositories/invitation_repository.dart';

/// Screen for generating team invitation codes
class InvitePlayerScreen extends StatefulWidget {
  final String teamId;
  final String teamName;

  const InvitePlayerScreen({
    super.key,
    required this.teamId,
    required this.teamName,
  });

  @override
  State<InvitePlayerScreen> createState() => _InvitePlayerScreenState();
}

class _InvitePlayerScreenState extends State<InvitePlayerScreen> {
  final InvitationRepository _invitationRepo = getIt<InvitationRepository>();
  
  TeamInvitation? _invitation;
  bool _isLoading = false;
  String? _error;
  List<TeamInvitation> _activeInvitations = [];

  @override
  void initState() {
    super.initState();
    _loadActiveInvitations();
  }

  Future<void> _loadActiveInvitations() async {
    try {
      final invitations = await _invitationRepo.getTeamInvitations(widget.teamId);
      setState(() {
        _activeInvitations = invitations
            .where((i) => i.status == InvitationStatus.pending && !i.isExpired)
            .toList();
      });
    } catch (e) {
      // Ignore error, just don't show active invitations
    }
  }

  Future<void> _generateInvitation() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final invitation = await _invitationRepo.createInvitation(widget.teamId);
      setState(() {
        _invitation = invitation;
        _activeInvitations.insert(0, invitation);
      });
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

  void _copyCode() {
    if (_invitation != null) {
      Clipboard.setData(ClipboardData(text: _invitation!.inviteCode));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Davet kodu kopyalandı!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _shareCode() {
    if (_invitation != null) {
      final message = '${widget.teamName} takımına katılmak için davet kodun: ${_invitation!.inviteCode}\n\nChallenger uygulamasını indir ve bu kodu girerek takıma katıl!';
      Clipboard.setData(ClipboardData(text: message));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Davet mesajı kopyalandı! Şimdi paylaşabilirsin.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _cancelInvitation(TeamInvitation invitation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Daveti İptal Et'),
        content: Text('${invitation.inviteCode} kodlu daveti iptal etmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('İptal Et'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _invitationRepo.cancelInvitation(invitation.id);
        setState(() {
          _activeInvitations.removeWhere((i) => i.id == invitation.id);
          if (_invitation?.id == invitation.id) {
            _invitation = null;
          }
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Davet iptal edildi')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hata: ${e.toString()}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Oyuncu Davet Et'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.2),
                    theme.colorScheme.primary.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.person_add,
                    size: 64,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.teamName,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Takımına yeni oyuncu davet et',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Generate button or show code
            if (_invitation == null) ...[
              // Info card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Davet kodu oluştur ve arkadaşlarınla paylaş. Kod 7 gün geçerli olacak.',
                        style: TextStyle(color: Colors.grey[300], fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Generate button
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _generateInvitation,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_link),
                  label: Text(_isLoading ? 'Oluşturuluyor...' : 'Davet Kodu Oluştur'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ] else ...[
              // Show generated code
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.colorScheme.primary),
                ),
                child: Column(
                  children: [
                    Text(
                      'Davet Kodu',
                      style: TextStyle(color: Colors.grey[400], fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    SelectableText(
                      _invitation!.inviteCode,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                        letterSpacing: 8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _invitation!.remainingTime,
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _copyCode,
                            icon: const Icon(Icons.copy),
                            label: const Text('Kopyala'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _shareCode,
                            icon: const Icon(Icons.share),
                            label: const Text('Paylaş'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () => setState(() => _invitation = null),
                icon: const Icon(Icons.add),
                label: const Text('Yeni Kod Oluştur'),
              ),
            ],

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

            // Active invitations
            if (_activeInvitations.isNotEmpty) ...[
              const SizedBox(height: 32),
              Text(
                'Aktif Davetler (${_activeInvitations.length})',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              ...(_activeInvitations.map((invitation) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        invitation.inviteCode,
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        invitation.remainingTime,
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red, size: 20),
                      onPressed: () => _cancelInvitation(invitation),
                      tooltip: 'İptal Et',
                    ),
                  ],
                ),
              ))),
            ],
          ],
        ),
      ),
    );
  }
}
