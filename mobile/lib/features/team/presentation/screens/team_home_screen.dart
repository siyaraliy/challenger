import 'package:flutter/material.dart';
import '../../../../core/widgets/mode_switcher_button.dart';

class TeamHomeScreen extends StatelessWidget {
  const TeamHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Takım Ana Sayfa'),
        centerTitle: true,
        actions: const [
          ModeSwitcherButton(),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shield,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Takım Modundasınız',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Takım gönderileri ve aktiviteleri yakında...',
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
