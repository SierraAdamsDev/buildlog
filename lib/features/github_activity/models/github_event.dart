class GitHubEvent {
  final String repoName;
  final List<String> commitMessages;
  final DateTime? createdAt; // 👈 NEW

  const GitHubEvent({
    required this.repoName,
    required this.commitMessages,
    this.createdAt,
  });

  factory GitHubEvent.fromJson(Map<String, dynamic> json) {
    final repo = json['repo'] as Map<String, dynamic>? ?? {};
    final payload = json['payload'] as Map<String, dynamic>? ?? {};
    final commits = payload['commits'] as List<dynamic>? ?? [];

    final createdAtString = json['created_at']?.toString();

    return GitHubEvent(
      repoName: repo['name']?.toString() ?? 'Unknown Repo',
      commitMessages: commits
          .whereType<Map<String, dynamic>>()
          .map((commit) => commit['message']?.toString().trim() ?? '')
          .where((message) => message.isNotEmpty)
          .toList(),
      createdAt: createdAtString != null
          ? DateTime.tryParse(createdAtString)
          : null,
    );
  }
}