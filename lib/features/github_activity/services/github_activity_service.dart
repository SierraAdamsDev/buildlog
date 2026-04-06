import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/github_event.dart';

class GitHubActivityService {
  static Map<String, String> _headers([String? token]) {
    return {
      'Accept': 'application/vnd.github+json',
      'X-GitHub-Api-Version': '2022-11-28',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // =============================
  // PUBLIC ENTRY POINTS
  // =============================

  static Future<List<GitHubEvent>> fetchPublicActivity(String username) async {
    final pushEvents = await _fetchPublicPushEvents(username);

    if (pushEvents.isNotEmpty) {
      return pushEvents;
    }

    return _fetchPublicRepoCommits(username);
  }

  static Future<List<GitHubEvent>> fetchPrivateActivity(String accessToken) async {
    return _fetchPrivateRepoCommits(accessToken);
  }

  // =============================
  // CORE FETCHERS
  // =============================

  static Future<List<GitHubEvent>> _fetchPublicPushEvents(String username) async {
    final response = await http.get(
      Uri.parse('https://api.github.com/users/$username/events/public?per_page=100'),
      headers: _headers(),
    );

    if (response.statusCode == 404) {
      throw Exception('GitHub user not found.');
    }

    if (response.statusCode != 200) {
      throw Exception('GitHub public activity failed.');
    }

    final List<dynamic> data = jsonDecode(response.body);

    final events = data
        .whereType<Map<String, dynamic>>()
        .where((event) => event['type'] == 'PushEvent')
        .map(GitHubEvent.fromJson)
        .where((event) => event.commitMessages.isNotEmpty)
        .map(_cleanEvent)
        .where((event) => event.commitMessages.isNotEmpty)
        .toList();

    return _sortEvents(events);
  }

  static Future<List<GitHubEvent>> _fetchPublicRepoCommits(String username) async {
    final reposResponse = await http.get(
      Uri.parse('https://api.github.com/users/$username/repos?sort=updated&per_page=5'),
      headers: _headers(),
    );

    if (reposResponse.statusCode == 404) {
      throw Exception('GitHub user not found.');
    }

    if (reposResponse.statusCode != 200) {
      throw Exception('Failed to load public repositories.');
    }

    final List<dynamic> repos = jsonDecode(reposResponse.body);
    final List<GitHubEvent> results = [];

    for (final repo in repos.whereType<Map<String, dynamic>>()) {
      final fullName = repo['full_name']?.toString();
      if (fullName == null || fullName.isEmpty) continue;

      final commitsResponse = await http.get(
        Uri.parse('https://api.github.com/repos/$fullName/commits?per_page=3'),
        headers: _headers(),
      );

      if (commitsResponse.statusCode != 200) continue;

      final List<dynamic> commits = jsonDecode(commitsResponse.body);

      final messages = commits
          .whereType<Map<String, dynamic>>()
          .map((commit) {
            final commitData = commit['commit'] as Map<String, dynamic>? ?? {};
            return commitData['message']?.toString().trim() ?? '';
          })
          .map(_cleanCommitMessage)
          .where((m) => m.isNotEmpty)
          .toSet()
          .take(3)
          .toList();

      if (messages.isNotEmpty) {
        results.add(
          GitHubEvent(
            repoName: fullName,
            commitMessages: messages,
            createdAt: DateTime.now(), // fallback
          ),
        );
      }
    }

    return _sortEvents(results);
  }

  static Future<List<GitHubEvent>> _fetchPrivateRepoCommits(String accessToken) async {
    final reposResponse = await http.get(
      Uri.parse('https://api.github.com/user/repos?sort=updated&per_page=5'),
      headers: _headers(accessToken),
    );

    if (reposResponse.statusCode != 200) {
      throw Exception('Failed to load private repositories.');
    }

    final List<dynamic> repos = jsonDecode(reposResponse.body);
    final List<GitHubEvent> results = [];

    for (final repo in repos.whereType<Map<String, dynamic>>()) {
      final fullName = repo['full_name']?.toString();
      final defaultBranch = repo['default_branch']?.toString() ?? 'main';

      if (fullName == null || fullName.isEmpty) continue;

      final commitsResponse = await http.get(
        Uri.parse(
          'https://api.github.com/repos/$fullName/commits?sha=$defaultBranch&per_page=3',
        ),
        headers: _headers(accessToken),
      );

      if (commitsResponse.statusCode != 200) continue;

      final List<dynamic> commits = jsonDecode(commitsResponse.body);

      final messages = commits
          .whereType<Map<String, dynamic>>()
          .map((commit) {
            final commitData = commit['commit'] as Map<String, dynamic>? ?? {};
            return commitData['message']?.toString().trim() ?? '';
          })
          .map(_cleanCommitMessage)
          .where((m) => m.isNotEmpty)
          .toSet()
          .take(3)
          .toList();

      if (messages.isNotEmpty) {
        results.add(
          GitHubEvent(
            repoName: fullName,
            commitMessages: messages,
            createdAt: DateTime.now(), // fallback
          ),
        );
      }
    }

    return _sortEvents(results);
  }

  // =============================
  // CLEANING
  // =============================

  static GitHubEvent _cleanEvent(GitHubEvent event) {
    final cleanedMessages = event.commitMessages
        .map(_cleanCommitMessage)
        .where((m) => m.isNotEmpty)
        .toSet()
        .take(3)
        .toList();

    return GitHubEvent(
      repoName: event.repoName,
      commitMessages: cleanedMessages,
      createdAt: event.createdAt,
    );
  }

  static String _cleanCommitMessage(String message) {
    var cleaned = message.trim();

    if (cleaned.toLowerCase().startsWith('merge')) return '';

    cleaned = cleaned.replaceAll(RegExp(r'\(#\d+\)'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

    return cleaned;
  }

  // =============================
  // SORTING (NEW)
  // =============================

  static List<GitHubEvent> _sortEvents(List<GitHubEvent> events) {
    events.sort((a, b) {
      final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });

    return events;
  }
}