import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/glassmorphism.dart';
import '../../../core/widgets/gradient_scaffold.dart';
import '../../../core/widgets/neon_button.dart';
import '../../../domain/entities/team.dart';
import '../../providers/auth_provider.dart';

/// Screen for creating or joining a team after Google Sign-In
class TeamScreen extends ConsumerStatefulWidget {
  const TeamScreen({super.key});

  @override
  ConsumerState<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends ConsumerState<TeamScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _createFormKey = GlobalKey<FormState>();
  final _joinFormKey = GlobalKey<FormState>();
  final _teamNameController = TextEditingController();
  final _teamIdController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  List<Team>? _availableTeams;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTeams();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _teamNameController.dispose();
    _teamIdController.dispose();
    super.dispose();
  }

  Future<void> _loadTeams() async {
    try {
      final teams = await ref.read(authProvider.notifier).getTeams();
      if (mounted) setState(() => _availableTeams = teams);
    } catch (_) {
      // Teams will be null, that's OK
    }
  }

  Future<void> _createTeam() async {
    if (!_createFormKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await ref.read(authProvider.notifier).createTeam(
            _teamNameController.text.trim(),
          );
      if (mounted) context.go('/home');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _joinTeam(String teamId) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await ref.read(authProvider.notifier).joinTeam(teamId);
      if (mounted) context.go('/home');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),

            // ── Header ──
            Text(
              'TEAM UP',
              style: GoogleFonts.orbitron(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: 4,
                foreground: Paint()
                  ..shader = const LinearGradient(
                    colors: AppColors.primaryGradient,
                  ).createShader(const Rect.fromLTWH(0, 0, 250, 40)),
              ),
            ).animate().fadeIn(duration: 500.ms),

            const SizedBox(height: 8),
            Text(
              'Create a new team or join an existing one',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 24),

            // ── Tabs ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GlassmorphicContainer(
                padding: const EdgeInsets.all(4),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      colors: AppColors.primaryGradient,
                    ),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.textSecondary,
                  labelStyle: GoogleFonts.orbitron(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  tabs: const [
                    Tab(text: 'CREATE'),
                    Tab(text: 'JOIN'),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 300.ms),

            const SizedBox(height: 24),

            // ── Error ──
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: AppColors.error.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(
                              color: AppColors.error, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Tab views ──
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildCreateTab(),
                  _buildJoinTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _createFormKey,
        child: GlassmorphicContainer(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.neonCyan.withOpacity(0.15),
                    ),
                    child: const Icon(Icons.group_add_rounded,
                        color: AppColors.neonCyan, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'New Team',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _teamNameController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Enter team name',
                  prefixIcon:
                      Icon(Icons.badge_rounded, color: AppColors.neonCyan),
                ),
                validator: (v) => v != null && v.trim().isNotEmpty
                    ? null
                    : 'Team name is required',
              ),

              const SizedBox(height: 12),
              Text(
                'Max 4 members per team. Others can join using your team ID.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
              ),

              const SizedBox(height: 28),

              NeonButton(
                text: 'Create Team',
                icon: Icons.rocket_launch_rounded,
                onPressed: _createTeam,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2);
  }

  Widget _buildJoinTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // ── Join by ID ──
          Form(
            key: _joinFormKey,
            child: GlassmorphicContainer(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.neonPurple.withOpacity(0.15),
                        ),
                        child: const Icon(Icons.login_rounded,
                            color: AppColors.neonPurple, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Join by Team ID',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  TextFormField(
                    controller: _teamIdController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'Enter team ID',
                      prefixIcon:
                          Icon(Icons.key_rounded, color: AppColors.neonPurple),
                    ),
                    validator: (v) => v != null && v.trim().isNotEmpty
                        ? null
                        : 'Enter the team ID',
                  ),
                  const SizedBox(height: 24),

                  NeonButton(
                    text: 'Join Team',
                    icon: Icons.group_rounded,
                    onPressed: () {
                      if (_joinFormKey.currentState!.validate()) {
                        _joinTeam(_teamIdController.text.trim());
                      }
                    },
                    isLoading: _isLoading,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ── Available teams ──
          if (_availableTeams != null && _availableTeams!.isNotEmpty) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Available Teams',
                style: GoogleFonts.orbitron(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ...(_availableTeams!.map((team) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GlassmorphicContainer(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: AppColors.cyanGradient,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              team.teamName[0].toUpperCase(),
                              style: GoogleFonts.orbitron(
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                team.teamName,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${team.members.length}/4 members',
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (team.members.length < 4)
                          TextButton(
                            onPressed: () => _joinTeam(team.id),
                            child: const Text(
                              'JOIN',
                              style: TextStyle(
                                color: AppColors.neonCyan,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ))),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2);
  }
}
