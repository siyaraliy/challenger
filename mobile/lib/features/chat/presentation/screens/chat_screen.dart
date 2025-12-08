import 'package:flutter/material.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
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
          bottom: TabBar(
            indicatorColor: theme.colorScheme.primary,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: 'Sohbetler'),
              Tab(text: 'Takım'),
              Tab(text: 'Müzakere'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_square),
              onPressed: () {},
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _ChatList(type: 'dm'),
            _ChatList(type: 'team'),
            _ChatList(type: 'negotiation'),
          ],
        ),
      ),
    );
  }
}

class _ChatList extends StatelessWidget {
  final String type;

  const _ChatList({required this.type});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 8,
      separatorBuilder: (context, index) => const Divider(color: Colors.white10),
      itemBuilder: (context, index) {
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Stack(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.grey[800],
                child: Icon(
                  type == 'team' ? Icons.shield : Icons.person,
                  color: Colors.white,
                ),
              ),
              if (index < 2)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: theme.scaffoldBackgroundColor, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          title: Text(
            type == 'negotiation' 
                ? 'Maç Müzakeresi #${100+index}' 
                : (type == 'team' ? 'Red Dragons FC' : 'Ahmet Yılmaz'),
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          subtitle: Text(
            type == 'negotiation'
                ? 'Kaptan: Tarih uygun mu?'
                : 'Hafta sonu maç var mı?',
            style: const TextStyle(color: Colors.grey),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '12:30',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              if (index == 0)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    '2',
                    style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
