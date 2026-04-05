class GitHubEvent {
  final String repoName;
  final List<String> commitMessages;

  const GitHubEvent({
    required this.repoName,
    required this.commitMessages,
  });

  factory GitHubEvent.fromJson(Map<String, dynamic> json) {
    final repo = json['repo'] as Map<String, dynamic>? ?? {};
    final payload = json['payload'] as Map<String, dynamic>? ?? {};
    final commits = payload['commits'] as List<dynamic>? ?? [];

    return GitHubEvent(
      repoName: repo['name']?.toString() ?? 'Unknown Repo',
      commitMessages: commits
          .whereType<Map<String, dynamic>>()
          .map((commit) => commit['message']?.toString().trim() ?? '')
          .where((message) => message.isNotEmpty)
          .toList(),
    );
  }
}