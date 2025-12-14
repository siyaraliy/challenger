import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/models/challenge.dart';
import '../../../../core/cubit/mode_cubit.dart';
import '../../data/repositories/challenge_repository.dart';
import '../widgets/challenge_card.dart';
import 'create_challenge_screen.dart';

class TeamMatchesScreen extends StatefulWidget {
  final String? teamId;

  const TeamMatchesScreen({super.key, this.teamId});

  @override
  State<TeamMatchesScreen> createState() => _TeamMatchesScreenState();
}

class _TeamMatchesScreenState extends State<TeamMatchesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ChallengeRepository _challengeRepo = getIt<ChallengeRepository>();
  
  List<Challenge> _incomingChallenges = [];
  List<Challenge> _outgoingChallenges = [];
  List<Map<String, dynamic>> _openChallenges = [];
  
  bool _isLoadingIncoming = true;
  bool _isLoadingOutgoing = true;
  bool _isLoadingOpen = true;
  String? _teamId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _teamId = widget.teamId;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get teamId from ModeCubit if not provided directly
    if (_teamId == null) {
      final modeState = context.read<ModeCubit>().state;
      if (modeState.isTeamMode) {
        _teamId = modeState.teamId;
      }
    }
    _loadChallenges();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadChallenges() async {
    if (_teamId == null) {
      print('TeamMatchesScreen: No teamId provided');
      setState(() {
        _isLoadingIncoming = false;
        _isLoadingOutgoing = false;
        _isLoadingOpen = false;
      });
      return;
    }

    // Load incoming
    setState(() => _isLoadingIncoming = true);
    final incoming = await _challengeRepo.getIncomingChallenges(_teamId!);
    if (mounted) {
      setState(() {
        _incomingChallenges = incoming;
        _isLoadingIncoming = false;
      });
    }

    // Load outgoing
    setState(() => _isLoadingOutgoing = true);
    final outgoing = await _challengeRepo.getOutgoingChallenges(_teamId!);
    if (mounted) {
      setState(() {
        _outgoingChallenges = outgoing;
        _isLoadingOutgoing = false;
      });
    }

    // Load open challenges (fetch all to show own challenges too)
    setState(() => _isLoadingOpen = true);
    final open = await _challengeRepo.getOpenChallenges(excludeTeamId: null);
    if (mounted) {
      setState(() {
        _openChallenges = open;
        _isLoadingOpen = false;
      });
    }
  }

  Future<void> _closeOpenChallenge(String openChallengeId) async {
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text('İlanı Kaldır', style: TextStyle(color: Colors.white)),
          content: const Text(
            'Bu maç ilanını kaldırmak istediğinize emin misiniz?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Kaldır'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        await _challengeRepo.closeOpenChallenge(openChallengeId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('İlan kaldırıldı')),
          );
          _loadChallenges();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  Future<void> _acceptChallenge(Challenge challenge) async {
    try {
      await _challengeRepo.acceptChallenge(challenge.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meydan okuma kabul edildi!')),
      );
      _loadChallenges();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  Future<void> _rejectChallenge(Challenge challenge) async {
    try {
      await _challengeRepo.rejectChallenge(challenge.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meydan okuma reddedildi')),
      );
      _loadChallenges();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  Future<void> _completeChallenge(Challenge challenge) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Maçı Tamamla', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Maç tamamlandığında her iki takıma da 100 puan verilecek. Devam etmek istiyor musunuz?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Tamamla'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _challengeRepo.completeChallenge(challenge.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🏆 Maç tamamlandı! Her iki takım da 100 puan kazandı!'),
              backgroundColor: Colors.green,
            ),
          );
          _loadChallenges();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hata: $e')),
          );
        }
      }
    }
  }

  Future<void> _cancelChallenge(Challenge challenge) async {
    try {
      await _challengeRepo.cancelChallenge(challenge.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meydan okuma iptal edildi')),
      );
      _loadChallenges();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  void _createChallenge() async {
    if (_teamId == null) return;
    
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CreateChallengeScreen(challengerTeamId: _teamId!),
      ),
    );

    if (result == true) {
      _loadChallenges();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Maçlar'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.primary,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.public, size: 18),
                  const SizedBox(width: 8),
                  Text('İlanlar (${_openChallenges.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.call_received, size: 18),
                  const SizedBox(width: 8),
                  Text('Gelen (${_incomingChallenges.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.call_made, size: 18),
                  const SizedBox(width: 8),
                  Text('Giden (${_outgoingChallenges.length})'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Open Challenges
          _buildOpenChallengeList(
            challenges: _openChallenges,
            isLoading: _isLoadingOpen,
          ),
          // Incoming challenges
          _buildChallengeList(
            challenges: _incomingChallenges,
            isLoading: _isLoadingIncoming,
            isIncoming: true,
            emptyMessage: 'Henüz gelen meydan okuma yok',
            emptyIcon: Icons.call_received,
          ),
          // Outgoing challenges
          _buildChallengeList(
            challenges: _outgoingChallenges,
            isLoading: _isLoadingOutgoing,
            isIncoming: false,
            emptyMessage: 'Henüz meydan okuma göndermemişsiniz',
            emptyIcon: Icons.call_made,
          ),
        ],
      ),
      floatingActionButton: _teamId != null
          ? FloatingActionButton.extended(
              onPressed: _createChallenge,
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.black,
              icon: const Icon(Icons.sports_mma),
              label: const Text('Meydan Oku'),
            )
          : null,
    );
  }

  Widget _buildOpenChallengeList({
    required List<Map<String, dynamic>> challenges,
    required bool isLoading,
  }) {
    final theme = Theme.of(context);
    
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (challenges.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.public_off, size: 64, color: Colors.grey[700]),
            const SizedBox(height: 16),
            Text(
              'Açık maç ilanı bulunamadı',
              style: TextStyle(color: Colors.grey[500], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: challenges.length,
      itemBuilder: (context, index) {
        final challenge = challenges[index];
        final matchDate = challenge['match_date'] != null 
            ? DateTime.parse(challenge['match_date']) 
            : null;
        final isMyChallenge = challenge['team_id'] == _teamId;
            
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          color: isMyChallenge 
              ? theme.colorScheme.primaryContainer.withOpacity(0.1) 
              : theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
             side: BorderSide(
               color: isMyChallenge ? theme.colorScheme.primary : Colors.grey[800]!
             ),
             borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.primary.withValues(alpha: 0.2),
                      ),
                      child: challenge['team_logo'] != null
                          ? ClipOval(
                              child: Image.network(
                                challenge['team_logo'],
                                fit: BoxFit.cover,
                              ),
                            )
                          : Icon(Icons.shield, color: theme.colorScheme.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            challenge['team_name'] ?? 'Bilinmeyen Takım',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                challenge['title'] ?? 'Maç Arıyoruz',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 14,
                                ),
                              ),
                              if (isMyChallenge) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'SİZİN İLANINIZ',
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                if (matchDate != null) ...[
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        '${matchDate.day}/${matchDate.month}/${matchDate.year} ${matchDate.hour.toString().padLeft(2, '0')}:${matchDate.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                
                if (challenge['location'] != null) ...[
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        challenge['location'],
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],

                if (challenge['message'] != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    challenge['message'],
                    style: TextStyle(color: Colors.grey[400], fontStyle: FontStyle.italic),
                  ),
                ],
                
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: isMyChallenge
                      ? OutlinedButton.icon(
                          onPressed: () => _closeOpenChallenge(challenge['id']),
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: const Text('İlanı Kaldır'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                        )
                      : ElevatedButton(
                          onPressed: () => _joinOpenChallenge(challenge['id']),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: Colors.black,
                          ),
                          child: const Text('Meydan Oku'),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _joinOpenChallenge(String openChallengeId) async {
    if (_teamId == null) return;
    
    try {
      await _challengeRepo.joinOpenChallenge(openChallengeId, _teamId!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Meydan okuma gönderildi!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadChallenges();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }
  Widget _buildChallengeList({
    required List<Challenge> challenges,
    required bool isLoading,
    required bool isIncoming,
    required String emptyMessage,
    required IconData emptyIcon,
  }) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_teamId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber, size: 64, color: Colors.orange[300]),
            const SizedBox(height: 16),
            const Text(
              'Takım bilgisi bulunamadı',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
      );
    }

    if (challenges.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(color: Colors.grey[500], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadChallenges,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: challenges.length,
        itemBuilder: (context, index) {
          final challenge = challenges[index];
          return ChallengeCard(
            challenge: challenge,
            isIncoming: isIncoming,
            onAccept: () => _acceptChallenge(challenge),
            onReject: () => _rejectChallenge(challenge),
            onComplete: () => _completeChallenge(challenge),
            onCancel: () => _cancelChallenge(challenge),
          );
        },
      ),
    );
  }
}
