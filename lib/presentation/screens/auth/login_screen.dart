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

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _teamIdController = TextEditingController();

  @override
  void dispose() {
    _teamIdController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authProvider.notifier).loginTeam(
          _teamIdController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return GradientScaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── Logo ──
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: AppColors.primaryGradient,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.neonCyan.withOpacity(0.4),
                          blurRadius: 40,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.explore_rounded,
                      size: 50,
                      color: Colors.white,
                    ),
                  ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),

                  const SizedBox(height: 24),
                  Text(
                    AppStrings.appName.toUpperCase(),
                    style: GoogleFonts.orbitron(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                      foreground: Paint()
                        ..shader = const LinearGradient(
                          colors: AppColors.primaryGradient,
                        ).createShader(const Rect.fromLTWH(0, 0, 300, 50)),
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.joinEvent,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ).animate().fadeIn(delay: 400.ms),

                  const SizedBox(height: 48),

                  // ── Login Card ──
                  GlassmorphicContainer(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      children: [
                        Text(
                          AppStrings.loginTeam,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 24),

                        TextFormField(
                          controller: _teamIdController,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            hintText: AppStrings.enterTeamId,
                            prefixIcon: const Icon(Icons.key_rounded,
                                color: AppColors.neonCyan),
                          ),
                          validator: (v) =>
                              v != null && v.trim().isNotEmpty
                                  ? null
                                  : 'Enter your Team ID',
                        ),

                        const SizedBox(height: 24),

                        if (authState.error != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppColors.error.withOpacity(0.3)),
                            ),
                            child: Text(
                              authState.error!,
                              style: const TextStyle(
                                  color: AppColors.error, fontSize: 13),
                            ),
                          ),

                        NeonButton(
                          text: AppStrings.joinEvent,
                          icon: Icons.login_rounded,
                          onPressed: _login,
                          isLoading: authState.status == AuthStatus.loading,
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.3),

                  const SizedBox(height: 24),

                  TextButton(
                    onPressed: () {
                      context.go('/register');
                    },
                    child: RichText(
                      text: TextSpan(
                        text: '${AppStrings.newTeam} ',
                        style: Theme.of(context).textTheme.bodyMedium,
                        children: const [
                          TextSpan(
                            text: AppStrings.registerTeam,
                            style: TextStyle(
                              color: AppColors.neonCyan,
                              fontWeight: FontWeight.w700,
                            ),
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
      ),
    );
  }
}

