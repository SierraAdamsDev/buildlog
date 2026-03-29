import 'package:flutter/material.dart';

void main() {
  runApp(const BuildLogApp());
}

class BuildLogApp extends StatelessWidget {
  const BuildLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BuildLog',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F8FA),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF111827),
          brightness: Brightness.light,
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
          headlineMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            color: Color(0xFF4B5563),
            height: 1.5,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: Color(0xFF6B7280),
            height: 1.5,
          ),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

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
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Summarize your work without exposing private repos.',
                                style: theme.textTheme.headlineLarge,
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
                                    onPressed: null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF111827),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 22,
                                        vertical: 18,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: const Text('Connect GitHub'),
                                  ),
                                  OutlinedButton(
                                    onPressed: null,
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 22,
                                        vertical: 18,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      side: const BorderSide(
                                        color: Color(0xFFD1D5DB),
                                      ),
                                    ),
                                    child: const Text('See Example Output'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 36),
                              const Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  _FeatureChip(label: 'Public + private activity'),
                                  _FeatureChip(label: 'Privacy-safe summaries'),
                                  _FeatureChip(label: 'Platform-ready drafts'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
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
                          child: const _PreviewCard(),
                        ),
                      ),
                    ],
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

class _FeatureChip extends StatelessWidget {
  final String label;

  const _FeatureChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF374151),
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preview',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: 20,
              ),
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Repo: buildlog',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Recent work',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                ),
              ),
              SizedBox(height: 10),
              Text('• Added homepage structure'),
              Text('• Cleaned up default app layout'),
              Text('• Started platform-ready summary flow'),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LinkedIn draft',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF9CA3AF),
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Built the first pass of BuildLog today. I cleaned up the default app structure, added a homepage, and started shaping how GitHub activity will turn into readable updates.',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}