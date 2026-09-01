import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import '../../providers/store_setup_provider.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/presentation/widgets/premium_text_field.dart';
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
        actions: [
          if (provider.currentStep == 0)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
              onSelected: (value) async {
                if (value == 'logout') {
                  await context.read<AuthProvider>().signOut();
                  if (context.mounted) {
                    context.go('/login');
                  }
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
                      SizedBox(width: 8),
                      Text('Logout', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          const SizedBox(width: 8),
        ],
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
          const SizedBox(height: 10),
          Image.asset(
            'assets/images/vendor_intro.png',
            width: double.infinity,
            height: 320,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 24),
          const Text(
            "Your food journey\nstarts here",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1.2,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              "Let's set up your store profile so customers can start discovering your homemade brand.",
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 40),
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
          const SizedBox(height: 16),
          const Text(
            "Store Logo",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              "Upload a profile picture for your brand. This is the first thing customers will see.",
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 56),
          GestureDetector(
            onTap: provider.pickLogo,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: provider.logoFile == null ? AppColors.primary.withOpacity(0.05) : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: provider.logoFile == null ? AppColors.primary.withOpacity(0.2) : AppColors.primary,
                  width: provider.logoFile == null ? 2 : 4,
                ),
                boxShadow: [
                  if (provider.logoFile == null)
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.1),
                      blurRadius: 30,
                      spreadRadius: 5,
                    )
                  else
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.25),
                      blurRadius: 40,
                      spreadRadius: 10,
                      offset: const Offset(0, 10),
                    ),
                ],
                image: provider.logoFile != null
                    ? DecorationImage(
                        image: FileImage(provider.logoFile!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: provider.logoFile == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.add_photo_alternate_rounded, color: AppColors.primary, size: 36),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Tap to Upload",
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
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
          const SizedBox(height: 16),
          const Text(
            "Store Banner",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              "Upload a beautiful banner. Here is how it will look with your logo!",
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 40),
          
          GestureDetector(
            onTap: provider.pickBanner,
            child: SizedBox(
              height: 300,
              width: double.infinity,
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  // Banner Area
                  Container(
                    height: 240,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: provider.bannerFile == null ? AppColors.primary.withOpacity(0.05) : Colors.white,
                      border: Border.symmetric(
                        horizontal: BorderSide(
                          color: provider.bannerFile == null ? AppColors.primary.withOpacity(0.2) : AppColors.primary,
                          width: provider.bannerFile == null ? 2 : 3,
                        ),
                      ),
                      boxShadow: [
                        if (provider.bannerFile == null)
                          BoxShadow(color: AppColors.primary.withOpacity(0.1), blurRadius: 20)
                        else
                          BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 30, offset: const Offset(0, 10)),
                      ],
                      image: provider.bannerFile != null
                          ? DecorationImage(
                              image: FileImage(provider.bannerFile!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: provider.bannerFile == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                                ),
                                child: const Icon(Icons.add_photo_alternate_rounded, color: AppColors.primary, size: 36),
                              ),
                              const SizedBox(height: 12),
                              const Text("Tap to Upload Banner", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 16)),
                            ],
                          )
                        : null,
                  ),
                  
                  // Overlapping Logo (from previous step)
                  Positioned(
                    bottom: 0,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 5)),
                        ],
                        image: provider.logoFile != null
                            ? DecorationImage(image: FileImage(provider.logoFile!), fit: BoxFit.cover)
                            : null,
                      ),
                      child: provider.logoFile == null 
                          ? const Icon(Icons.storefront_rounded, color: AppColors.grey400, size: 50)
                          : null,
                    ),
                  ),
                ],
              ),
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
          const SizedBox(height: 16),
          const Center(
            child: Text(
              "Your Brand",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: Center(
              child: Text(
                "Tell customers about your kitchen and what makes your food special.",
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 40),
          
          PremiumTextField(
            label: "Store Name",
            isRequired: true,
            initialValue: provider.storeName,
            onChanged: provider.setStoreName,
            hintText: "e.g., Grandma's Pickles",
          ),
          const SizedBox(height: 24),
          
          PremiumTextField(
            label: "Store ID",
            isRequired: true,
            controller: provider.handleController,
            onChanged: provider.setStoreHandle,
            hintText: "grandmas_pickles",
            prefixIcon: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
              child: Text('@', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
            ),
            suffixIcon: provider.isCheckingHandle
                ? const Padding(padding: EdgeInsets.all(14.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)))
                : provider.storeHandle.isNotEmpty
                    ? provider.isHandleAvailable == true
                        ? const Icon(Icons.check_circle_rounded, color: Colors.green, size: 24)
                        : const Icon(Icons.cancel_rounded, color: AppColors.error, size: 24)
                    : null,
          ),
          if (provider.storeHandle.isNotEmpty && provider.isHandleAvailable == false)
            Padding(
              padding: const EdgeInsets.only(top: 8.0, left: 4.0),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 16),
                  const SizedBox(width: 4),
                  Text(provider.handleError ?? "This handle is already taken. Try another.", style: const TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          const SizedBox(height: 24),
          
          PremiumTextField(
            label: "Brand Story",
            isRequired: true,
            initialValue: provider.brandStory,
            onChanged: provider.setBrandStory,
            minLines: 5,
            maxLines: 5,
            hintText: "Started by a mother in Guntur using traditional family recipes...",
          ),
          const SizedBox(height: 24),
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
        
        PremiumTextField(
          label: "Instagram Profile (Optional)",
          initialValue: provider.instagramLink,
          onChanged: provider.setInstagramLink,
          hintText: "https://instagram.com/yourbrand",
          prefixIcon: const Icon(Icons.camera_alt_outlined, color: Colors.pink),
        ),
        const SizedBox(height: 16),
        
        PremiumTextField(
          label: "YouTube Channel (Optional)",
          initialValue: provider.youtubeLink,
          onChanged: provider.setYoutubeLink,
          hintText: "https://youtube.com/@yourbrand",
          prefixIcon: const Icon(Icons.play_circle_outline, color: Colors.red),
        ),
        const SizedBox(height: 16),
        
        PremiumTextField(
          label: "Facebook Page (Optional)",
          initialValue: provider.facebookLink,
          onChanged: provider.setFacebookLink,
          hintText: "https://facebook.com/yourbrand",
          prefixIcon: const Icon(Icons.facebook, color: Colors.blue),
        ),
        const SizedBox(height: 16),
        
        PremiumTextField(
          label: "WhatsApp Group (Optional)",
          initialValue: provider.whatsappNumber,
          onChanged: provider.setWhatsappNumber,
          keyboardType: TextInputType.url,
          hintText: "Paste group invite link here",
          prefixIcon: const Icon(Icons.group_outlined, color: Colors.green),
        ),
        const SizedBox(height: 32),
      ],
      ),
    );
  }

  Widget _buildPreviewStep(StoreSetupProvider provider) {
    return SingleChildScrollView(
      key: const ValueKey('preview'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
          const Text(
            "Store Preview",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              "This is exactly how customers will see your brand.",
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          
          // Premium Customer App style profile card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08), 
                  blurRadius: 30, 
                  offset: const Offset(0, 15),
                  spreadRadius: -5,
                ),
              ],
              border: Border.all(color: Colors.grey.shade100, width: 1.5),
            ),
            child: Column(
              children: [
                // Store Header
                SizedBox(
                  height: 240,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Banner Image
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        bottom: 60,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.05),
                            image: provider.bannerFile != null
                                ? DecorationImage(image: FileImage(provider.bannerFile!), fit: BoxFit.cover)
                                : null,
                          ),
                          child: provider.bannerFile == null
                              ? Center(child: Icon(Icons.image, color: AppColors.primary.withOpacity(0.2), size: 40))
                              : null,
                        ),
                      ),
                      // Gradient overlay
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        bottom: 60,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.3),
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
                        height: 60,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
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
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 5),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5)),
                              ],
                              image: provider.logoFile != null
                                  ? DecorationImage(image: FileImage(provider.logoFile!), fit: BoxFit.cover)
                                  : null,
                            ),
                            child: provider.logoFile == null
                                ? Icon(Icons.store, color: AppColors.primary.withOpacity(0.3), size: 48)
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Store Info Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              provider.storeName.isEmpty ? "Your Brand Name" : provider.storeName,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                                fontFamily: 'serif',
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.verified, color: Colors.blue, size: 22),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        provider.storeHandle.isEmpty ? "@your_brand_handle" : "@${provider.storeHandle}",
                        style: TextStyle(
                          color: Colors.green.shade700, 
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 54),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: const Text("Follow", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
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
