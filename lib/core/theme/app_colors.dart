import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Core brand tokens (Coinbase-inspired palette)
  static const Color blue = Color(0xFF0052FF);
  static const Color black = Color(0xFF0A0B0D);
  static const Color gray700 = Color(0xFF7C828A);
  static const Color gray300 = Color(0xFFA8B8CC);
  static const Color gray100 = Color(0xFFEEF0F3);
  static const Color white = Color(0xFFFFFFFF);

  // Status colors (used strictly for dots and text inside gray100 pill)
  static const Color statusGreen = Color(0xFF05B169); // Tepat waktu
  static const Color statusRed = Color(0xFFCF202F);   // Terlambat
  static const Color statusGray = Color(0xFF7C828A);  // Belum absen
}
