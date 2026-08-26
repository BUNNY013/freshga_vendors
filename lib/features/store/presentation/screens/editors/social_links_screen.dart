import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/app_colors.dart';

import 'package:provider/provider.dart';
import '../../../providers/store_provider.dart';
import '../../../../../core/presentation/widgets/premium_text_field.dart';

class SocialLinksScreen extends StatelessWidget {
  const SocialLinksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final storeProvider = Provider.of<StoreProvider>(context);
    final store = storeProvider.store;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Social Links',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 17),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Done', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PremiumTextField(
              label: 'Instagram (Optional)',
              initialValue: store?.instagramLink ?? '',
              hintText: 'Instagram URL',
              prefixIcon: const Icon(Icons.camera_alt, color: Color(0xFFE1306C)),
            ),
            const SizedBox(height: 24),
            PremiumTextField(
              label: 'Facebook (Optional)',
              initialValue: store?.facebookLink ?? '',
              hintText: 'Facebook URL',
              prefixIcon: const Icon(Icons.facebook, color: Color(0xFF1877F2)),
            ),
            const SizedBox(height: 24),
            PremiumTextField(
              label: 'YouTube (Optional)',
              initialValue: store?.youtubeLink ?? '',
              hintText: 'YouTube Channel URL',
              prefixIcon: const Icon(Icons.play_circle_fill, color: Color(0xFFFF0000)),
            ),
          ],
        ),
      ),
    );
  }

}
