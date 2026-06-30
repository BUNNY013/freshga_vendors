import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/app_colors.dart';

class SocialLinksScreen extends StatelessWidget {
  const SocialLinksScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
            _buildLabel('Instagram', required: false),
            const SizedBox(height: 8),
            _buildTextField(
              initialValue: 'https://instagram.com/ammas.secrets',
              hintText: 'Instagram URL',
              icon: Icons.camera_alt,
              iconColor: const Color(0xFFE1306C),
            ),
            const SizedBox(height: 24),
            _buildLabel('Facebook', required: false),
            const SizedBox(height: 8),
            _buildTextField(
              initialValue: 'https://facebook.com/ammas.secrets',
              hintText: 'Facebook URL',
              icon: Icons.facebook,
              iconColor: const Color(0xFF1877F2),
            ),
            const SizedBox(height: 24),
            _buildLabel('YouTube', required: false),
            const SizedBox(height: 8),
            _buildTextField(
              initialValue: 'https://youtube.com/@ammassecrets',
              hintText: 'YouTube Channel URL',
              icon: Icons.play_circle_fill,
              iconColor: const Color(0xFFFF0000),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text, {bool required = false}) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        if (required)
          const Text(' *', style: TextStyle(color: Color(0xFFDC2626))),
        if (!required)
          const Text(' (Optional)', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
      ],
    );
  }

  Widget _buildTextField({
    required String initialValue,
    required String hintText,
    required IconData icon,
    required Color iconColor,
  }) {
    return TextFormField(
      initialValue: initialValue,
      style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
        border: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFE2E8F0))),
        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.blue, width: 1.5)),
        prefixIcon: Icon(icon, color: iconColor, size: 24),
      ),
    );
  }
}
