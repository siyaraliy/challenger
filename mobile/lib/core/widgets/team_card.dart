import 'package:flutter/material.dart';

class TeamCard extends StatelessWidget {
  final String teamName;
  final String rank;
  final String imageUrl;
  final VoidCallback onChallenge;

  const TeamCard({
    super.key,
    required this.teamName,
    required this.rank,
    required this.imageUrl,
    required this.onChallenge,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.grey,
            child: Icon(Icons.shield, size: 30, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(
            teamName,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            rank,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onChallenge,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            ),
            child: const Text('Meydan Oku', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
