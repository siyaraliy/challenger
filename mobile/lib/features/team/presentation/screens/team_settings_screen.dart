import 'package:flutter/material.dart';
import '../../../../core/widgets/mode_switcher_button.dart';

class TeamSettingsScreen extends StatelessWidget {
  const TeamSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Takım Ayarları'),
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
              Icons.settings,
              size: 80,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 24),
            Text(
              'Takım Ayarları',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Takım bilgilerini düzenle, üyeleri yönet...',
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
