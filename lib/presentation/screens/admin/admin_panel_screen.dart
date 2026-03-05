import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/glassmorphism.dart';
import '../../../core/widgets/gradient_scaffold.dart';
import '../../../core/widgets/neon_app_bar.dart';
import '../../../core/widgets/neon_button.dart';

/// Admin Panel Screen — Event management dashboard
/// In production, this would be a web dashboard.
/// This is a mobile-accessible version for event organizers.
class AdminPanelScreen extends ConsumerStatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  ConsumerState<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends ConsumerState<AdminPanelScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: const NeonAppBar(title: 'ADMIN PANEL'),
      body: SafeArea(
        child: Column(
          children: [
            // Tab bar
            _buildTabBar(),
            const SizedBox(height: 16),
            // Tab content
            Expanded(
              child: IndexedStack(
                index: _selectedTab,
                children: const [
                  _TeamsOverviewTab(),
                  _ChallengesManagementTab(),
                  _EventControlTab(),
                  _AnalyticsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    final tabs = ['Teams', 'Challenges', 'Event', 'Analytics'];
    final icons = [
      Icons.groups_rounded,
      Icons.flag_rounded,
      Icons.settings_rounded,
      Icons.analytics_rounded,
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder, width: 0.5),
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final isSelected = _selectedTab == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.neonCyan.withOpacity(0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected
                      ? Border.all(
                          color: AppColors.neonCyan.withOpacity(0.4))
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icons[i],
                      size: 18,
                      color: isSelected
                          ? AppColors.neonCyan
                          : AppColors.textMuted,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tabs[i],
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? AppColors.neonCyan
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// ── Teams Overview Tab ──
class _TeamsOverviewTab extends StatelessWidget {
  const _TeamsOverviewTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats row
          Row(
            children: [
              _AdminStatCard(
                title: 'Total Teams',
                value: '—',
                icon: Icons.groups_rounded,
                color: AppColors.neonCyan,
              ),
              const SizedBox(width: 12),
              _AdminStatCard(
                title: 'Active Now',
                value: '—',
                icon: Icons.play_circle_rounded,
                color: AppColors.neonGreen,
              ),
              const SizedBox(width: 12),
              _AdminStatCard(
                title: 'Completed',
                value: '—',
                icon: Icons.check_circle_rounded,
                color: AppColors.neonPurple,
              ),
            ].map((e) => Expanded(child: e)).toList(),
          ).animate().fadeIn(),

          const SizedBox(height: 24),

          Text(
            'Live Teams',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),

          // Placeholder for live team list
          GlassmorphicContainer(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.cloud_sync_rounded,
                      color: AppColors.textMuted, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'Connect Firebase to view live team data',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 200.ms),
        ],
      ),
    );
  }
}

/// ── Challenges Management Tab ──
class _ChallengesManagementTab extends StatelessWidget {
  const _ChallengesManagementTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NeonButton(
            text: 'Seed Sample Challenges',
            icon: Icons.add_location_alt_rounded,
            color: AppColors.neonGreen,
            onPressed: () {
              // TODO: Implement seed data upload
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content:
                        Text('Connect Firebase and run seed script first')),
              );
            },
          ).animate().fadeIn(),
          const SizedBox(height: 16),

          NeonButton(
            text: 'Add New Challenge',
            icon: Icons.add_rounded,
            color: AppColors.neonCyan,
            onPressed: () {
              _showAddChallengeDialog(context);
            },
          ).animate().fadeIn(delay: 100.ms),

          const SizedBox(height: 24),

          Text(
            'Challenge Locations',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),

          GlassmorphicContainer(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.map_rounded,
                      color: AppColors.textMuted, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'Challenge locations will appear here\nafter Firebase connection',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 200.ms),
        ],
      ),
    );
  }

  void _showAddChallengeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Add Challenge',
          style: GoogleFonts.orbitron(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'To add challenges, use the Firebase console or the seed script '
                'at scripts/seed_challenges.dart.\n\n'
                'Each challenge requires:\n'
                '• Title & Description\n'
                '• GPS coordinates (lat/lng)\n'
                '• Category & Difficulty\n'
                '• Question & Answer\n'
                '• Points & Time Limit',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: AppColors.neonCyan)),
          ),
        ],
      ),
    );
  }
}

