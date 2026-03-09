import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/challenge.dart';

/// Styled chip showing challenge category with icon and neon glow
class CategoryChip extends StatelessWidget {
  final ChallengeCategory category;

  const CategoryChip({super.key, required this.category});

  IconData get _icon {
    switch (category) {
      case ChallengeCategory.logicalReasoning:
        return Icons.psychology_rounded;
      case ChallengeCategory.algorithmOutput:
        return Icons.code_rounded;
      case ChallengeCategory.codeDebugging:
        return Icons.bug_report_rounded;
      case ChallengeCategory.mathPuzzle:
        return Icons.calculate_rounded;
      case ChallengeCategory.technicalReasoning:
        return Icons.engineering_rounded;
      case ChallengeCategory.observational:
        return Icons.visibility_rounded;
    }
  }

  String get _label {
    switch (category) {
      case ChallengeCategory.logicalReasoning:
        return 'Logic';
      case ChallengeCategory.algorithmOutput:
        return 'Algorithm';
      case ChallengeCategory.codeDebugging:
        return 'Debug';
      case ChallengeCategory.mathPuzzle:
        return 'Math';
      case ChallengeCategory.technicalReasoning:
        return 'Technical';
      case ChallengeCategory.observational:
        return 'Observe';
    }
  }

  Color get _color {
    switch (category) {
      case ChallengeCategory.logicalReasoning:
        return AppColors.neonPurple;
      case ChallengeCategory.algorithmOutput:
        return AppColors.neonCyan;
      case ChallengeCategory.codeDebugging:
        return AppColors.neonOrange;
      case ChallengeCategory.mathPuzzle:
        return AppColors.neonGreen;
      case ChallengeCategory.technicalReasoning:
        return AppColors.neonPink;
      case ChallengeCategory.observational:
        return AppColors.neonYellow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, color: _color, size: 14),
          const SizedBox(width: 4),
          Text(
            _label,
            style: GoogleFonts.inter(
              color: _color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

