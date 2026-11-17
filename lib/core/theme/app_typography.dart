import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  // Primary font: Inter
  static TextStyle get appTitle => GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w400,
        color: AppColors.black,
        height: 1.2,
      );

  static TextStyle get greeting => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w400,
        color: AppColors.black,
      );

  static TextStyle get screenTitle => GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w400,
        color: AppColors.black,
      );

  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.black,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.gray700,
      );

  static TextStyle get button => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.white,
      );

  static TextStyle get itemTitle => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.black,
      );

  // Monospace font: JetBrains Mono
  static TextStyle get heroTime => GoogleFonts.jetBrainsMono(
        fontSize: 48,
        fontWeight: FontWeight.w400,
        color: AppColors.black,
        letterSpacing: -1,
      );

  static TextStyle get monoMedium => GoogleFonts.jetBrainsMono(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.black,
      );

  static TextStyle get monoSecondary => GoogleFonts.jetBrainsMono(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.gray700,
      );
}
