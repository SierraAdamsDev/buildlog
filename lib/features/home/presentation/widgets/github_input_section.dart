import 'dart:convert';

import 'package:buildlog/features/github_activity/models/github_event.dart';
import 'package:buildlog/features/github_activity/services/github_activity_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

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
  String? _githubToken;

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
    _checkForOAuthCode();
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      _controller.text = prefs.getString('username') ?? '';
      _mode = prefs.getString('mode') ?? 'public';
      _selectedPlatform = prefs.getString('platform') ?? 'LinkedIn';
      _githubToken = prefs.getString('github_token');
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('username', _controller.text);
    await prefs.setString('mode', _mode);
    await prefs.setString('platform', _selectedPlatform);

    if (_githubToken != null && _githubToken!.isNotEmpty) {
      await prefs.setString('github_token', _githubToken!);
    }
  }

  Future<void> _saveGitHubToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    _githubToken = token;
    await prefs.setString('github_token', token);
  }

  Future<void> _checkForOAuthCode() async {
    final code = Uri.base.queryParameters['code'];

    if (code == null || code.isEmpty) return;

    setState(() {
      _isLoading = true;
      _showResults = true;
      _errorMessage = null;
      _events = [];
      _selectedEvent = null;
    });

    try {
      final response = await http.get(
        Uri.parse('${Uri.base.origin}/.netlify/functions/github-oauth?code=$code'),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final token = data['access_token']?.toString();

      if (token == null || token.isEmpty) {
        throw Exception(
          data['error']?.toString() ?? 'Failed to retrieve GitHub access token.',
        );
      }

      await _saveGitHubToken(token);

      final events = await GitHubActivityService.fetchPrivateActivity(token);

      if (!mounted) return;

      setState(() {
        _events = events;
        _selectedEvent = events.isNotEmpty ? events.first : null;
        _errorMessage = events.isEmpty
            ? 'GitHub connected, but no recent activity was found.'
            : null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _setMode(String mode) {
    setState(() {
      _mode = mode;
      _errorMessage = null;
      _showResults = false;
      _events = [];
      _selectedEvent = null;
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
      final events = await GitHubActivityService.fetchPublicActivity(username);

      if (!mounted) return;

      setState(() {
        _events = events;
        _selectedEvent = events.isNotEmpty ? events.first : null;
        _errorMessage = events.isEmpty ? 'No recent public activity found.' : null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleConnectGitHub() async {
    const clientId = 'YOUR_GITHUB_CLIENT_ID';
    final redirectUri = Uri.encodeComponent(Uri.base.origin);

    final authUrl =
        'https://github.com/login/oauth/authorize?client_id=$clientId&redirect_uri=$redirectUri&scope=repo';

    final uri = Uri.parse(authUrl);

    if (!await launchUrl(uri)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open GitHub login')),
      );
    }
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

    if (cleaned.isEmpty) return 'made updates';
    return cleaned[0].toUpperCase() + cleaned.substring(1);
  }

  String _repoDisplayName() {
    final repoName = _selectedEvent?.repoName ?? '';

    if (repoName.isEmpty) return 'your project';

    final parts = repoName.split('/');
    return parts.isNotEmpty ? parts.last : repoName;
  }

  String _summaryForPost() {
    final event = _selectedEvent;

    if (event == null || event.commitMessages.isEmpty) {
      return 'shipped another round of improvements';
    }

    final cleaned = event.commitMessages
        .take(3)
        .map(_cleanCommitMessage)
        .toList();

    if (cleaned.length == 1) return cleaned.first.toLowerCase();
    if (cleaned.length == 2) {
      return '${cleaned[0].toLowerCase()} and ${cleaned[1].toLowerCase()}';
    }

    return '${cleaned[0].toLowerCase()}, ${cleaned[1].toLowerCase()}, and ${cleaned[2].toLowerCase()}';
  }

  String _generatedPost() {
    final repoName = _repoDisplayName();
    final summary = _summaryForPost();

    switch (_selectedPlatform) {
      case 'LinkedIn':
        return 'Built more of $repoName today. I $summary and kept shaping the product into something cleaner and more usable.';
      case 'X':
        return 'Worked on $repoName today. I $summary. Still pushing BuildLog forward. #buildinpublic #webdev';
      case 'Reddit':
        return 'Made more progress on $repoName today. I $summary and kept improving how BuildLog turns GitHub activity into cleaner post drafts.';
      case 'Discord':
        return 'Update on $repoName: I $summary.';
      default:
        return 'Worked on $repoName today. I $summary.';
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
                    onPressed: _mode == 'private' && !_isLoading
                        ? _handleConnectGitHub
                        : null,
                    child: Text(
                      _githubToken != null ? 'GitHub Connected' : 'Connect GitHub',
                    ),
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
    final activeRepo = selectedEvent?.repoName ?? 'No repo selected';

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
              : errorMessage != null && events.isEmpty
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
                        const SizedBox(height: 18),
                        Text(
                          activeRepo,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                        ),
                        if (errorMessage != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            errorMessage!,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        ...events.take(5).map(
                          (event) {
                            final selected = selectedEvent == event;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: GestureDetector(
                                onTap: () => onEventSelected(event),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? const Color(0xFFF9FAFB)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(18),
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
                                          color: Color(0xFF111827),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      const Text(
                                        'Recent work',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF6B7280),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      ...event.commitMessages.take(3).map(
                                            (message) => Padding(
                                              padding: const EdgeInsets.only(bottom: 4),
                                              child: Text('• $message'),
                                            ),
                                          ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
        ),
        if (!isLoading && selectedEvent != null) ...[
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
                  runSpacing: 10,
                  children: platforms.map((platform) {
                    final selected = platform == selectedPlatform;

                    return GestureDetector(
                      onTap: () => onPlatformSelected(platform),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFF111827)
                              : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          platform,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: selected ? Colors.white : const Color(0xFF374151),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$selectedPlatform draft',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        generatedPost,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.6,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
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