import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_constants.dart';

class AppTheme {
  static const Color primaryColor = Color(AppConstants.primaryColorValue);
  static const Color scaffoldBackgroundColor = Color(AppConstants.scaffoldBackgroundColorValue);
  
  // 확장 색상 팔레트
  static const Color secondaryColor = Color(0xFF64748B);
  static const Color successColor = Color(0xFF10B981);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color onSurfaceColor = Color(0xFF1F2937);
  
  // 텍스트 색상
  static const Color primaryTextColor = Color(0xFF111827);
  static const Color secondaryTextColor = Color(0xFF6B7280);
  static const Color lightTextColor = Color(0xFF9CA3AF);
  
  // 그림자
  static const Color shadowColor = Color(0x0F000000);
  
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.roboto().fontFamily,
      
      // 색상 스키마
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        surface: surfaceColor,
        onSurface: onSurfaceColor,
        error: errorColor,
      ),
      
      // 배경색
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      
      // AppBar 테마
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: shadowColor,
        titleTextStyle: GoogleFonts.roboto(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      
      // 버튼 테마
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: shadowColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // 카드 테마
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 4,
        shadowColor: shadowColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(8),
      ),
      
      // 입력 필드 테마
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: secondaryColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: errorColor),
        ),
        filled: true,
        fillColor: surfaceColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        labelStyle: GoogleFonts.roboto(color: secondaryTextColor),
        hintStyle: GoogleFonts.roboto(color: lightTextColor),
      ),
      
      // 스낵바 테마
      snackBarTheme: SnackBarThemeData(
        backgroundColor: onSurfaceColor,
        contentTextStyle: GoogleFonts.roboto(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      
      // 다이얼로그 테마
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        elevation: 8,
        shadowColor: shadowColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titleTextStyle: GoogleFonts.roboto(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: primaryTextColor,
        ),
        contentTextStyle: GoogleFonts.roboto(
          fontSize: 16,
          color: secondaryTextColor,
        ),
      ),
      
      // 텍스트 테마
      textTheme: TextTheme(
        displayLarge: GoogleFonts.roboto(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: primaryTextColor,
        ),
        displayMedium: GoogleFonts.roboto(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: primaryTextColor,
        ),
        displaySmall: GoogleFonts.roboto(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: primaryTextColor,
        ),
        headlineLarge: GoogleFonts.roboto(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: primaryTextColor,
        ),
        headlineMedium: GoogleFonts.roboto(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: primaryTextColor,
        ),
        headlineSmall: GoogleFonts.roboto(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: primaryTextColor,
        ),
        titleLarge: GoogleFonts.roboto(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: primaryTextColor,
        ),
        titleMedium: GoogleFonts.roboto(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: primaryTextColor,
        ),
        titleSmall: GoogleFonts.roboto(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: primaryTextColor,
        ),
        bodyLarge: GoogleFonts.roboto(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: primaryTextColor,
        ),
        bodyMedium: GoogleFonts.roboto(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: primaryTextColor,
        ),
        bodySmall: GoogleFonts.roboto(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: secondaryTextColor,
        ),
        labelLarge: GoogleFonts.roboto(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: primaryTextColor,
        ),
        labelMedium: GoogleFonts.roboto(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: secondaryTextColor,
        ),
        labelSmall: GoogleFonts.roboto(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: lightTextColor,
        ),
      ),
    );
  }
  
  // SIGMA 브랜딩 색상
  static const Color sigmaBlue = Color(0xFF383AF4);
  static const Color sigmaLightBlue = Color(0xFF5381F6);
  
  // UI 공통 색상
  static const Color borderGray = Color(0xFFDADCE0);
  static const Color textGray = Color(0xFF3C4043);
  static const Color logoGray = Color(0xFFB2B0B0);
  static const Color backgroundGray = Color(0xFFD9D8D8);
  static const Color lightBackgroundGray = Color(0xFFE8E8E8);
  static const Color lightGray = Color(0xFFF2F2F7);
  static const Color iconGray = Color(0xFFA2A2A2);
  static const Color mediumGray = Color(0xFF7A7A7A);
  static const Color separatorGray = Color(0xFFE6E5E5);
  static const Color overlayBackground = Color(0xFF0C0C0C);
  static const Color dialogGray = Color(0xFF666666);
  static const Color buttonBlue = Color(0xFF4A90E2);
  static const Color googleBlue = Color(0xFF4285F4);
  static const Color cameraGreen = Color(0xFF34BF49);
  static const Color micRed = Colors.red;
  static const Color lightMicGray = Color(0xFFBDBDBD);
  static const Color errorRed = Color(0xFFFF5252);
  static const Color lightBlueBackground = Color(0xFFF8F9FF);
  static const Color settingsGray = Color(0xFFCECCCC);
  static const Color arrowGray = Color(0xFF827F7F);
  static const Color settingsBackground = Color(0xFFF0F0F4);
  static const Color settingsBorder = Color(0xFF9397B8);
  static const Color settingsText = Color(0xFF4B4B4B);
  static const Color settingsOrange = Color(0xFFFF5722);
  static const Color settingsButtonGray = Color(0xFF9CA3AF);
  static const Color settingsButtonBlue = Color(0xFF185ABD);
  
  // 그라데이션
  static const LinearGradient sigmaGradient = LinearGradient(
    colors: [Color(0xFF578EF6), Color(0xFF496BF5), Color(0xFF383AF4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // 커스텀 색상 확장
  static const Map<String, Color> customColors = {
    'cameraGreen': Color(0xFF10B981),
    'warningAmber': Color(0xFFF59E0B),
    'dangerRed': Color(0xFFEF4444),
    'infoBlue': Color(0xFF3B82F6),
    'neutralGray': Color(0xFF6B7280),
  };
  
  // SIGMA 브랜딩 텍스트 스타일
  static TextStyle get sigmaAcronymStyle => const TextStyle(
    fontFamily: 'AppleSDGothicNeo',
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );
  
  static TextStyle get sigmaTitleStyle => const TextStyle(
    fontFamily: 'AppleSDGothicNeo',
    fontSize: 64,
    fontWeight: FontWeight.w900,
    color: Colors.black,
    height: 1.0,
  );
  
  static TextStyle get sigmaBackButtonStyle => const TextStyle(
    fontFamily: 'AppleSDGothicNeo',
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: Color(0xFF5381F6),
  );
  
  // 그라데이션
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, Color(0xFF4F46E5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient successGradient = LinearGradient(
    colors: [successColor, Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // 애니메이션 시간
  static const Duration fastAnimation = Duration(milliseconds: 200);
  static const Duration normalAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 500);
}