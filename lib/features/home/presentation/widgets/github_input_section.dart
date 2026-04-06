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
  bool _showOlderActivity = false;
  String? _errorMessage;
  List<GitHubEvent> _selectedEvents = [];
  List<GitHubEvent> _events = [];
  String? _githubToken;
  int _visibleEventCount = 5;

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

  Future<void> _clearGitHubToken() async {
    final prefs = await SharedPreferences.getInstance();
    _githubToken = null;
    await prefs.remove('github_token');
  }

  void _resetResultsState() {
    _errorMessage = null;
    _showResults = false;
    _events = [];
    _selectedEvents = [];
    _visibleEventCount = 5;
    _showOlderActivity = false;
  }

  Future<void> _loadPrivateActivity() async {
    if (_githubToken == null || _githubToken!.isEmpty) return;

    setState(() {
      _isLoading = true;
      _showResults = true;
      _errorMessage = null;
      _events = [];
      _selectedEvents = [];
      _visibleEventCount = 5;
      _showOlderActivity = false;
    });

    try {
      final events =
          await GitHubActivityService.fetchPrivateActivity(_githubToken!);

      if (!mounted) return;

      setState(() {
        _events = events;
        _selectedEvents = events.isNotEmpty ? [events.first] : [];
        _errorMessage = events.isEmpty
            ? 'GitHub connected, but no recent activity was found.'
            : null;
      });
    } catch (error) {
      if (!mounted) return;

      final message = error.toString().replaceFirst('Exception: ', '');

      if (message.contains('Status: 401') ||
          message.contains('Status: 403')) {
        await _clearGitHubToken();

        setState(() {
          _errorMessage =
              'Your saved GitHub connection is no longer valid. Please reconnect GitHub.';
          _events = [];
          _selectedEvents = [];
        });
      } else {
        setState(() {
          _errorMessage = message;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _checkForOAuthCode() async {
    final code = Uri.base.queryParameters['code'];

    if (code == null || code.isEmpty) return;

    setState(() {
      _isLoading = true;
      _showResults = true;
      _errorMessage = null;
      _events = [];
      _selectedEvents = [];
      _visibleEventCount = 5;
      _showOlderActivity = false;
    });

    try {
      final response = await http.get(
        Uri.parse(
          '${Uri.base.origin}/.netlify/functions/github-oauth?code=$code',
        ),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final token = data['access_token']?.toString();

      if (token == null || token.isEmpty) {
        throw Exception(
          data['error']?.toString() ??
              'Failed to retrieve GitHub access token.',
        );
      }

      await _saveGitHubToken(token);
      await _loadPrivateActivity();
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
      _resetResultsState();
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
      _selectedEvents = [];
      _visibleEventCount = 5;
      _showOlderActivity = false;
    });

    await _saveData();

    try {
      final events = await GitHubActivityService.fetchPublicActivity(username);

      if (!mounted) return;

      setState(() {
        _events = events;
        _selectedEvents = events.isNotEmpty ? [events.first] : [];
        _errorMessage =
            events.isEmpty ? 'No recent public activity found.' : null;
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
    const clientId = 'Ov23liUmc46NUGnWfi8i';
    final redirectUri = Uri.encodeComponent(Uri.base.origin);

    final authUrl =
        'https://github.com/login/oauth/authorize?client_id=$clientId&redirect_uri=$redirectUri&scope=repo%20read:user%20user:email';

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

    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');
    cleaned = cleaned.replaceAll(RegExp(r'\(#\d+\)'), '');
    cleaned =
        cleaned.replaceAll(RegExp(r'\bmerge\b.*$', caseSensitive: false), '');
    cleaned = cleaned.trim();

    if (cleaned.isEmpty) return 'made updates';

    final verbMap = {
      'add': 'added',
      'adds': 'added',
      'added': 'added',
      'fix': 'fixed',
      'fixed': 'fixed',
      'update': 'updated',
      'updates': 'updated',
      'updated': 'updated',
      'remove': 'removed',
      'removed': 'removed',
      'create': 'created',
      'created': 'created',
      'improve': 'improved',
      'improved': 'improved',
      'clean': 'cleaned',
      'cleaned': 'cleaned',
      'polish': 'polished',
      'polished': 'polished',
      'refactor': 'refactored',
      'refactored': 'refactored',
    };

    final parts = cleaned.split(RegExp(r'\s+'));
    final firstWord =
        parts.first.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');

    if (verbMap.containsKey(firstWord)) {
      final rest = cleaned.substring(parts.first.length).trimLeft();
      return '${verbMap[firstWord]}${rest.isNotEmpty ? ' $rest' : ''}';
    }

    return cleaned[0].toLowerCase() + cleaned.substring(1);
  }

  String _repoShortName(String repoName) {
    final parts = repoName.split('/');
    return parts.isNotEmpty ? parts.last : repoName;
  }

  String _repoDisplayName() {
    if (_selectedEvents.isEmpty) return 'your project';

    final names = _selectedEvents
        .map((e) => _repoShortName(e.repoName))
        .toSet()
        .toList();

    if (names.length == 1) return names.first;
    if (names.length == 2) return '${names[0]} and ${names[1]}';

    return '${names[0]}, ${names[1]}, and more';
  }

  String _normalizeThemeKey(String text) {
    final normalized = text.toLowerCase();

    if (normalized.contains('responsive') ||
        normalized.contains('layout') ||
        normalized.contains('spacing') ||
        normalized.contains('padding') ||
        normalized.contains('margin') ||
        normalized.contains('mobile') ||
        normalized.contains('desktop') ||
        normalized.contains('ui') ||
        normalized.contains('screen') ||
        normalized.contains('theme') ||
        normalized.contains('style')) {
      return 'ui_polish';
    }

    if (normalized.contains('bug') ||
        normalized.contains('error') ||
        normalized.contains('crash') ||
        normalized.contains('issue') ||
        normalized.contains('broken') ||
        normalized.contains('null') ||
        normalized.contains('fix')) {
      return 'bug_fixes';
    }

    if (normalized.contains('refactor') ||
        normalized.contains('cleanup') ||
        normalized.contains('clean up') ||
        normalized.contains('restructure') ||
        normalized.contains('organize')) {
      return 'refactor';
    }

    if (normalized.contains('oauth') ||
        normalized.contains('auth') ||
        normalized.contains('login') ||
        normalized.contains('token') ||
        normalized.contains('permission')) {
      return 'auth';
    }

    if (normalized.contains('api') ||
        normalized.contains('fetch') ||
        normalized.contains('request') ||
        normalized.contains('response') ||
        normalized.contains('service') ||
        normalized.contains('endpoint')) {
      return 'data_flow';
    }

    if (normalized.contains('generate') ||
        normalized.contains('summary') ||
        normalized.contains('post') ||
        normalized.contains('draft') ||
        normalized.contains('copy') ||
        normalized.contains('output')) {
      return 'generation_logic';
    }

    if (normalized.contains('deploy') ||
        normalized.contains('build') ||
        normalized.contains('release') ||
        normalized.contains('netlify') ||
        normalized.contains('config') ||
        normalized.contains('environment')) {
      return 'shipping';
    }

    if (normalized.contains('doc') ||
        normalized.contains('readme') ||
        normalized.contains('docs')) {
      return 'docs';
    }

    if (normalized.contains('test') ||
        normalized.contains('testing')) {
      return 'testing';
    }

    if (normalized.contains('add') ||
        normalized.contains('create') ||
        normalized.contains('new') ||
        normalized.contains('introduce') ||
        normalized.contains('support')) {
      return 'features';
    }

    return 'general_updates';
  }

  String _themeLabel(String themeKey) {
    switch (themeKey) {
      case 'ui_polish':
        return 'responsive UI cleanup';
      case 'bug_fixes':
        return 'bug fixes';
      case 'refactor':
        return 'code cleanup and structure updates';
      case 'auth':
        return 'auth flow updates';
      case 'data_flow':
        return 'data flow improvements';
      case 'generation_logic':
        return 'post generation logic';
      case 'shipping':
        return 'build and deploy work';
      case 'docs':
        return 'documentation updates';
      case 'testing':
        return 'testing work';
      case 'features':
        return 'new functionality';
      default:
        return 'general improvements';
    }
  }

  int _themeBaseWeight(String themeKey) {
    switch (themeKey) {
      case 'features':
        return 10;
      case 'generation_logic':
        return 9;
      case 'auth':
        return 9;
      case 'data_flow':
        return 8;
      case 'bug_fixes':
        return 8;
      case 'shipping':
        return 7;
      case 'ui_polish':
        return 6;
      case 'refactor':
        return 6;
      case 'testing':
        return 5;
      case 'docs':
        return 3;
      default:
        return 4;
    }
  }

  int _messageWeight(String cleanedMessage, String themeKey) {
    var score = _themeBaseWeight(themeKey);
    final normalized = cleanedMessage.toLowerCase();

    if (normalized.contains('crash') ||
        normalized.contains('oauth') ||
        normalized.contains('auth') ||
        normalized.contains('login') ||
        normalized.contains('security') ||
        normalized.contains('token')) {
      score += 4;
    }

    if (normalized.contains('generator') ||
        normalized.contains('generation') ||
        normalized.contains('summary') ||
        normalized.contains('draft') ||
        normalized.contains('output')) {
      score += 3;
    }

    if (normalized.contains('responsive') ||
        normalized.contains('desktop') ||
        normalized.contains('mobile') ||
        normalized.contains('layout')) {
      score += 2;
    }

    if (normalized.contains('readme') || normalized.contains('docs')) {
      score -= 1;
    }

    final wordCount = cleanedMessage.split(RegExp(r'\s+')).length;
    if (wordCount >= 6) {
      score += 1;
    }

    return score;
  }

  List<_CommitSignal> _extractTopSignals() {
    final uniqueMessages = <String>{};
    final signals = <_CommitSignal>[];

    for (final event in _selectedEvents) {
      final repoShortName = _repoShortName(event.repoName);

      for (final rawMessage in event.commitMessages) {
        final cleaned = _cleanCommitMessage(rawMessage);

        if (cleaned.isEmpty || cleaned == 'made updates') continue;

        final dedupeKey = '${repoShortName.toLowerCase()}::${cleaned.toLowerCase()}';
        if (uniqueMessages.contains(dedupeKey)) continue;
        uniqueMessages.add(dedupeKey);

        final themeKey = _normalizeThemeKey(cleaned);
        final weight = _messageWeight(cleaned, themeKey);

        signals.add(
          _CommitSignal(
            repoName: repoShortName,
            themeKey: themeKey,
            cleanedMessage: cleaned,
            weight: weight,
          ),
        );
      }
    }

    signals.sort((a, b) {
      final weightCompare = b.weight.compareTo(a.weight);
      if (weightCompare != 0) return weightCompare;
      return a.cleanedMessage.compareTo(b.cleanedMessage);
    });

    return signals;
  }

  _WorkSummary _buildWorkSummary() {
    if (_selectedEvents.isEmpty) {
      return const _WorkSummary(
        repoLabel: 'your project',
        themeLabels: ['general improvements'],
        repoCount: 0,
        topSignals: [],
      );
    }

    final repoNames = _selectedEvents
        .map((e) => _repoShortName(e.repoName))
        .toSet()
        .toList();

    final signals = _extractTopSignals();
    final themeScores = <String, int>{};

    for (final signal in signals) {
      themeScores[signal.themeKey] =
          (themeScores[signal.themeKey] ?? 0) + signal.weight;
    }

    final sortedThemes = themeScores.entries.toList()
      ..sort((a, b) {
        final scoreCompare = b.value.compareTo(a.value);
        if (scoreCompare != 0) return scoreCompare;
        return a.key.compareTo(b.key);
      });

    final topThemeLabels = sortedThemes
        .take(3)
        .map((entry) => _themeLabel(entry.key))
        .toList();

    return _WorkSummary(
      repoLabel: _repoDisplayName(),
      themeLabels:
          topThemeLabels.isEmpty ? ['general improvements'] : topThemeLabels,
      repoCount: repoNames.length,
      topSignals: signals.take(3).toList(),
    );
  }

  String _joinNatural(List<String> items) {
    if (items.isEmpty) return '';
    if (items.length == 1) return items.first;
    if (items.length == 2) return '${items[0]} and ${items[1]}';

    final allButLast = items.sublist(0, items.length - 1).join(', ');
    return '$allButLast, and ${items.last}';
  }

  String _focusLine(_WorkSummary summary) {
    final focus = _joinNatural(summary.themeLabels);

    if (summary.repoCount > 1) {
      return 'Focused on $focus across multiple projects.';
    }

    return 'Focused on $focus.';
  }

  String _impactLine(_WorkSummary summary) {
    final topThemes = summary.themeLabels;

    if (topThemes.contains('post generation logic')) {
      return 'Made the output smarter and more useful instead of just dumping commit history.';
    }

    if (topThemes.contains('auth flow updates')) {
      return 'Tightened access and flow so the experience feels more reliable.';
    }

    if (topThemes.contains('data flow improvements')) {
      return 'Cleaned up how data moves through the app so things feel more stable.';
    }

    if (topThemes.contains('responsive UI cleanup')) {
      return 'Cleaned up the experience across screen sizes and tightened overall usability.';
    }

    if (topThemes.contains('new functionality')) {
      return 'Added more real functionality instead of just surface-level polish.';
    }

    if (summary.repoCount > 1) {
      return 'Still building, testing, and tightening things up.';
    }

    return 'Still refining the experience and keeping things moving.';
  }

  String _detailLine(_WorkSummary summary) {
    if (summary.topSignals.isEmpty) return '';

    final strongest = summary.topSignals.first.cleanedMessage;
    final cleanedStrongest =
        strongest.isNotEmpty ? strongest[0].toUpperCase() + strongest.substring(1) : '';

    if (cleanedStrongest.isEmpty) return '';

    return 'Most notable update: $cleanedStrongest.';
  }

  String _generatedPost() {
    final summary = _buildWorkSummary();

    switch (_selectedPlatform) {
      case 'LinkedIn':
        return '''Worked on ${summary.repoLabel} today.

${_focusLine(summary)}
${_impactLine(summary)}
${_detailLine(summary)}

#BuildInPublic #SoftwareDevelopment #WebDevelopment #DevTools #GitHub''';

      case 'X':
        return 'Worked on ${summary.repoLabel} today. ${_focusLine(summary).replaceAll('.', '')} ${_impactLine(summary)} #buildinpublic #webdev #devtools';

      case 'Reddit':
        return '''Update on ${summary.repoLabel}:

${_focusLine(summary)}
${_impactLine(summary)}
${_detailLine(summary)}''';

      case 'Discord':
        return 'Update on ${summary.repoLabel}: ${_focusLine(summary)} ${_impactLine(summary)} ${_detailLine(summary)}';

      default:
        return 'Worked on ${summary.repoLabel} today. ${_focusLine(summary)} ${_impactLine(summary)} ${_detailLine(summary)}';
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

  void _toggleEventSelection(GitHubEvent event) {
    setState(() {
      if (_selectedEvents.contains(event)) {
        _selectedEvents.remove(event);
      } else {
        if (_selectedEvents.length < 3) {
          _selectedEvents.add(event);
        }
      }
    });
  }

  void _loadMoreEvents() {
    setState(() {
      _visibleEventCount += 5;
    });
  }

  void _toggleOlderActivity() {
    setState(() {
      _showOlderActivity = !_showOlderActivity;
      _visibleEventCount = 5;
    });
  }

  bool _isRecentEvent(GitHubEvent event) {
    if (event.createdAt == null) return true;

    final difference = DateTime.now().difference(event.createdAt!);
    return difference.inHours <= 48;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;
        final cardPadding = isMobile ? 20.0 : 28.0;

        return Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(cardPadding),
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
                    isMobile: isMobile,
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
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      ElevatedButton(
                        onPressed: _mode == 'public' && !_isLoading
                            ? _handlePublicLoad
                            : null,
                        child: Text(
                          _isLoading ? 'Loading...' : 'Load Public Activity',
                        ),
                      ),
                      OutlinedButton(
                        onPressed: _mode == 'private' && !_isLoading
                            ? ((_githubToken == null || _githubToken!.isEmpty)
                                ? _handleConnectGitHub
                                : _loadPrivateActivity)
                            : null,
                        child: Text(
                          (_githubToken != null && _githubToken!.isNotEmpty)
                              ? 'Load Private Activity'
                              : 'Connect GitHub',
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
                selectedEvents: _selectedEvents,
                onEventSelected: _toggleEventSelection,
                selectedPlatform: _selectedPlatform,
                platforms: _platforms,
                onPlatformSelected: _selectPlatform,
                generatedPost: _generatedPost(),
                onCopy: _copyPost,
                isMobile: isMobile,
                visibleEventCount: _visibleEventCount,
                onLoadMore: _loadMoreEvents,
                showOlderActivity: _showOlderActivity,
                onToggleOlderActivity: _toggleOlderActivity,
                isRecentEvent: _isRecentEvent,
              ),
          ],
        );
      },
    );
  }
}

class _ModeCards extends StatelessWidget {
  final String mode;
  final Function(String) onModeChange;
  final bool isMobile;

  const _ModeCards({
    required this.mode,
    required this.onModeChange,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return Column(
        children: [
          _ModeCard(
            label: 'Public Mode',
            selected: mode == 'public',
            onTap: () => onModeChange('public'),
          ),
          const SizedBox(height: 10),
          _ModeCard(
            label: 'Private Mode',
            selected: mode == 'private',
            onTap: () => onModeChange('private'),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: _ModeCard(
            label: 'Public Mode',
            selected: mode == 'public',
            onTap: () => onModeChange('public'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ModeCard(
            label: 'Private Mode',
            selected: mode == 'private',
            onTap: () => onModeChange('private'),
          ),
        ),
      ],
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeCard({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE5E7EB) : Colors.white,
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _ResultsSection extends StatelessWidget {
  final bool isLoading;
  final String? errorMessage;
  final List<GitHubEvent> events;
  final List<GitHubEvent> selectedEvents;
  final ValueChanged<GitHubEvent> onEventSelected;
  final String selectedPlatform;
  final List<String> platforms;
  final ValueChanged<String> onPlatformSelected;
  final String generatedPost;
  final VoidCallback onCopy;
  final bool isMobile;
  final int visibleEventCount;
  final VoidCallback onLoadMore;
  final bool showOlderActivity;
  final VoidCallback onToggleOlderActivity;
  final bool Function(GitHubEvent) isRecentEvent;

  const _ResultsSection({
    required this.isLoading,
    required this.errorMessage,
    required this.events,
    required this.selectedEvents,
    required this.onEventSelected,
    required this.selectedPlatform,
    required this.platforms,
    required this.onPlatformSelected,
    required this.generatedPost,
    required this.onCopy,
    required this.isMobile,
    required this.visibleEventCount,
    required this.onLoadMore,
    required this.showOlderActivity,
    required this.onToggleOlderActivity,
    required this.isRecentEvent,
  });

  @override
  Widget build(BuildContext context) {
    final cardPadding = isMobile ? 20.0 : 28.0;
    final recentEvents = events.where(isRecentEvent).toList();
    final olderEvents = events.where((event) => !isRecentEvent(event)).toList();

    final displayEvents = showOlderActivity
        ? [...recentEvents, ...olderEvents]
        : recentEvents;

    final visibleEvents = displayEvents.take(visibleEventCount).toList();
    final canLoadMore = visibleEventCount < displayEvents.length;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(cardPadding),
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
                        if (errorMessage != null) ...[
                          Text(
                            errorMessage!,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 18),
                        ],
                        if (recentEvents.isEmpty && olderEvents.isNotEmpty) ...[
                          const Text(
                            'No recent activity found. Older activity is available.',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF4B5563),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (recentEvents.isNotEmpty && olderEvents.isNotEmpty) ...[
                          Text(
                            showOlderActivity
                                ? 'Showing recent and older activity'
                                : 'Showing recent activity first',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        ...visibleEvents.map(
                          (event) {
                            final selected = selectedEvents.contains(event);
                            final recent = isRecentEvent(event);

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: GestureDetector(
                                onTap: () => onEventSelected(event),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? const Color(0xFF111827)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: const Color(0xFFE5E7EB),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              event.repoName,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                color: selected
                                                    ? Colors.white
                                                    : const Color(0xFF111827),
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: selected
                                                  ? Colors.white12
                                                  : const Color(0xFFF3F4F6),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                            child: Text(
                                              recent ? 'Recent' : 'Older',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: selected
                                                    ? Colors.white
                                                    : const Color(0xFF4B5563),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'What changed',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: selected
                                              ? const Color(0xFF9CA3AF)
                                              : const Color(0xFF6B7280),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      ...event.commitMessages.take(3).map(
                                            (message) => Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 4,
                                              ),
                                              child: Text(
                                                '• $message',
                                                style: TextStyle(
                                                  color: selected
                                                      ? Colors.white
                                                      : null,
                                                ),
                                              ),
                                            ),
                                          ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        if (olderEvents.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Center(
                            child: TextButton(
                              onPressed: onToggleOlderActivity,
                              child: Text(
                                showOlderActivity
                                    ? 'Hide Older Activity'
                                    : 'Show Older Activity',
                              ),
                            ),
                          ),
                        ],
                        if (canLoadMore) ...[
                          const SizedBox(height: 4),
                          Center(
                            child: TextButton(
                              onPressed: onLoadMore,
                              child: const Text('Load more'),
                            ),
                          ),
                        ],
                      ],
                    ),
        ),
        if (!isLoading && selectedEvents.isNotEmpty) ...[
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(cardPadding),
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
                            color: selected
                                ? Colors.white
                                : const Color(0xFF374151),
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
                      const Text(
                        'Draft',
                        style: TextStyle(
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

class _WorkSummary {
  final String repoLabel;
  final List<String> themeLabels;
  final int repoCount;
  final List<_CommitSignal> topSignals;

  const _WorkSummary({
    required this.repoLabel,
    required this.themeLabels,
    required this.repoCount,
    required this.topSignals,
  });
}

class _CommitSignal {
  final String repoName;
  final String themeKey;
  final String cleanedMessage;
  final int weight;

  const _CommitSignal({
    required this.repoName,
    required this.themeKey,
    required this.cleanedMessage,
    required this.weight,
  });
}