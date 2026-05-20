import 'package:flutter/material.dart';


/// Social links row displayed below store stats
class StoreSocialLinks extends StatelessWidget {
  final String instagramLink;
  final String youtubeLink;
  final String facebookLink;

  const StoreSocialLinks({
    super.key,
    required this.instagramLink,
    required this.youtubeLink,
    required this.facebookLink,
  });

  bool get hasAnyLink =>
      instagramLink.isNotEmpty || youtubeLink.isNotEmpty || facebookLink.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (!hasAnyLink) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (instagramLink.isNotEmpty)
            _buildSocialLink(
              icon: Icons.camera_alt_outlined,
              label: 'Instagram',
              color: const Color(0xFFE1306C),
              url: instagramLink,
            ),
          if (instagramLink.isNotEmpty && youtubeLink.isNotEmpty) const SizedBox(width: 10),
          if (youtubeLink.isNotEmpty)
            _buildSocialLink(
              icon: Icons.play_circle_outline,
              label: 'YouTube',
              color: const Color(0xFFFF0000),
              url: youtubeLink,
            ),
          if (youtubeLink.isNotEmpty && facebookLink.isNotEmpty) const SizedBox(width: 10),
          if (facebookLink.isNotEmpty)
            _buildSocialLink(
              icon: Icons.facebook,
              label: 'Facebook',
              color: const Color(0xFF1877F2),
              url: facebookLink,
            ),
        ],
      ),
    );
  }

  Widget _buildSocialLink({
    required IconData icon,
    required String label,
    required Color color,
    required String url,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
