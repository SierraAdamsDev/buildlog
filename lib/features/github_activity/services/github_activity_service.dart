import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/github_event.dart';

class GitHubActivityService {
  static Map<String, String> _headers(String token) {
    return {
      'Accept': 'application/vnd.github+json',
      'Authorization': 'Bearer $token',
      'X-GitHub-Api-Version': '2022-11-28',
    };
  }

  static Future<List<GitHubEvent>> fetchPublicActivity(String username) async {
    final response = await http.get(
      Uri.parse('https://api.github.com/users/$username/events/public?per_page=100'),
      headers: {
        'Accept': 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'GitHub public activity failed. Status: ${response.statusCode}. Body: ${response.body}',
      );
    }

    final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;

    final pushEvents = data
        .whereType<Map<String, dynamic>>()
        .where((event) => event['type'] == 'PushEvent')
        .map(GitHubEvent.fromJson)
        .where((event) => event.commitMessages.isNotEmpty)
        .toList();

    return pushEvents;
  }

  static Future<List<GitHubEvent>> fetchPrivateActivity(String accessToken) async {
    final userResponse = await http.get(
      Uri.parse('https://api.github.com/user'),
      headers: _headers(accessToken),
    );

    if (userResponse.statusCode != 200) {
      throw Exception(
        'GitHub user lookup failed. Status: ${userResponse.statusCode}. Body: ${userResponse.body}',
      );
    }

    final userData = jsonDecode(userResponse.body) as Map<String, dynamic>;
    final login = userData['login']?.toString();

    if (login == null || login.isEmpty) {
      throw Exception('Could not determine authenticated GitHub username.');
    }

    final eventsResponse = await http.get(
      Uri.parse('https://api.github.com/users/$login/events?per_page=100'),
      headers: _headers(accessToken),
    );

    if (eventsResponse.statusCode != 200) {
      throw Exception(
        'GitHub private activity failed. Status: ${eventsResponse.statusCode}. Body: ${eventsResponse.body}',
      );
    }

    final List<dynamic> data = jsonDecode(eventsResponse.body) as List<dynamic>;

    final pushEvents = data
        .whereType<Map<String, dynamic>>()
        .where((event) => event['type'] == 'PushEvent')
        .map(GitHubEvent.fromJson)
        .where((event) => event.commitMessages.isNotEmpty)
        .toList();

    return pushEvents;
  }
}