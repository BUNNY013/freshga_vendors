import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/store_setup_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class StoreSetupScreen extends StatelessWidget {
  const StoreSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => StoreSetupProvider(),
      child: const _StoreSetupContent(),
    );
  }
}

class _StoreSetupContent extends StatelessWidget {
  const _StoreSetupContent();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StoreSetupProvider>();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: provider.currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
                onPressed: provider.previousStep,
              )
            : null,
        title: _buildProgressIndicator(provider.currentStep),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _getStepContent(provider.currentStep, provider, context),
                ),
              ),
              const SizedBox(height: 24),
              _buildBottomButton(provider, context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(int currentStep) {
    return Row(
      children: List.generate(
        6,
        (index) => Expanded(
          child: Container(
            height: 4,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: index <= currentStep
                  ? AppColors.primary
                  : AppColors.grey200,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _getStepContent(int step, StoreSetupProvider provider, BuildContext context) {
    switch (step) {
      case 0:
        return _buildIntroStep();
      case 1:
        return _buildLogoBannerStep(provider);
      case 2:
        return _buildBrandStoryStep(provider);
      case 3:
        return _buildSocialSettingsStep(provider);
      case 4:
        return _buildDispatchSettingsStep(provider);
      case 5:
        return _buildPreviewStep(provider);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildIntroStep() {
    return Column(
      key: const ValueKey('intro'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.storefront, size: 80, color: AppColors.primary),
        const SizedBox(height: 32),
        const Text(
          "Your food journey starts here 🚀",
          style: AppTextStyles.h1,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        const Text(
          "Let's set up your store profile so customers can start discovering your homemade brand.",
          style: AppTextStyles.bodyText,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLogoBannerStep(StoreSetupProvider provider) {
    return Column(
      key: const ValueKey('logo_banner'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Store Identity", style: AppTextStyles.h2),
        const SizedBox(height: 8),
        const Text("Upload your brand logo and store banner.", style: AppTextStyles.bodyText),
        const SizedBox(height: 32),
        
        // Logo
        Center(
          child: GestureDetector(
            onTap: provider.pickLogo,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.grey100,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary.withOpacity(0.5)),
                image: provider.logoFile != null
                    ? DecorationImage(
                        image: FileImage(provider.logoFile!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: provider.logoFile == null
                  ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo, color: AppColors.primary),
                        SizedBox(height: 4),
                        Text("Logo", style: TextStyle(fontSize: 12, color: AppColors.primary)),
                      ],
                    )
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 32),
        
        // Banner
        GestureDetector(
          onTap: provider.pickBanner,
          child: Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.grey100,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.grey300),
              image: provider.bannerFile != null
                  ? DecorationImage(
                      image: FileImage(provider.bannerFile!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: provider.bannerFile == null
                ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image, color: AppColors.grey500, size: 40),
                      SizedBox(height: 8),
                      Text("Upload Banner", style: TextStyle(color: AppColors.grey600)),
                    ],
                  )
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildBrandStoryStep(StoreSetupProvider provider) {
    return SingleChildScrollView(
      key: const ValueKey('brand_story'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Your Brand", style: AppTextStyles.h2),
          const SizedBox(height: 8),
          const Text("Tell customers about your kitchen.", style: AppTextStyles.bodyText),
          const SizedBox(height: 24),
          
          const Text("Store Name", style: AppTextStyles.subtitle),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: '',
            onChanged: provider.setStoreName,
            decoration: InputDecoration(
              hintText: "e.g., Grandma's Pickles",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 24),
          
          const Text("Brand Story", style: AppTextStyles.subtitle),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: '',
            onChanged: provider.setBrandStory,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: "Share the inspiration behind your homemade food...",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialSettingsStep(StoreSetupProvider provider) {
    return Column(
      key: const ValueKey('social'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Social Links", style: AppTextStyles.h2),
        const SizedBox(height: 8),
        const Text("Connect your audience.", style: AppTextStyles.bodyText),
        const SizedBox(height: 32),
        
        const Text("Instagram Profile (Optional)", style: AppTextStyles.subtitle),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: '',
          onChanged: provider.setInstagramLink,
          decoration: InputDecoration(
            hintText: "https://instagram.com/yourbrand",
            prefixIcon: const Icon(Icons.link),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildDispatchSettingsStep(StoreSetupProvider provider) {
    return Column(
      key: const ValueKey('dispatch'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Dispatch Settings", style: AppTextStyles.h2),
        const SizedBox(height: 8),
        const Text("How quickly do you usually prepare and dispatch orders?", style: AppTextStyles.bodyText),
        const SizedBox(height: 32),
        
        DropdownButtonFormField<String>(
          value: '24 hours',
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: const [
            DropdownMenuItem(value: '24 hours', child: Text("Within 24 hours (Ready to ship)")),
            DropdownMenuItem(value: '48 hours', child: Text("Within 48 hours")),
            DropdownMenuItem(value: '3-4 days', child: Text("3-4 days (Made to order)")),
            DropdownMenuItem(value: '1 week', child: Text("1 week")),
          ],
          onChanged: (val) {
            if (val != null) provider.setDispatchTime(val);
          },
        ),
      ],
    );
  }

  Widget _buildPreviewStep(StoreSetupProvider provider) {
    return Column(
      key: const ValueKey('preview'),
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle, size: 80, color: Colors.green),
        const SizedBox(height: 24),
        const Text("Ready to Launch!", style: AppTextStyles.h2),
        const SizedBox(height: 16),
        const Text(
          "Your store profile is complete. Click below to publish your store and start adding products.",
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyText,
        ),
        if (provider.errorMessage != null) ...[
          const SizedBox(height: 16),
          Text(provider.errorMessage!, style: const TextStyle(color: Colors.red)),
        ]
      ],
    );
  }

  Widget _buildBottomButton(StoreSetupProvider provider, BuildContext context) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final isLastStep = provider.currentStep == 5;
    
    return ElevatedButton(
      onPressed: () async {
        if (isLastStep) {
          final success = await provider.publishStore();
          if (success && context.mounted) {
            context.go('/dashboard');
          }
        } else {
          provider.nextStep();
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        isLastStep ? "Publish Store" : "Continue",
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }
}
