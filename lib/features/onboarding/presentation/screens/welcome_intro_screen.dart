import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:go_router/go_router.dart';

class WelcomeIntroScreen extends StatelessWidget {
  const WelcomeIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.celebration_rounded, color: AppColors.primary, size: 56),
              const SizedBox(height: 32),
              Text(
                'Welcome to FreshGa\nHomeMades',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: AppColors.textPrimary,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Start your own homemade food store today.',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.normal,
                ),
              ),
              const SizedBox(height: 48),
              
              _buildFeatureItem(Icons.public_rounded, 'Sell across India'),
              _buildFeatureItem(Icons.groups_rounded, 'Build followers'),
              _buildFeatureItem(Icons.local_shipping_rounded, 'Receive direct orders'),
              _buildFeatureItem(Icons.star_rounded, 'Create your food brand'),
              _buildFeatureItem(Icons.trending_up_rounded, 'Grow like Instagram creators'),
              
              const Spacer(),
              
              ElevatedButton(
                onPressed: () {
                  context.push('/onboarding/step1');
                },
                child: const Text('Start Verification'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
