import 'package:flutter/material.dart';
import 'package:buildlog/shared/widgets/feature_chip.dart';
import 'package:buildlog/shared/widgets/preview_card.dart';
import 'package:buildlog/features/home/presentation/widgets/github_input_section.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});
   final GlobalKey _githubSectionKey = GlobalKey();
   
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BuildLog',
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: const Text(
                    'Turn GitHub activity into platform-ready updates',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                /// MAIN CONTENT
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        /// HERO SECTION
                        SizedBox(
                          height: 560,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.only(right: 24),
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Summarize your work without exposing private repos.',
                                        style:
                                            theme.textTheme.headlineLarge,
                                      ),
                                      const SizedBox(height: 20),
                                      Text(
                                        'BuildLog helps developers turn GitHub activity into clean summaries and platform-specific drafts for LinkedIn, X, Reddit, Discord, and more.',
                                        style:
                                            theme.textTheme.bodyLarge,
                                      ),
                                      const SizedBox(height: 28),
                                      Wrap(
                                        spacing: 12,
                                        runSpacing: 12,
                                        children: [
                                          ElevatedButton(
                                            onPressed: () {
                                              Scrollable.ensureVisible(
                                                _githubSectionKey.currentContext!,
                                                duration: const Duration(milliseconds: 500),
                                              );
                                            },
                                            child: const Text('Connect GitHub'),
                                          ),

                                          const SizedBox(width: 12),

                                          OutlinedButton(
                                            onPressed: () {
                                              Scrollable.ensureVisible(
                                                _githubSectionKey.currentContext!,
                                                duration: const Duration(milliseconds: 500),
                                              );
                                            },
                                            child: const Text('Try Public Mode'),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 36),
                                      const Wrap(
                                        spacing: 12,
                                        runSpacing: 12,
                                        children: [
                                          FeatureChip(
                                              label:
                                                  'Public + Private Activity'),
                                          FeatureChip(
                                              label:
                                                  'Privacy-Safe Summaries'),
                                          FeatureChip(
                                              label:
                                                  'Platform-Ready Drafts'),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const Expanded(
                                child: _PreviewCardShell(),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        /// NEW SECTION (GitHub Input)
                        Container(
                          key: _githubSectionKey,
                          child: const GitHubInputSection(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PreviewCardShell extends StatelessWidget {
  const _PreviewCardShell();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 30,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: const PreviewCard(),
    );
  }
}