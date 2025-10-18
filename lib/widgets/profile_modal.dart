import 'package:flutter/material.dart';

class ProfileModal extends StatelessWidget {
  final Map<String, dynamic>? userInfo;
  final VoidCallback onLogout;
  final VoidCallback onClose;

  const ProfileModal({
    super.key,
    required this.userInfo,
    required this.onLogout,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    // iPad Air 11": 834x1194
    // Figma base: 836x584
    final screenWidth = MediaQuery.of(context).size.width;
    final scale = screenWidth / 836;

    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black.withValues(alpha: 0.3),
        child: Center(
          child: GestureDetector(
            onTap: () {}, // Prevent closing when tapping modal content
            child: Container(
              width: 285 * scale,
              height: 419 * scale,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(20 * scale),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 35 * scale,
                    offset: Offset(3 * scale, 4 * scale),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Top bar with close button (macOS style)
                  Padding(
                    padding: EdgeInsets.only(left: 10 * scale, top: 10 * scale),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Close button (red)
                          GestureDetector(
                            onTap: onClose,
                            child: Container(
                              width: 12 * scale,
                              height: 12 * scale,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFE5F57),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          SizedBox(width: 6 * scale),
                          // Hide button (gray)
                          Container(
                            width: 12 * scale,
                            height: 12 * scale,
                            decoration: const BoxDecoration(
                              color: Color(0xFFDADADB),
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 6 * scale),
                          // Fullscreen button (gray)
                          Container(
                            width: 12 * scale,
                            height: 12 * scale,
                            decoration: const BoxDecoration(
                              color: Color(0xFFDADADB),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 45 * scale),

                  // Profile Image
                  Container(
                    width: 148 * scale,
                    height: 148 * scale,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 4 * scale,
                          offset: const Offset(0, 0),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: userInfo != null && userInfo!['profileUrl'] != null
                          ? Image.network(
                              userInfo!['profileUrl'],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[300],
                                  child: Icon(Icons.person, size: 80 * scale),
                                );
                              },
                            )
                          : Container(
                              color: Colors.grey[300],
                              child: Icon(Icons.person, size: 80 * scale),
                            ),
                    ),
                  ),

                  SizedBox(height: 43 * scale),

                  // Name
                  Text(
                    userInfo?['userName'] ?? '사용자',
                    style: TextStyle(
                      fontSize: 16 * scale,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),

                  SizedBox(height: 2 * 1),

                  // Subscription status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '요금제: ',
                        style: TextStyle(
                          fontSize: 11 * scale,
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 9 * scale,
                          vertical: 1 * scale,
                        ),
                        decoration: BoxDecoration(
                          color: userInfo?['subscriptStatus'] == 'PAID'
                              ? const Color(0xFF4E9CFF)
                              : const Color(0xFF9A9A9A),
                          borderRadius: BorderRadius.circular(12 * scale),
                        ),
                        child: Text(
                          userInfo?['subscriptStatus'] == 'PAID'
                              ? 'pro'
                              : 'free',
                          style: TextStyle(
                            fontSize: 11 * scale,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 4 * 1),

                  // Email
                  Text(
                    '이메일: ${userInfo?['email'] ?? '알 수 없음'}',
                    style: TextStyle(
                      fontSize: 11 * scale,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                  ),

                  SizedBox(height: 40 * scale),

                  // Logout button
                  GestureDetector(
                    onTap: onLogout,
                    child: Text(
                      '로그아웃',
                      style: TextStyle(
                        fontSize: 10 * scale,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF9A9A9A),
                        decoration: TextDecoration.underline,
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
