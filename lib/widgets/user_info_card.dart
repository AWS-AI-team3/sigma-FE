import 'package:flutter/material.dart';
import 'safe_network_image.dart';

class UserInfoCard extends StatelessWidget {
  final String userName;
  final String? profileUrl;
  final String subscriptStatus;

  const UserInfoCard({
    super.key,
    required this.userName,
    this.profileUrl,
    required this.subscriptStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          SafeProfileImage(
            imageUrl: profileUrl,
            size: 60,
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userName,
                style: const TextStyle(
                  fontFamily: 'AppleSDGothicNeo',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subscriptStatus,
                style: const TextStyle(
                  fontFamily: 'AppleSDGothicNeo',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}