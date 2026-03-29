import 'package:buildlog/features/github_activity/models/github_event.dart';
import 'package:buildlog/features/github_activity/services/github_activity_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GitHubInputSection extends StatefulWidget {
  const GitHubInputSection({super.key});

  @override
  State<GitHubInputSection> createState() => _GitHubInputSectionState();
}

class _GitHubInputSectionState extends State<GitHubInputSection> {
  final TextEditingController _controller = TextEditingController();

  String _mode = 'public';
  String _selectedPlatform = 'LinkedIn';
  bool _showResults = false;
  bool _isLoading = false;
  String? _errorMessage;
  GitHubEvent? _selectedEvent;
  List<GitHubEvent> _events = [];

  final List<String> _platforms = [
    'LinkedIn',
    'X',
    'Reddit',
    'Discord',
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _controller.text = prefs.getString('username') ?? '';
      _mode = prefs.getString('mode') ?? 'public';
      _selectedPlatform = prefs.getString('platform') ?? 'LinkedIn';
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('username', _controller.text);
    await prefs.setString('mode', _mode);
    await prefs.setString('platform', _selectedPlatform);
  }

  void _setMode(String mode) {
    setState(() {
      _mode = mode;
      _errorMessage = null;
    });
    _saveData();
  }

  void _selectPlatform(String platform) {
    setState(() {
      _selectedPlatform = platform;
    });
    _saveData();
  }

  Future<void> _handlePublicLoad() async {
    final username = _controller.text.trim();

    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a GitHub username')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _showResults = true;
      _events = [];
      _selectedEvent = null;
    });

    await _saveData();

    try {
      final events = await GitHubActivityService.fetchPublicPushEvents(username);

      if (!mounted) return;

      setState(() {
        _events = events;
        _selectedEvent = events.isNotEmpty ? events.first : null;
        _errorMessage =
            events.isEmpty ? 'No recent public push activity found.' : null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleConnectGitHub() {
    _saveData();

    setState(() {
      _showResults = true;
      _errorMessage = 'Private GitHub connection comes in Pass 2.';
      _events = [];
      _selectedEvent = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Private GitHub connection comes next')),
    );
  }

  String _buildSummary() {
    final event = _selectedEvent;

    if (event == null || event.commitMessages.isEmpty) {
      return 'Worked on BuildLog and made progress worth sharing.';
    }

    final cleaned = event.commitMessages
        .take(3)
        .map((message) => _cleanCommitMessage(message))
        .toList();

    if (cleaned.length == 1) return cleaned.first;
    if (cleaned.length == 2) return '${cleaned[0]} and ${cleaned[1]}';

    return '${cleaned[0]}, ${cleaned[1]}, and ${cleaned[2]}';
  }

  String _cleanCommitMessage(String message) {
    var cleaned = message.trim();

    final prefixes = [
      'feat:',
      'fix:',
      'refactor:',
      'docs:',
      'style:',
      'test:',
      'chore:',
      'build:',
      'perf:',
      'ci:',
    ];

    for (final prefix in prefixes) {
      if (cleaned.toLowerCase().startsWith(prefix)) {
        cleaned = cleaned.substring(prefix.length).trim();
        break;
      }
    }

    if (cleaned.isEmpty) {
      return 'made updates';
    }

    return cleaned[0].toUpperCase() + cleaned.substring(1);
  }

  String _generatedPost() {
    final repoName = _selectedEvent?.repoName ?? 'BuildLog';
    final summary = _buildSummary();
    final username = _controller.text.trim();

    switch (_selectedPlatform) {
      case 'LinkedIn':
        return 'Built more progress on $repoName today. Recent work included $summary. Using BuildLog to turn GitHub activity into clearer, shareable updates is starting to feel very real.';
      case 'X':
        return 'Shipped more work on $repoName 🚀 $summary. Testing BuildLog with real GitHub activity from @$username. #buildinpublic #webdev';
      case 'Reddit':
        return 'I’m testing BuildLog with real GitHub activity now. Recent work on $repoName included $summary. It’s been nice seeing actual commits turn into cleaner post drafts.';
      case 'Discord':
        return 'BuildLog update: recent work on $repoName included $summary.';
      default:
        return 'Built more of $repoName today: $summary.';
    }
  }

  Future<void> _copyPost() async {
    await Clipboard.setData(
      ClipboardData(text: _generatedPost()),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied $_selectedPlatform draft')),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repoLabel = _selectedEvent?.repoName ?? _controller.text.trim();

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'GitHub Activity',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _ModeCards(
                mode: _mode,
                onModeChange: _setMode,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _controller,
                onChanged: (_) => _saveData(),
                decoration: InputDecoration(
                  hintText: 'Enter GitHub username',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _mode == 'public' && !_isLoading
                        ? _handlePublicLoad
                        : null,
                    child: Text(_isLoading ? 'Loading...' : 'Load Public Activity'),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: _mode == 'private' ? _handleConnectGitHub : null,
                    child: const Text('Connect GitHub'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (_showResults)
          _ResultsSection(
            isLoading: _isLoading,
            errorMessage: _errorMessage,
            repoName: repoLabel.isEmpty ? 'No repo selected' : repoLabel,
            events: _events,
            selectedEvent: _selectedEvent,
            onEventSelected: (event) {
              setState(() {
                _selectedEvent = event;
              });
            },
            selectedPlatform: _selectedPlatform,
            platforms: _platforms,
            onPlatformSelected: _selectPlatform,
            generatedPost: _generatedPost(),
            onCopy: _copyPost,
          ),
      ],
    );
  }
}

class _ModeCards extends StatelessWidget {
  final String mode;
  final Function(String) onModeChange;

  const _ModeCards({
    required this.mode,
    required this.onModeChange,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => onModeChange('public'),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: mode == 'public'
                    ? const Color(0xFFE5E7EB)
                    : Colors.white,
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: const Text('Public Mode'),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: () => onModeChange('private'),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: mode == 'private'
                    ? const Color(0xFFE5E7EB)
                    : Colors.white,
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: const Text('Private Mode'),
            ),
          ),
        ),
      ],
    );
  }
}

class _ResultsSection extends StatelessWidget {
  final bool isLoading;
  final String? errorMessage;
  final String repoName;
  final List<GitHubEvent> events;
  final GitHubEvent? selectedEvent;
  final ValueChanged<GitHubEvent> onEventSelected;
  final String selectedPlatform;
  final List<String> platforms;
  final ValueChanged<String> onPlatformSelected;
  final String generatedPost;
  final VoidCallback onCopy;

  const _ResultsSection({
    required this.isLoading,
    required this.errorMessage,
    required this.repoName,
    required this.events,
    required this.selectedEvent,
    required this.onEventSelected,
    required this.selectedPlatform,
    required this.platforms,
    required this.onPlatformSelected,
    required this.generatedPost,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: isLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                )
              : errorMessage != null
                  ? Text(
                      errorMessage!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Recent Activity',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          repoName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...events.take(5).map(
                          (event) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: GestureDetector(
                              onTap: () => onEventSelected(event),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: selectedEvent == event
                                      ? const Color(0xFFF3F4F6)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFE5E7EB),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      event.repoName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      event.commitMessages.first,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
        ),
        if (!isLoading && errorMessage == null && selectedEvent != null) ...[
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Platform Output',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  children: platforms.map((platform) {
                    final selected = platform == selectedPlatform;

                    return GestureDetector(
                      onTap: () => onPlatformSelected(platform),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? Colors.black
                              : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          platform,
                          style: TextStyle(
                            color: selected ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    generatedPost,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: onCopy,
                  child: const Text('Copy Draft'),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}