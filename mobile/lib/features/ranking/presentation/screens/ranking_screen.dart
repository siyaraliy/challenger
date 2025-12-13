import 'package:flutter/material.dart';

/// Team ranking data model (mock)
class TeamRankingData {
  final String id;
  final String name;
  final String? logoUrl;
  final int points;
  final int matchesPlayed;
  final int wins;
  final int losses;

  const TeamRankingData({
    required this.id,
    required this.name,
    this.logoUrl,
    required this.points,
    required this.matchesPlayed,
    required this.wins,
    required this.losses,
  });
}

/// Mock team rankings
const List<TeamRankingData> mockTeamRankings = [
  TeamRankingData(
    id: '1',
    name: 'Red Dragons FC',
    points: 450,
    matchesPlayed: 15,
    wins: 12,
    losses: 3,
  ),
  TeamRankingData(
    id: '2',
    name: 'Blue Sharks',
    points: 380,
    matchesPlayed: 14,
    wins: 10,
    losses: 4,
  ),
  TeamRankingData(
    id: '3',
    name: 'Golden Eagles',
    points: 350,
    matchesPlayed: 13,
    wins: 9,
    losses: 4,
  ),
  TeamRankingData(
    id: '4',
    name: 'Black Panthers',
    points: 320,
    matchesPlayed: 12,
    wins: 8,
    losses: 4,
  ),
  TeamRankingData(
    id: '5',
    name: 'Silver Wolves',
    points: 290,
    matchesPlayed: 11,
    wins: 7,
    losses: 4,
  ),
];

class RankingScreen extends StatelessWidget {
  const RankingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sıralama'),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: mockTeamRankings.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final team = mockTeamRankings[index];
          final rank = index + 1;

          return _buildTeamRankCard(context, theme, team, rank);
        },
      ),
    );
  }

  Widget _buildTeamRankCard(
    BuildContext context,
    ThemeData theme,
    TeamRankingData team,
    int rank,
  ) {
    Color rankColor;
    if (rank == 1) {
      rankColor = Colors.amber;
    } else if (rank == 2) {
      rankColor = Colors.grey[400]!;
    } else if (rank == 3) {
      rankColor = Colors.brown[300]!;
    } else {
      rankColor = Colors.grey[700]!;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: rank <= 3 ? rankColor.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.1),
          width: rank <= 3 ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: rankColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Team logo placeholder
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[800],
            ),
            child: const Icon(Icons.shield, color: Colors.white, size: 28),
          ),

          const SizedBox(width: 16),

          // Team info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  team.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${team.matchesPlayed} Maç • ${team.wins}G ${team.losses}M',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // Points
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${team.points} P',
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
