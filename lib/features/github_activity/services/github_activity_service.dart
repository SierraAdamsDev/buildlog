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

  static Future<List<GitHubEvent>> fetchPublicActivity(String username) async {
    final pushEvents = await _fetchPublicPushEvents(username);

    if (pushEvents.isNotEmpty) {
      return pushEvents;
    }

    return _fetchPublicRepoCommits(username);
  }

  static Future<List<GitHubEvent>> fetchPrivateActivity(String accessToken) async {
    final pushEvents = await _fetchPrivatePushEvents(accessToken);

    if (pushEvents.isNotEmpty) {
      return pushEvents;
    }

    return _fetchPrivateRepoCommits(accessToken);
  }

  static Future<List<GitHubEvent>> _fetchPublicPushEvents(String username) async {
    final response = await http.get(
      Uri.parse('https://api.github.com/users/$username/events/public?per_page=100'),
      headers: _headers(),
    );

    if (response.statusCode == 404) {
      throw Exception('GitHub user not found.');
    }

    if (response.statusCode != 200) {
      throw Exception(
        'GitHub public activity failed. Status: ${response.statusCode}. Body: ${response.body}',
      );
    }

    final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;

    return data
        .whereType<Map<String, dynamic>>()
        .where((event) => event['type'] == 'PushEvent')
        .map(GitHubEvent.fromJson)
        .where((event) => event.commitMessages.isNotEmpty)
        .toList();
  }

  static Future<List<GitHubEvent>> _fetchPrivatePushEvents(String accessToken) async {
    final response = await http.get(
      Uri.parse('https://api.github.com/user/events?per_page=100'),
      headers: _headers(accessToken),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'GitHub private activity failed. Status: ${response.statusCode}. Body: ${response.body}',
      );
    }

    final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;

    return data
        .whereType<Map<String, dynamic>>()
        .where((event) => event['type'] == 'PushEvent')
        .map(GitHubEvent.fromJson)
        .where((event) => event.commitMessages.isNotEmpty)
        .toList();
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
      throw Exception(
        'Failed to load public repositories. Status: ${reposResponse.statusCode}. Body: ${reposResponse.body}',
      );
    }

    final List<dynamic> repos = jsonDecode(reposResponse.body) as List<dynamic>;
    final List<GitHubEvent> results = [];

    for (final repo in repos.whereType<Map<String, dynamic>>()) {
      final fullName = repo['full_name']?.toString();
      if (fullName == null || fullName.isEmpty) continue;

      final commitsResponse = await http.get(
        Uri.parse('https://api.github.com/repos/$fullName/commits?per_page=3'),
        headers: _headers(),
      );

      if (commitsResponse.statusCode != 200) continue;

      final List<dynamic> commits = jsonDecode(commitsResponse.body) as List<dynamic>;

      final messages = commits
          .whereType<Map<String, dynamic>>()
          .map((commit) {
            final commitData = commit['commit'] as Map<String, dynamic>? ?? {};
            return commitData['message']?.toString().trim() ?? '';
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

  static Future<List<GitHubEvent>> _fetchPrivateRepoCommits(String accessToken) async {
    final reposResponse = await http.get(
      Uri.parse('https://api.github.com/user/repos?sort=updated&per_page=5'),
      headers: _headers(accessToken),
    );

    if (reposResponse.statusCode != 200) {
      throw Exception(
        'Failed to load private repositories. Status: ${reposResponse.statusCode}. Body: ${reposResponse.body}',
      );
    }

    final List<dynamic> repos = jsonDecode(reposResponse.body) as List<dynamic>;
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

      final List<dynamic> commits = jsonDecode(commitsResponse.body) as List<dynamic>;

      final messages = commits
          .whereType<Map<String, dynamic>>()
          .map((commit) {
            final commitData = commit['commit'] as Map<String, dynamic>? ?? {};
            return commitData['message']?.toString().trim() ?? '';
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