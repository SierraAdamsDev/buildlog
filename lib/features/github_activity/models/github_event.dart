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
          .map((commit) => (commit as Map<String, dynamic>)['message']?.toString() ?? '')
          .where((message) => message.isNotEmpty)
          .toList(),
    );
  }
}