/// ── Event Control Tab ──
class _EventControlTab extends StatelessWidget {
  const _EventControlTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassmorphicContainer(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Event Configuration',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                _ConfigRow(label: 'Session Duration', value: '2 hours'),
                _ConfigRow(label: 'Geofence Radius', value: '20 meters'),
                _ConfigRow(label: 'Skip Penalty', value: '-10 pts'),
                _ConfigRow(label: 'Target Score', value: '500 pts'),
                _ConfigRow(label: 'Max Teams', value: '100'),
              ],
            ),
          ).animate().fadeIn(),
          const SizedBox(height: 20),

          NeonButton(
            text: 'Reset All Sessions',
            icon: Icons.restart_alt_rounded,
            color: AppColors.error,
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppColors.surface,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  title: const Text('Confirm Reset',
                      style: TextStyle(color: AppColors.textPrimary)),
                  content: const Text(
                    'This will end all active sessions and reset the leaderboard. '
                    'This action cannot be undone.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel',
                          style: TextStyle(color: AppColors.textMuted)),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Reset triggered (connect Firebase)')),
                        );
                      },
                      child: const Text('Reset',
                          style: TextStyle(color: AppColors.error)),
                    ),
                  ],
                ),
              );
            },
          ).animate().fadeIn(delay: 100.ms),
        ],
      ),
    );
  }
}

class _ConfigRow extends StatelessWidget {
  final String label;
  final String value;

  const _ConfigRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.neonCyan.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: GoogleFonts.orbitron(
                color: AppColors.neonCyan,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ── Analytics Tab ──
class _AnalyticsTab extends StatelessWidget {
  const _AnalyticsTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _AdminStatCard(
                  title: 'Avg Score',
                  value: '—',
                  icon: Icons.score_rounded,
                  color: AppColors.neonCyan,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _AdminStatCard(
                  title: 'Avg Time',
                  value: '—',
                  icon: Icons.timer_rounded,
                  color: AppColors.neonPurple,
                ),
              ),
            ],
          ).animate().fadeIn(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _AdminStatCard(
                  title: 'Accuracy',
                  value: '—',
                  icon: Icons.check_rounded,
                  color: AppColors.neonGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _AdminStatCard(
                  title: 'Skips',
                  value: '—',
                  icon: Icons.skip_next_rounded,
                  color: AppColors.neonOrange,
                ),
              ),
            ],
          ).animate().fadeIn(delay: 100.ms),

          const SizedBox(height: 24),

          Text(
            'Category Performance',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),

          ..._buildCategoryBars(context),
        ],
      ),
    );
  }

  List<Widget> _buildCategoryBars(BuildContext context) {
    final categories = [
      ('Logical Reasoning', 0.72, AppColors.neonPurple),
      ('Algorithm Output', 0.58, AppColors.neonCyan),
      ('Code Debugging', 0.45, AppColors.neonOrange),
      ('Math Puzzle', 0.65, AppColors.neonGreen),
      ('Technical Reasoning', 0.52, AppColors.neonPink),
      ('Observational', 0.80, AppColors.neonYellow),
    ];

    return categories.asMap().entries.map((entry) {
      final (label, progress, color) = entry.value;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label,
                    style: Theme.of(context).textTheme.bodySmall),
                Text(
                  '${(progress * 100).toInt()}% accuracy',
                  style: GoogleFonts.inter(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Stack(
              children: [
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, color.withOpacity(0.5)],
                      ),
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.4),
                          blurRadius: 6,
                          spreadRadius: -1,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ).animate().fadeIn(delay: (100 * entry.key).ms).slideX(begin: 0.1);
    }).toList();
  }
}

/// Reusable admin stat card
class _AdminStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _AdminStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassmorphicContainer(
      borderRadius: 14,
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.orbitron(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.inter(
              color: AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

