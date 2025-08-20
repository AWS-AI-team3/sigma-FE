import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_loading_screen.dart';
import '../themes/app_theme.dart';
import '../widgets/sigma_branding_text.dart';
import '../widgets/safe_image_asset.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    SafeImageAsset(
                      assetPath: 'assets/images/sigma_logo.png',
                      width: 90,
                      height: 90,
                      fallbackText: 'SIGMA',
                    ),
                    const SizedBox(height: 23),
                    
                    // Smart Interactive Gesture text
                    SigmaBrandingText(
                      text: 'Smart Interactive Gesture',
                      highlightLetters: 'SIG',
                      baseStyle: AppTheme.sigmaAcronymStyle,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // SIGMA title
                    Text(
                      'SIGMA',
                      style: AppTheme.sigmaTitleStyle,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Management Assistant text
                    SigmaBrandingText(
                      text: 'Management Assistant',
                      highlightLetters: 'MA',
                      baseStyle: AppTheme.sigmaAcronymStyle,
                    ),
                    
                    const SizedBox(height: 60),
                    
                    // Google Sign In Button
                    Container(
                      width: 413,
                      height: 59,
                      child: ElevatedButton(
                        onPressed: () {
                          _handleGoogleLogin(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.textGray,
                          elevation: 0,
                          side: const BorderSide(
                            color: AppTheme.borderGray,
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(40),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Google Logo
                            SizedBox(
                              width: 26,
                              height: 26,
                              child: SafeImageAsset(
                                assetPath: 'assets/images/google_logo.png',
                                width: 26,
                                height: 26,
                                fallback: Container(
                                  width: 26,
                                  height: 26,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.googleBlue,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.g_mobiledata,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Sign in with Google',
                              style: GoogleFonts.roboto(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textGray,
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
            
            // Bottom section with Euler, X, and AWS logos
            Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SafeLogoImage(
                    assetPath: 'assets/images/euler_logo.png',
                    size: 40,
                    fallbackText: 'Euler',
                  ),
                  const SizedBox(width: 8),
                  SafeImageAsset(
                    assetPath: 'assets/images/x_logo.png',
                    width: 8,
                    height: 8,
                    fallback: Container(
                      width: 5.238,
                      height: 5.238,
                      decoration: const BoxDecoration(
                        color: AppTheme.logoGray,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SafeIconImage(
                    assetPath: 'assets/images/aws_logo.png',
                    size: 24,
                    fallbackIcon: Icons.cloud,
                    color: AppTheme.logoGray,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleGoogleLogin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginLoadingScreen()),
    );
  }
}
