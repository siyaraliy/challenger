import 'package:flutter/material.dart';

class TeamChatScreen extends StatelessWidget {
  const TeamChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
              'Takım Sohbeti',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Takım arkadaşlarınla sohbet et...',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
