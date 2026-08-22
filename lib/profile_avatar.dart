import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, required this.radius, this.imageUrl});

  final double radius;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final diameter = radius * 2;
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFE2E8F0),
      child: ClipOval(
        child: hasImage
            ? Image.network(
                imageUrl!,
                width: diameter,
                height: diameter,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _fallback(),
              )
            : _fallback(),
      ),
    );
  }

  Widget _fallback() {
    final diameter = radius * 2;
    return SizedBox(
      width: diameter,
      height: diameter,
      child: const Icon(Icons.person, color: Color(0xFF64748B)),
    );
  }
}
