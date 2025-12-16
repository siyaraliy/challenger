import 'package:flutter/material.dart';
import '../../../../core/di/service_locator.dart';
import '../../data/repositories/challenge_repository.dart';

class CreateChallengeScreen extends StatefulWidget {
  final String challengerTeamId;
  final String? preselectedTeamId;

  const CreateChallengeScreen({
    super.key, 
    required this.challengerTeamId,
    this.preselectedTeamId,
  });

  @override
  State<CreateChallengeScreen> createState() => _CreateChallengeScreenState();
}

class _CreateChallengeScreenState extends State<CreateChallengeScreen> {
  final ChallengeRepository _challengeRepo = getIt<ChallengeRepository>();
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  final _messageController = TextEditingController();

  List<Map<String, dynamic>> _teams = [];
  String? _selectedTeamId;
  DateTime? _matchDate;
  TimeOfDay? _matchTime;
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedTeamId = widget.preselectedTeamId;
    _loadTeams();
  }

  @override
  void dispose() {
    _locationController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadTeams() async {
    final teams = await _challengeRepo.getAllTeams(excludeTeamId: widget.challengerTeamId);
    setState(() {
      _teams = teams;
      _isLoading = false;
    });
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() => _matchDate = date);
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 18, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (time != null) {
      setState(() => _matchTime = time);
    }
  }

  DateTime? get _fullMatchDateTime {
    if (_matchDate == null) return null;
    final time = _matchTime ?? const TimeOfDay(hour: 18, minute: 0);
    return DateTime(
      _matchDate!.year,
      _matchDate!.month,
      _matchDate!.day,
      time.hour,
      time.minute,
    );
  }

  Future<void> _submitDirectChallenge() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTeamId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir takım seçin')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _challengeRepo.createChallenge(
        challengerTeamId: widget.challengerTeamId,
        challengedTeamId: _selectedTeamId!,
        matchDate: _fullMatchDateTime,
        location: _locationController.text.isEmpty ? null : _locationController.text,
        message: _messageController.text.isEmpty ? null : _messageController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🔥 Meydan okuma gönderildi!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _submitOpenChallenge() async {
    setState(() => _isSubmitting = true);

    try {
      await _challengeRepo.createOpenChallenge(
        teamId: widget.challengerTeamId,
        title: 'Maç Arıyoruz!',
        matchDate: _fullMatchDateTime,
        location: _locationController.text.isEmpty ? null : _locationController.text,
        message: _messageController.text.isEmpty ? null : _messageController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📢 Maç ilanı oluşturuldu!'),
            backgroundColor: Colors.blue,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DefaultTabController(
      length: 2,
      initialIndex: 0,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Meydan Oku'),
          centerTitle: true,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Takıma Özel'),
              Tab(text: 'Maç İlanı'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildDirectChallengeForm(theme),
            _buildOpenChallengeForm(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectChallengeForm(ThemeData theme) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.preselectedTeamId == null) ...[
              Text(
                'Rakip Takım',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[700]!),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedTeamId,
                    isExpanded: true,
                    dropdownColor: theme.colorScheme.surface,
                    hint: const Text('Takım seç...', style: TextStyle(color: Colors.grey)),
                    items: _teams.map((team) {
                      return DropdownMenuItem<String>(
                        value: team['id'] as String,
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: theme.colorScheme.primary.withValues(alpha: 0.2),
                              ),
                              child: team['logo_url'] != null
                                  ? ClipOval(
                                      child: Image.network(
                                        team['logo_url'] as String,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Icon(Icons.shield, size: 16, color: theme.colorScheme.primary),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              team['name'] as String? ?? 'Bilinmeyen',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedTeamId = value),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            _buildCommonFields(theme),
            const SizedBox(height: 32),

            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitDirectChallenge,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: Text(_isSubmitting ? 'Gönderiliyor...' : 'Meydan Oku!'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.black,
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOpenChallengeForm(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Icon(Icons.public, size: 48, color: theme.colorScheme.primary),
                const SizedBox(height: 12),
                Text(
                  'Herkese Açık Maç İlanı',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Müsait olduğunuz zamanı ve yeri belirtin, diğer takımlar size maç isteği göndersin.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[400]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _buildCommonFields(theme),
          const SizedBox(height: 32),

          SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submitOpenChallenge,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.campaign),
              label: Text(_isSubmitting ? 'Oluşturuluyor...' : 'İLAN OLUŞTUR'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommonFields(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Maç Tarihi & Saati',
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _selectDate,
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  _matchDate != null
                      ? '${_matchDate!.day}/${_matchDate!.month}/${_matchDate!.year}'
                      : 'Tarih Seç',
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _selectTime,
                icon: const Icon(Icons.access_time),
                label: Text(
                  _matchTime != null
                      ? '${_matchTime!.hour.toString().padLeft(2, '0')}:${_matchTime!.minute.toString().padLeft(2, '0')}'
                      : 'Saat Seç',
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        Text(
          'Konum (Opsiyonel)',
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _locationController,
          decoration: InputDecoration(
            hintText: 'Örn: Beşiktaş Sahası',
            prefixIcon: const Icon(Icons.location_on),
            filled: true,
            fillColor: theme.colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[700]!),
            ),
          ),
        ),
        const SizedBox(height: 24),

        Text(
          'Mesaj (Opsiyonel)',
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _messageController,
          maxLines: 3,
          maxLength: 200,
          decoration: InputDecoration(
            hintText: 'Rakibinize bir mesaj bırakın...',
            prefixIcon: const Icon(Icons.message),
            filled: true,
            fillColor: theme.colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[700]!),
            ),
          ),
        ),
      ],
    );
  }
}
