import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/github_event.dart';

class GitHubActivityService {
  static Future<List<GitHubEvent>> fetchPublicPushEvents(String username) async {
    final uri = Uri.parse('https://api.github.com/users/$username/events/public');

    final response = await http.get(
      uri,
      headers: {
        'Accept': 'application/vnd.github+json',
      },
    );

    if (response.statusCode == 404) {
      throw Exception('GitHub user not found.');
    }

    if (response.statusCode != 200) {
      throw Exception('Failed to load GitHub activity.');
    }

    final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;

    final pushEvents = data
        .where((event) => event is Map<String, dynamic> && event['type'] == 'PushEvent')
        .map((event) => GitHubEvent.fromJson(event as Map<String, dynamic>))
        .where((event) => event.commitMessages.isNotEmpty)
        .toList();

    return pushEvents;
  }
}