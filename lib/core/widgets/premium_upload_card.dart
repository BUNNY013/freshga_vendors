import 'package:flutter/material.dart';
import 'dart:io';
import '../theme/app_colors.dart';

class PremiumUploadCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final File? selectedFile;
  final VoidCallback onTap;
  final double height;
  final bool isCircle;

  const PremiumUploadCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.selectedFile,
    required this.onTap,
    this.height = 200,
    this.isCircle = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.circular(isCircle ? height / 2 : 24),
          border: Border.all(
            color: selectedFile != null ? AppColors.primary : AppColors.grey300,
            width: 2,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: selectedFile != null
            ? _buildImagePreview()
            : _buildUploadPrompt(),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.file(
          selectedFile!,
          fit: BoxFit.cover,
        ),
        Container(
          color: Colors.black.withOpacity(0.3),
        ),
        const Center(
          child: Icon(Icons.edit, color: Colors.white, size: 40),
        ),
      ],
    );
  }

  Widget _buildUploadPrompt() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 32),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.grey600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
