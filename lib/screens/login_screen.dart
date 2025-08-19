import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_loading_screen.dart';

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
                    Image.asset(
                      'assets/images/sigma_logo.png',
                      width: 90,
                      height: 90,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 23),
                    
                    // Smart Interactive Gesture text
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontFamily: 'AppleSDGothicNeo',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                        children: const [
                          TextSpan(
                            text: 'S',
                            style: TextStyle(color: Color(0xFF383AF4)),
                          ),
                          TextSpan(
                            text: 'mart ',
                            style: TextStyle(color: Colors.black),
                          ),
                          TextSpan(
                            text: 'I',
                            style: TextStyle(color: Color(0xFF383AF4)),
                          ),
                          TextSpan(
                            text: 'nteractive ',
                            style: TextStyle(color: Colors.black),
                          ),
                          TextSpan(
                            text: 'G',
                            style: TextStyle(color: Color(0xFF383AF4)),
                          ),
                          TextSpan(
                            text: 'esture',
                            style: TextStyle(color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // SIGMA title
                    Text(
                      'SIGMA',
                      style: const TextStyle(
                        fontFamily: 'AppleSDGothicNeo',
                        fontSize: 64,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                        height: 1.0,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Management Assistant text
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontFamily: 'AppleSDGothicNeo',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                        children: const [
                          TextSpan(
                            text: 'M',
                            style: TextStyle(color: Color(0xFF383AF4)),
                          ),
                          TextSpan(
                            text: 'anagement ',
                            style: TextStyle(color: Colors.black),
                          ),
                          TextSpan(
                            text: 'A',
                            style: TextStyle(color: Color(0xFF383AF4)),
                          ),
                          TextSpan(
                            text: 'ssistant',
                            style: TextStyle(color: Colors.black),
                          ),
                        ],
                      ),
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
                          foregroundColor: const Color(0xFF3C4043),
                          elevation: 0,
                          side: const BorderSide(
                            color: Color(0xFFDADCE0),
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
                              child: Image.asset(
                                'assets/images/google_logo.png',
                                width: 26,
                                height: 26,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 26,
                                    height: 26,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF4285F4),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.g_mobiledata,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Sign in with Google',
                              style: GoogleFonts.roboto(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF3C4043),
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
                  Image.asset(
                    'assets/images/euler_logo.png',
                    width: 40,
                    height: 14,
                    errorBuilder: (context, error, stackTrace) {
                      return Text(
                        'Euler',
                        style: const TextStyle(
                          fontFamily: 'AppleSDGothicNeo',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFB2B0B0),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  Image.asset(
                    'assets/images/x_logo.png',
                    width: 8,
                    height: 8,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 5.238,
                        height: 5.238,
                        decoration: const BoxDecoration(
                          color: Color(0xFFB2B0B0),
                          shape: BoxShape.circle,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  Image.asset(
                    'assets/images/aws_logo.png',
                    width: 24,
                    height: 24,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.cloud,
                        color: Color(0xFFB2B0B0),
                        size: 24,
                      );
                    },
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
