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
              const SizedBox(height: 16),
              if (provider.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    provider.errorMessage!,
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
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
        return _buildLogoStep(provider);
      case 2:
        return _buildBannerStep(provider);
      case 3:
        return _buildBrandStoryStep(provider);
      case 4:
        return _buildSocialSettingsStep(provider);
      case 5:
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
          
          const Text("Store Handle (Unique Link)", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextFormField(
            controller: provider.handleController,
            onChanged: provider.setStoreHandle,
            decoration: InputDecoration(
              hintText: "grandmas_pickles",
              prefixIcon: const Padding(
                padding: EdgeInsets.all(14.0),
                child: Text('@', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
              ),
              suffixIcon: provider.isCheckingHandle
                  ? const Padding(padding: EdgeInsets.all(12.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                  : provider.storeHandle.isNotEmpty
                      ? provider.isHandleAvailable == true
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : const Icon(Icons.cancel, color: Colors.red)
                      : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12), 
                borderSide: provider.storeHandle.isNotEmpty && provider.isHandleAvailable == false 
                    ? const BorderSide(color: Colors.red) 
                    : BorderSide.none
              ),
            ),
          ),
          if (provider.storeHandle.isNotEmpty && provider.isHandleAvailable == false)
            Padding(
              padding: const EdgeInsets.only(top: 8.0, left: 4.0),
              child: Text(provider.handleError ?? "This handle is already taken. Try another.", style: const TextStyle(color: Colors.red, fontSize: 12)),
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
            prefixIcon: const Icon(Icons.camera_alt_outlined, color: Colors.pink),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 16),
        
        const Text("YouTube Channel (Optional)", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: provider.youtubeLink,
          onChanged: provider.setYoutubeLink,
          decoration: InputDecoration(
            hintText: "https://youtube.com/@yourbrand",
            prefixIcon: const Icon(Icons.play_circle_outline, color: Colors.red),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 16),
        
        const Text("Facebook Page (Optional)", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: provider.facebookLink,
          onChanged: provider.setFacebookLink,
          decoration: InputDecoration(
            hintText: "https://facebook.com/yourbrand",
            prefixIcon: const Icon(Icons.facebook, color: Colors.blue),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 16),
        
        const Text("WhatsApp Number (Optional)", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: provider.whatsappNumber,
          onChanged: provider.setWhatsappNumber,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            hintText: "Enter 10-digit number",
            prefixIcon: const Icon(Icons.chat_bubble_outline, color: Colors.green),
            prefixText: "+91 ",
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
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
          
          // Premium Customer App style profile card
          Container(
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10)),
              ],
              border: Border.all(color: Colors.grey.shade200, width: 1),
            ),
            child: Column(
              children: [
                // Store Header
                SizedBox(
                  height: 220,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Banner Image
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        bottom: 50,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.grey200,
                            image: provider.bannerFile != null
                                ? DecorationImage(image: FileImage(provider.bannerFile!), fit: BoxFit.cover)
                                : null,
                          ),
                        ),
                      ),
                      // Gradient overlay
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        bottom: 50,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.4),
                                Colors.transparent,
                                Colors.black.withOpacity(0.1),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // White overlap area
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 50,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                          ),
                        ),
                      ),
                      // Logo overlapping
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Center(
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 4)),
                              ],
                              image: provider.logoFile != null
                                  ? DecorationImage(image: FileImage(provider.logoFile!), fit: BoxFit.cover)
                                  : null,
                            ),
                            child: provider.logoFile == null
                                ? const Icon(Icons.store, color: Colors.grey, size: 36)
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Store Info Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              provider.storeName.isEmpty ? "Your Brand Name" : provider.storeName,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                                fontFamily: 'serif',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.verified, color: Colors.blue, size: 20),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        provider.storeHandle.isEmpty ? "@your_brand_handle" : "@${provider.storeHandle}",
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "0 Followers",
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          elevation: 0,
                        ),
                        child: const Text("Follow", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
            context.go('/trial-activation');
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
