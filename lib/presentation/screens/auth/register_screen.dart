import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/glassmorphism.dart';
import '../../../core/widgets/gradient_scaffold.dart';
import '../../../core/widgets/neon_button.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _teamNameController = TextEditingController();
  final _memberControllers = <TextEditingController>[
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];

  @override
  void dispose() {
    _teamNameController.dispose();
    for (final c in _memberControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addMember() {
    if (_memberControllers.length < 4) {
      setState(() {
        _memberControllers.add(TextEditingController());
      });
    }
  }

  void _removeMember(int index) {
    if (_memberControllers.length > 3) {
      setState(() {
        _memberControllers[index].dispose();
        _memberControllers.removeAt(index);
      });
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final members = _memberControllers
        .map((c) => c.text.trim())
        .where((m) => m.isNotEmpty)
        .toList();

    if (members.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.errorMinMembers)),
      );
      return;
    }

    await ref.read(authProvider.notifier).registerTeam(
          teamName: _teamNameController.text.trim(),
          members: members,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return GradientScaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),

                // ── Logo & Title ──
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: AppColors.primaryGradient,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.neonCyan.withOpacity(0.4),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.explore_rounded,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        AppStrings.appName.toUpperCase(),
                        style: GoogleFonts.orbitron(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4,
                          foreground: Paint()
                            ..shader = const LinearGradient(
                              colors: AppColors.primaryGradient,
                            ).createShader(
                              const Rect.fromLTWH(0, 0, 250, 50),
                            ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppStrings.appTagline,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.3),

                const SizedBox(height: 48),

                // ── Registration Form ──
                GlassmorphicContainer(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.registerTeam,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 24),

                      // Team Name
                      TextFormField(
                        controller: _teamNameController,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: AppStrings.teamName,
                          prefixIcon: const Icon(Icons.groups_rounded,
                              color: AppColors.neonCyan),
                        ),
                        validator: (v) =>
                            v != null && v.trim().isNotEmpty
                                ? null
                                : 'Enter team name',
                      ),
                      const SizedBox(height: 24),

                      // Members
                      Text(
                        'Team Members (3-4)',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 12),

                      ...List.generate(_memberControllers.length, (i) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _memberControllers[i],
                                  style: const TextStyle(
                                      color: AppColors.textPrimary),
                                  decoration: InputDecoration(
                                    hintText: '${AppStrings.memberName} ${i + 1}',
                                    prefixIcon: const Icon(
                                      Icons.person_rounded,
                                      color: AppColors.neonPurple,
                                    ),
                                  ),
                                  validator: (v) =>
                                      v != null && v.trim().isNotEmpty
                                          ? null
                                          : 'Enter member name',
                                ),
                              ),
                              if (i >= 3)
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline,
                                      color: AppColors.error),
                                  onPressed: () => _removeMember(i),
                                ),
                            ],
                          ),
                        ).animate().fadeIn(delay: (100 * i).ms).slideX(begin: 0.2);
                      }),

                      if (_memberControllers.length < 4)
                        TextButton.icon(
                          onPressed: _addMember,
                          icon: const Icon(Icons.add_circle_outline,
                              color: AppColors.neonGreen),
                          label: Text(
                            AppStrings.addMember,
                            style: TextStyle(color: AppColors.neonGreen),
                          ),
                        ),

                      const SizedBox(height: 24),

                      // Error
                      if (authState.error != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.error.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            authState.error!,
                            style: const TextStyle(
                                color: AppColors.error, fontSize: 13),
                          ),
                        ),

                      // Submit
                      NeonButton(
                        text: AppStrings.createTeam,
                        icon: Icons.rocket_launch_rounded,
                        onPressed: _register,
                        isLoading: authState.status == AuthStatus.loading,
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),

                const SizedBox(height: 24),

                // Login link
                Center(
                  child: TextButton(
                    onPressed: () {
                      context.go('/login');
                    },
                    child: RichText(
                      text: TextSpan(
                        text: '${AppStrings.alreadyRegistered} ',
                        style: Theme.of(context).textTheme.bodyMedium,
                        children: [
                          TextSpan(
                            text: AppStrings.loginTeam,
                            style: const TextStyle(
                              color: AppColors.neonCyan,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
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

