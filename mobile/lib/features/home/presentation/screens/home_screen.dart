import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/widgets/post_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // TODO: Refresh feed
          await Future.delayed(const Duration(seconds: 1));
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            // Feed Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.feed, color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Ana Akım',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Post Feed (Mock)
            ...List.generate(
              10,
              (index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: PostCard(
                  teamName: index % 3 == 0
                      ? 'Red Dragons FC'
                      : index % 3 == 1
                          ? 'Blue Sharks'
                          : 'Golden Eagles',
                  timeAgo: '${index + 1} saat önce',
                  imageUrl: 'placeholder',
                  content: index % 2 == 0
                      ? 'Harika bir galibiyet! Takım arkadaşlarımı tebrik ediyorum. 💪⚽ #football #win'
                      : 'Zorlu bir maçtı ama pes etmek yok. Önümüzdeki maçlara bakacağız.',
                  likes: (index + 1) * 12,
                  comments: index * 3,
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/create-team'),
        icon: const Icon(Icons.shield),
        label: const Text('Takım Oluştur'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.black,
      ),
    );
  }
}
