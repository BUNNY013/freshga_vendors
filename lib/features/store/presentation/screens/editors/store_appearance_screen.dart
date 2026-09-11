import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../../../../../core/theme/app_colors.dart';

class StoreAppearanceScreen extends StatefulWidget {
  const StoreAppearanceScreen({super.key});

  @override
  State<StoreAppearanceScreen> createState() => _StoreAppearanceScreenState();
}

class _StoreAppearanceScreenState extends State<StoreAppearanceScreen> {
  final ImagePicker _picker = ImagePicker();
  
  File? _bannerImage;
  File? _logoImage;
  
  // Existing placeholder network images
  final String _placeholderBanner = 'assets/images/default_banner.png';
  final String _placeholderLogo = 'assets/images/default_logo.png';

  Future<void> _pickAndCropImage({required bool isBanner}) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final CroppedFile? croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedFile.path,
          aspectRatio: isBanner 
              ? const CropAspectRatio(ratioX: 16, ratioY: 6) 
              : const CropAspectRatio(ratioX: 1, ratioY: 1),
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: isBanner ? 'Crop Banner' : 'Crop Logo',
              toolbarColor: AppColors.primary,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: isBanner ? CropAspectRatioPreset.ratio16x9 : CropAspectRatioPreset.square, // Fallback predefined preset
              lockAspectRatio: true,
              hideBottomControls: true,
            ),
            IOSUiSettings(
              title: isBanner ? 'Crop Banner' : 'Crop Logo',
              aspectRatioLockEnabled: true,
              resetAspectRatioEnabled: false,
            ),
          ],
        );

        if (croppedFile != null) {
          setState(() {
            if (isBanner) {
              _bannerImage = File(croppedFile.path);
            } else {
              _logoImage = File(croppedFile.path);
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error picking/cropping image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Store Appearance',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 17),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Store Banner'),
            const SizedBox(height: 12),
            _buildBannerEditor(),
            const SizedBox(height: 8),
            const Text(
              'Recommended size: 1600 x 600 px, JPG, PNG up to 5MB.',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 32),
            _buildSectionTitle('Store Logo'),
            const SizedBox(height: 12),
            _buildLogoEditor(),
            const SizedBox(height: 8),
            const Text(
              'Recommended size: 512 x 512 px, PNG, JPG up to 2MB.',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomButton(context),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
    );
  }

  Widget _buildBannerEditor() {
    return Stack(
      children: [
        GestureDetector(
          onTap: () => _pickAndCropImage(isBanner: true),
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              image: DecorationImage(
                image: _bannerImage != null
                    ? FileImage(_bannerImage!) as ImageProvider
                    : AssetImage(_placeholderBanner),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 8,
          right: 8,
          child: GestureDetector(
            onTap: () => _pickAndCropImage(isBanner: true),
            child: _buildEditIcon(),
          ),
        ),
      ],
    );
  }

  Widget _buildLogoEditor() {
    return Stack(
      children: [
        GestureDetector(
          onTap: () => _pickAndCropImage(isBanner: false),
          child: Container(
            height: 96,
            width: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: _logoImage != null
                    ? FileImage(_logoImage!) as ImageProvider
                    : AssetImage(_placeholderLogo),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: () => _pickAndCropImage(isBanner: false),
            child: _buildEditIcon(),
          ),
        ),
      ],
    );
  }

  Widget _buildEditIcon() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 16),
    );
  }

  Widget _buildBottomButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: ElevatedButton(
        onPressed: () => context.pop(),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      ),
    );
  }
}
