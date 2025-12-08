import 'package:flutter/material.dart';
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
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined),
            onPressed: () {},
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, size: 20, color: Colors.white),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (context, index) {
          return PostCard(
            teamName: index % 2 == 0 ? 'Red Dragons FC' : 'Blue Sharks',
            timeAgo: '${index + 1} saat önce',
            imageUrl: 'placeholder',
            content: index % 2 == 0 
                ? 'Harika bir galibiyet! Takım arkadaşlarımı tebrik ediyorum. 💪⚽ #football #win'
                : 'Zorlu bir maçtı ama pes etmek yok. Önümüzdeki maçlara bakacağız.',
            likes: (index + 1) * 12,
            comments: index * 3,
          );
        },
      ),
    );
  }
}
