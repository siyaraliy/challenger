import 'package:flutter/material.dart';
import '../../../../core/models/challenge.dart';

class ChallengeCard extends StatelessWidget {
  final Challenge challenge;
  final bool isIncoming; // true = gelen, false = gönderilen
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onComplete;
  final VoidCallback? onCancel;
  final VoidCallback? onTap;

  const ChallengeCard({
    super.key,
    required this.challenge,
    required this.isIncoming,
    this.onAccept,
    this.onReject,
    this.onComplete,
    this.onCancel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final otherTeamName = isIncoming 
        ? challenge.challengerTeamName ?? 'Bilinmeyen Takım'
        : challenge.challengedTeamName ?? 'Bilinmeyen Takım';
    final otherTeamLogo = isIncoming
        ? challenge.challengerTeamLogo
        : challenge.challengedTeamLogo;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _getStatusColor(challenge.status).withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Team info + Status
            Row(
              children: [
                // Team Avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  ),
                  child: otherTeamLogo != null
                      ? ClipOval(
                          child: Image.network(otherTeamLogo, fit: BoxFit.cover),
                        )
                      : Icon(Icons.shield, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 12),
                // Team name and time
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        otherTeamName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        challenge.timeAgo,
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(challenge.status).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _getStatusColor(challenge.status)),
                  ),
                  child: Text(
                    challenge.statusText,
                    style: TextStyle(
                      color: _getStatusColor(challenge.status),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            // Match details
            if (challenge.matchDate != null || challenge.location != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    if (challenge.matchDate != null)
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 16, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            challenge.formattedMatchDate,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    if (challenge.location != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 16, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              challenge.location!,
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],

            // Message
            if (challenge.message != null && challenge.message!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                '"${challenge.message}"',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],

            // Points awarded (if completed)
            if (challenge.status == ChallengeStatus.completed && challenge.pointsAwarded > 0) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.emoji_events, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '+${challenge.pointsAwarded} Puan',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],

            // Action buttons
            if (challenge.status == ChallengeStatus.pending ||
                challenge.status == ChallengeStatus.accepted) ...[
              const SizedBox(height: 16),
              _buildActionButtons(theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    if (challenge.status == ChallengeStatus.pending) {
      if (isIncoming) {
        // Incoming pending: Accept / Reject
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onReject,
                icon: const Icon(Icons.close, size: 18),
                label: const Text('Reddet'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onAccept,
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Kabul Et'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        );
      } else {
        // Outgoing pending: Cancel
        return SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onCancel,
            icon: const Icon(Icons.cancel_outlined, size: 18),
            label: const Text('İptal Et'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orange,
              side: const BorderSide(color: Colors.orange),
            ),
          ),
        );
      }
    } else if (challenge.status == ChallengeStatus.accepted) {
      // Accepted: Complete match
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onComplete,
          icon: const Icon(Icons.sports_score, size: 18),
          label: const Text('Maçı Tamamla'),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.black,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Color _getStatusColor(ChallengeStatus status) {
    switch (status) {
      case ChallengeStatus.pending:
        return Colors.orange;
      case ChallengeStatus.accepted:
        return Colors.blue;
      case ChallengeStatus.rejected:
        return Colors.red;
      case ChallengeStatus.completed:
        return Colors.green;
      case ChallengeStatus.cancelled:
        return Colors.grey;
    }
  }
}
