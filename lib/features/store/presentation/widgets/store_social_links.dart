import 'package:flutter/material.dart';


/// Social links row displayed below store stats
class StoreSocialLinks extends StatelessWidget {
  final String instagramLink;
  final String youtubeLink;
  final String facebookLink;
  final String whatsappNumber;

  const StoreSocialLinks({
    super.key,
    required this.instagramLink,
    required this.youtubeLink,
    required this.facebookLink,
    this.whatsappNumber = '',
  });

  bool get hasAnyLink =>
      instagramLink.isNotEmpty || youtubeLink.isNotEmpty || facebookLink.isNotEmpty || whatsappNumber.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (!hasAnyLink) return const SizedBox.shrink();

    final List<Widget> links = [];

    if (whatsappNumber.isNotEmpty) {
      links.add(_buildSocialLink(
        assetPath: 'assets/images/whatsapp_icon.png',
        label: 'WhatsApp',
        color: const Color(0xFF25D366),
        url: whatsappNumber,
      ));
    }
    if (instagramLink.isNotEmpty) {
      links.add(_buildSocialLink(
        assetPath: 'assets/images/instagram_icon.png',
        label: 'Instagram',
        color: const Color(0xFFE1306C),
        url: instagramLink,
        scale: 1.35,
      ));
    }
    if (youtubeLink.isNotEmpty) {
      links.add(_buildSocialLink(
        assetPath: 'assets/images/youtube_icon.png',
        label: 'YouTube',
        color: const Color(0xFFFF0000),
        url: youtubeLink,
      ));
    }
    if (facebookLink.isNotEmpty) {
      links.add(_buildSocialLink(
        assetPath: 'assets/images/facebook_icon.png',
        label: 'Facebook',
        color: const Color(0xFF1877F2),
        url: facebookLink,
      ));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 10,
        runSpacing: 10,
        children: links,
      ),
    );
  }

  Widget _buildSocialLink({
    required String assetPath,
    required String label,
    required Color color,
    required String url,
    double scale = 1.0,
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
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Transform.scale(
              scale: scale,
              child: Image.asset(assetPath, width: 20, height: 20, fit: BoxFit.cover),
            ),
          ),
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
