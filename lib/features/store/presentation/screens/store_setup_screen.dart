import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import '../../providers/store_setup_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class StoreSetupScreen extends StatefulWidget {
  const StoreSetupScreen({super.key});

  @override
  State<StoreSetupScreen> createState() => _StoreSetupScreenState();
}

class _StoreSetupScreenState extends State<StoreSetupScreen> {
  late final StoreSetupProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = StoreSetupProvider();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
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
        7,
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
        return _buildLogoStep(provider);
      case 2:
        return _buildBannerStep(provider);
      case 3:
        return _buildBrandStoryStep(provider);
      case 4:
        return _buildSocialSettingsStep(provider);
      case 5:
        return _buildDispatchSettingsStep(provider);
      case 6:
        return _buildPreviewStep(provider);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildIntroStep() {
    return SingleChildScrollView(
      key: const ValueKey('intro'),
      child: Column(
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
      ),
    );
  }

  Widget _buildLogoStep(StoreSetupProvider provider) {
    return SingleChildScrollView(
      key: const ValueKey('logo'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text("Store Logo", style: AppTextStyles.h2),
          const SizedBox(height: 8),
          const Text("Upload a profile picture for your brand.", style: AppTextStyles.bodyText),
          const SizedBox(height: 48),
        GestureDetector(
          onTap: provider.pickLogo,
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: AppColors.grey100,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary.withOpacity(0.5), width: 2),
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
                      Icon(Icons.add_a_photo, color: AppColors.primary, size: 40),
                      SizedBox(height: 8),
                      Text("Upload Logo", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    ],
                  )
                : null,
          ),
        ),
        ],
      ),
    );
  }

  Widget _buildBannerStep(StoreSetupProvider provider) {
    return SingleChildScrollView(
      key: const ValueKey('banner'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text("Store Banner", style: AppTextStyles.h2),
          const SizedBox(height: 8),
          const Text("Upload a beautiful banner for your profile top.", style: AppTextStyles.bodyText),
          const SizedBox(height: 48),
        GestureDetector(
          onTap: provider.pickBanner,
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.grey100,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withOpacity(0.5), width: 2),
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
                      Icon(Icons.image_outlined, color: AppColors.primary, size: 48),
                      SizedBox(height: 12),
                      Text("Upload Banner", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text("Recommended: 1024x500", style: TextStyle(color: AppColors.grey600, fontSize: 12)),
                    ],
                  )
                : null,
          ),
        ),
        ],
      ),
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
          const SizedBox(height: 32),
          
          const Text("Store Name", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: provider.storeName,
            onChanged: provider.setStoreName,
            decoration: InputDecoration(
              hintText: "e.g., Grandma's Pickles",
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 24),
          
          const Text("Brand Story", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: provider.brandStory,
            onChanged: provider.setBrandStory,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: "Started by a mother in Guntur using traditional family recipes...",
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialSettingsStep(StoreSetupProvider provider) {
    return SingleChildScrollView(
      key: const ValueKey('social'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Social Links", style: AppTextStyles.h2),
          const SizedBox(height: 8),
          const Text("Connect your audience.", style: AppTextStyles.bodyText),
          const SizedBox(height: 32),
        
        const Text("Instagram Profile (Optional)", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: provider.instagramLink,
          onChanged: provider.setInstagramLink,
          decoration: InputDecoration(
            hintText: "https://instagram.com/yourbrand",
            prefixIcon: const Icon(Icons.link, color: AppColors.primary),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      ],
      ),
    );
  }

  Widget _buildDispatchSettingsStep(StoreSetupProvider provider) {
    return SingleChildScrollView(
      key: const ValueKey('dispatch'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Dispatch Settings", style: AppTextStyles.h2),
          const SizedBox(height: 8),
          const Text("How quickly do you usually prepare and dispatch orders?", style: AppTextStyles.bodyText),
          const SizedBox(height: 32),
        
        DropdownButtonFormField<String>(
          value: provider.dispatchTime,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
      ),
    );
  }

  Widget _buildPreviewStep(StoreSetupProvider provider) {
    // We can't access private fields easily if we don't have getters for story etc,
    // but we can fake it or use a default if it's a stateless preview.
    // However, we just need a beautiful preview representation.
    return SingleChildScrollView(
      key: const ValueKey('preview'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text("Store Preview", style: AppTextStyles.h2),
          const SizedBox(height: 8),
          const Text("This is how customers will see your brand.", style: AppTextStyles.bodyText),
          const SizedBox(height: 24),
          
          // Premium Instagram/Youtube-style profile card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10)),
              ],
            ),
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomCenter,
                  children: [
                    Container(
                      height: 140,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.grey200,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                        image: provider.bannerFile != null
                            ? DecorationImage(image: FileImage(provider.bannerFile!), fit: BoxFit.cover)
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: -40,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: Colors.white, width: 4),
                          image: provider.logoFile != null
                              ? DecorationImage(image: FileImage(provider.logoFile!), fit: BoxFit.cover)
                              : null,
                        ),
                        child: provider.logoFile == null
                            ? const Icon(Icons.fastfood, size: 40, color: AppColors.grey400)
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 48),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(provider.storeName.isEmpty ? "Your Brand Name" : provider.storeName, style: AppTextStyles.h2),
                    const SizedBox(width: 4),
                    const Icon(Icons.verified, color: Colors.blue, size: 18),
                  ],
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    provider.brandStory.isEmpty
                        ? "Your brand story will appear here. It shows authenticity and builds trust with your customers."
                        : provider.brandStory,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.grey600, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 16),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.favorite, size: 14, color: AppColors.grey600),
                    SizedBox(width: 4),
                    Text("0 Followers", style: TextStyle(color: AppColors.grey600, fontSize: 13)),
                    SizedBox(width: 16),
                    Icon(Icons.thumb_up_alt_outlined, size: 14, color: AppColors.grey600),
                    SizedBox(width: 4),
                    Text("0 Likes", style: TextStyle(color: AppColors.grey600, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          
          if (provider.errorMessage != null) ...[
            const SizedBox(height: 16),
            Text(provider.errorMessage!, style: const TextStyle(color: Colors.red)),
          ]
        ],
      ),
    );
  }

  Widget _buildBottomButton(StoreSetupProvider provider, BuildContext context) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final isLastStep = provider.currentStep == 6;
    
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
        elevation: 0,
      ),
      child: Text(
        isLastStep ? "Go Live" : "Continue",
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }
}
