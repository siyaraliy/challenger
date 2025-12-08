import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 350, // Increased height
                pinned: true,
                title: Text(
                  'CHALLENGER',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.primary,
                  ),
                ),
                centerTitle: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Cover Image
                      Container(color: Colors.grey[900]), // Placeholder for Cover
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              theme.scaffoldBackgroundColor,
                            ],
                            stops: const [0.5, 1.0],
                          ),
                        ),
                      ),
                      // Profile Info
                      Padding(
                        padding: const EdgeInsets.only(bottom: 60), // Added padding to push content up from tabs
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: theme.colorScheme.primary, width: 3),
                              ),
                              child: const CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.grey,
                                child: Icon(Icons.shield, size: 50, color: Colors.white),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Red Dragons FC',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'İstanbul, Kadıköy • Lig A',
                              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                            ),
                            const SizedBox(height: 20),
                            // Stats Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _StatItem(label: 'Maç', value: '24'),
                                _StatItem(label: 'Galibiyet', value: '18'),
                                _StatItem(label: 'Gol', value: '56'),
                                _StatItem(label: 'Puan', value: '2400'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                bottom: TabBar(
                  indicatorColor: theme.colorScheme.primary,
                  labelColor: theme.colorScheme.primary,
                  unselectedLabelColor: Colors.grey,
                  tabs: const [
                    Tab(text: 'Kadro'),
                    Tab(text: 'Fikstür'),
                    Tab(text: 'Medya'),
                  ],
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [
              // Squad Tab
              ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: 11,
                separatorBuilder: (_, __) => const Divider(color: Colors.white10),
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey[800],
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(
                      'Oyuncu ${index + 1}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    subtitle: Text(
                      index == 0 ? 'Kaptan' : 'Forvet',
                      style: TextStyle(color: index == 0 ? theme.colorScheme.primary : Colors.grey),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '#${10 + index}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                },
              ),
              // Fixtures Tab Placeholder
              const Center(child: Text('Fikstür Yakında')),
              // Media Tab Placeholder
              const Center(child: Text('Medya Yakında')),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
