import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/github_event.dart';

class GitHubActivityService {
  static const Map<String, String> _baseHeaders = {
    'Accept': 'application/vnd.github+json',
  };

  static Future<List<GitHubEvent>> fetchPublicActivity(String username) async {
    final pushEvents = await _fetchPublicPushEvents(username);

    if (pushEvents.isNotEmpty) {
      return pushEvents;
    }

    return _fetchPublicRepoCommits(username);
  }

  static Future<List<GitHubEvent>> fetchPrivateActivity(String token) async {
    final pushEvents = await _fetchAuthenticatedPushEvents(token);

    if (pushEvents.isNotEmpty) {
      return pushEvents;
    }

    return _fetchAuthenticatedRepoCommits(token);
  }

  static Future<List<GitHubEvent>> _fetchPublicPushEvents(String username) async {
    final uri = Uri.parse('https://api.github.com/users/$username/events/public');

    final response = await http.get(uri, headers: _baseHeaders);

    if (response.statusCode == 404) {
      throw Exception('GitHub user not found.');
    }

    if (response.statusCode != 200) {
      throw Exception('Failed to load GitHub activity.');
    }

    final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;

    return data
        .where((event) => event is Map<String, dynamic> && event['type'] == 'PushEvent')
        .map((event) => GitHubEvent.fromJson(event as Map<String, dynamic>))
        .where((event) => event.commitMessages.isNotEmpty)
        .toList();
  }

  static Future<List<GitHubEvent>> _fetchAuthenticatedPushEvents(String token) async {
    final uri = Uri.parse('https://api.github.com/user/events');

    final response = await http.get(
      uri,
      headers: {
        ..._baseHeaders,
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load private GitHub activity.');
    }

    final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;

    return data
        .where((event) => event is Map<String, dynamic> && event['type'] == 'PushEvent')
        .map((event) => GitHubEvent.fromJson(event as Map<String, dynamic>))
        .where((event) => event.commitMessages.isNotEmpty)
        .toList();
  }

  static Future<List<GitHubEvent>> _fetchPublicRepoCommits(String username) async {
    final reposUri = Uri.parse(
      'https://api.github.com/users/$username/repos?sort=updated&per_page=5',
    );

    final reposResponse = await http.get(reposUri, headers: _baseHeaders);

    if (reposResponse.statusCode == 404) {
      throw Exception('GitHub user not found.');
    }

    if (reposResponse.statusCode != 200) {
      throw Exception('Failed to load public repositories.');
    }

    final List<dynamic> repos = jsonDecode(reposResponse.body) as List<dynamic>;
    final List<GitHubEvent> results = [];

    for (final repo in repos) {
      final repoMap = repo as Map<String, dynamic>;
      final fullName = repoMap['full_name']?.toString();

      if (fullName == null || fullName.isEmpty) continue;

      final commitsUri = Uri.parse(
        'https://api.github.com/repos/$fullName/commits?per_page=3',
      );

      final commitsResponse = await http.get(commitsUri, headers: _baseHeaders);

      if (commitsResponse.statusCode != 200) continue;

      final List<dynamic> commits = jsonDecode(commitsResponse.body) as List<dynamic>;

      final messages = commits
          .map((commit) {
            final map = commit as Map<String, dynamic>;
            final commitData = map['commit'] as Map<String, dynamic>? ?? {};
            return commitData['message']?.toString() ?? '';
          })
          .where((message) => message.isNotEmpty)
          .toList();

      if (messages.isNotEmpty) {
        results.add(
          GitHubEvent(
            repoName: fullName,
            commitMessages: messages,
          ),
        );
      }
    }

    return results;
  }

  static Future<List<GitHubEvent>> _fetchAuthenticatedRepoCommits(String token) async {
    final reposUri = Uri.parse(
      'https://api.github.com/user/repos?sort=updated&per_page=5',
    );

    final reposResponse = await http.get(
      reposUri,
      headers: {
        ..._baseHeaders,
        'Authorization': 'Bearer $token',
      },
    );

    if (reposResponse.statusCode != 200) {
      throw Exception('Failed to load repositories from connected GitHub account.');
    }

    final List<dynamic> repos = jsonDecode(reposResponse.body) as List<dynamic>;
    final List<GitHubEvent> results = [];

    for (final repo in repos) {
      final repoMap = repo as Map<String, dynamic>;
      final fullName = repoMap['full_name']?.toString();
      final defaultBranch = repoMap['default_branch']?.toString() ?? 'main';

      if (fullName == null || fullName.isEmpty) continue;

      final commitsUri = Uri.parse(
        'https://api.github.com/repos/$fullName/commits?sha=$defaultBranch&per_page=3',
      );

      final commitsResponse = await http.get(
        commitsUri,
        headers: {
          ..._baseHeaders,
          'Authorization': 'Bearer $token',
        },
      );

      if (commitsResponse.statusCode != 200) continue;

      final List<dynamic> commits = jsonDecode(commitsResponse.body) as List<dynamic>;

      final messages = commits
          .map((commit) {
            final map = commit as Map<String, dynamic>;
            final commitData = map['commit'] as Map<String, dynamic>? ?? {};
            return commitData['message']?.toString() ?? '';
          })
          .where((message) => message.isNotEmpty)
          .toList();

      if (messages.isNotEmpty) {
        results.add(
          GitHubEvent(
            repoName: fullName,
            commitMessages: messages,
          ),
        );
      }
    }

    return results;
  }
}