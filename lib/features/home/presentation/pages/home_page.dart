import 'package:flutter/material.dart';
import 'package:buildlog/shared/widgets/feature_chip.dart';
import 'package:buildlog/shared/widgets/preview_card.dart';
import 'package:buildlog/features/home/presentation/widgets/github_input_section.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

  final GlobalKey _githubSectionKey = GlobalKey();

  void _scrollToGitHubSection() {
    final context = _githubSectionKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isMobile = width < 768;
            final isTablet = width >= 768 && width < 1100;

            final horizontalPadding = isMobile
                ? 16.0
                : isTablet
                    ? 20.0
                    : 24.0;

            final verticalPadding = isMobile ? 20.0 : 40.0;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: verticalPadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BuildLog',
                        style: isMobile
                            ? theme.textTheme.headlineSmall
                            : theme.textTheme.headlineMedium,
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
                      SizedBox(height: isMobile ? 24 : 32),

                      /// HERO SECTION
                      isMobile
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _HeroTextSection(
                                  theme: theme,
                                  isMobile: true,
                                  onConnectTap: _scrollToGitHubSection,
                                ),
                                const SizedBox(height: 24),
                                const _PreviewCardShell(),
                              ],
                            )
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 24),
                                    child: _HeroTextSection(
                                      theme: theme,
                                      isMobile: false,
                                      onConnectTap: _scrollToGitHubSection,
                                    ),
                                  ),
                                ),
                                const Expanded(
                                  child: _PreviewCardShell(),
                                ),
                              ],
                            ),

                      const SizedBox(height: 24),

                      /// GITHUB INPUT SECTION
                      Container(
                        key: _githubSectionKey,
                        child: const GitHubInputSection(),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HeroTextSection extends StatelessWidget {
  final ThemeData theme;
  final bool isMobile;
  final VoidCallback onConnectTap;

  const _HeroTextSection({
    required this.theme,
    required this.isMobile,
    required this.onConnectTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment:
          isMobile ? MainAxisAlignment.start : MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Summarize your work without exposing private repos.',
          style: isMobile
              ? theme.textTheme.headlineMedium
              : theme.textTheme.headlineLarge,
        ),
        const SizedBox(height: 20),
        Text(
          'BuildLog helps developers turn GitHub activity into clean summaries and platform-specific drafts for LinkedIn, X, Reddit, Discord, and more.',
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 28),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ElevatedButton(
              onPressed: onConnectTap,
              child: const Text('Connect GitHub'),
            ),
            OutlinedButton(
              onPressed: onConnectTap,
              child: const Text('Try Public Mode'),
            ),
          ],
        ),
        const SizedBox(height: 36),
        const Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FeatureChip(label: 'Public + Private Activity'),
            FeatureChip(label: 'Privacy-Safe Summaries'),
            FeatureChip(label: 'Platform-Ready Drafts'),
          ],
        ),
      ],
    );
  }
}

class _PreviewCardShell extends StatelessWidget {
  const _PreviewCardShell();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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