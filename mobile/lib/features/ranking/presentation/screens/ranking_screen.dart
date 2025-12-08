import 'package:flutter/material.dart';

class RankingScreen extends StatelessWidget {
  const RankingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'CHALLENGER',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            fontStyle: FontStyle.italic,
            color: theme.colorScheme.primary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Podium Section (Top 3)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  theme.colorScheme.surface,
                  theme.scaffoldBackgroundColor,
                ],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _PodiumItem(
                  rank: 2,
                  teamName: 'Blue Sharks',
                  points: '2150',
                  height: 120,
                  color: theme.colorScheme.secondary,
                ),
                _PodiumItem(
                  rank: 1,
                  teamName: 'Red Dragons',
                  points: '2400',
                  height: 160,
                  color: theme.colorScheme.primary,
                  isWinner: true,
                ),
                _PodiumItem(
                  rank: 3,
                  teamName: 'Iron Cleats',
                  points: '1980',
                  height: 100,
                  color: Colors.orangeAccent,
                ),
              ],
            ),
          ),

          // List Section (4th onwards)
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: 10,
                separatorBuilder: (_, __) => const Divider(color: Colors.white10),
                itemBuilder: (context, index) {
                  final rank = index + 4;
                  return ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Text(
                        '$rank',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    title: Text(
                      'Team ${String.fromCharCode(70 + index)}', // F, G, H...
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    subtitle: const Text('18 Maç • 12 Galibiyet', style: TextStyle(color: Colors.grey)),
                    trailing: Text(
                      '${1800 - (index * 50)} P',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                        fontSize: 16,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PodiumItem extends StatelessWidget {
  final int rank;
  final String teamName;
  final String points;
  final double height;
  final Color color;
  final bool isWinner;

  const _PodiumItem({
    required this.rank,
    required this.teamName,
    required this.points,
    required this.height,
    required this.color,
    this.isWinner = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Avatar
        Stack(
          alignment: Alignment.topCenter,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
                boxShadow: [
                  BoxShadow(color: color.withOpacity(0.5), blurRadius: 10),
                ],
              ),
              child: CircleAvatar(
                radius: isWinner ? 35 : 25,
                backgroundColor: Colors.grey[800],
                child: const Icon(Icons.shield, color: Colors.white),
              ),
            ),
            if (isWinner)
              Positioned(
                top: -10,
                child: Icon(Icons.emoji_events, color: Colors.amber, size: 30),
              ),
          ],
        ),
        
        // Team Name
        Text(
          teamName,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),

        // Bar
        Container(
          width: isWinner ? 80 : 60,
          height: height,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            border: Border.all(color: color.withOpacity(0.5)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '$rank',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        
        // Points
        const SizedBox(height: 4),
        Text(
          '$points P',
          style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 12),
        ),
      ],
    );
  }
}
