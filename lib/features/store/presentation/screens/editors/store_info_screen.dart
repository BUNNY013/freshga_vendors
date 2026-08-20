import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../data/models/user_model.dart';

class StoreInfoScreen extends StatefulWidget {
  const StoreInfoScreen({super.key});

  @override
  State<StoreInfoScreen> createState() => _StoreInfoScreenState();
}

class _StoreInfoScreenState extends State<StoreInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _descController = TextEditingController();
  
  String? _storeId;
  String _originalDesc = '';
  String _originalLogo = '';
  String _originalBanner = '';
  
  File? _newLogoFile;
  File? _newBannerFile;
  
  bool _isLoading = true;
  bool _isSaving = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchStoreInfo();
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _fetchStoreInfo() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not authenticated');

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (!userDoc.exists) throw Exception('User not found');
      
      final userModel = UserModel.fromJson(userDoc.data()!);
      _storeId = userModel.storeId;
      
      if (_storeId == null || _storeId!.isEmpty) {
        throw Exception('No store linked to this user');
      }

      final storeDoc = await FirebaseFirestore.instance.collection('stores').doc(_storeId).get();
      if (storeDoc.exists) {
        final data = storeDoc.data()!;
        _originalDesc = data['description'] ?? '';
        _originalLogo = data['logo'] ?? '';
        _originalBanner = data['banner'] ?? '';
        
        _descController.text = _originalDesc;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickImage(bool isLogo) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatio: isLogo 
            ? const CropAspectRatio(ratioX: 1, ratioY: 1)
            : const CropAspectRatio(ratioX: 16, ratioY: 9), // Standard widescreen ratio to match the 260px container height
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: isLogo ? 'Position Logo' : 'Position Banner',
            toolbarColor: const Color(0xFF0F172A), // Sleek dark slate
            toolbarWidgetColor: Colors.white,
            activeControlsWidgetColor: AppColors.primary,
            dimmedLayerColor: Colors.black.withOpacity(0.8), // Darken background to focus on crop
            cropFrameColor: Colors.white,
            cropGridColor: Colors.white38,
            initAspectRatio: isLogo ? CropAspectRatioPreset.square : CropAspectRatioPreset.ratio16x9,
            lockAspectRatio: true,
            hideBottomControls: true, // Hide complex rotation tools for a simpler Instagram feel
            cropStyle: isLogo ? CropStyle.circle : CropStyle.rectangle,
          ),
          IOSUiSettings(
            title: isLogo ? 'Position Logo' : 'Position Banner',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
            resetButtonHidden: true,
            aspectRatioPickerButtonHidden: true,
            rotateButtonsHidden: true,
            rotateClockwiseButtonHidden: true,
            cropStyle: isLogo ? CropStyle.circle : CropStyle.rectangle,
          ),
        ],
      );

      if (croppedFile != null) {
        setState(() {
          if (isLogo) {
            _newLogoFile = File(croppedFile.path);
          } else {
            _newBannerFile = File(croppedFile.path);
          }
        });
      }
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    if (_storeId == null) return;

    setState(() => _isSaving = true);

    try {
      final updateData = <String, dynamic>{
        'description': _descController.text.trim(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      // Upload Logo if changed
      if (_newLogoFile != null) {
        final ref = FirebaseStorage.instance.ref().child('store_assets/$_storeId/logo_${DateTime.now().millisecondsSinceEpoch}.jpg');
        await ref.putFile(_newLogoFile!);
        final logoUrl = await ref.getDownloadURL();
        updateData['logo'] = logoUrl;
      }

      // Upload Banner if changed
      if (_newBannerFile != null) {
        final ref = FirebaseStorage.instance.ref().child('store_assets/$_storeId/banner_${DateTime.now().millisecondsSinceEpoch}.jpg');
        await ref.putFile(_newBannerFile!);
        final bannerUrl = await ref.getDownloadURL();
        updateData['banner'] = bannerUrl;
      }
      
      await FirebaseFirestore.instance.collection('stores').doc(_storeId).update(updateData);

      _originalDesc = _descController.text.trim();
      _newLogoFile = null;
      _newBannerFile = null;

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<bool> _onWillPop() async {
    final hasChanges = _descController.text.trim() != _originalDesc || _newLogoFile != null || _newBannerFile != null;
    
    if (hasChanges && !_isSaving) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Discard Changes?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                const SizedBox(height: 12),
                const Text('You have unsaved changes.', style: TextStyle(fontSize: 14, color: Color(0xFF475569))),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Discard', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      );
      return confirm ?? false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: const Text('Edit Profile', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 16)),
          leading: IconButton(
            icon: const Icon(Icons.close, color: Color(0xFF0F172A)),
            onPressed: () async {
              if (await _onWillPop() && mounted) context.pop();
            },
          ),
          actions: [
            if (!_isLoading)
              TextButton(
                onPressed: _isSaving ? null : _saveChanges,
                child: _isSaving 
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                  : const Text('Done', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            const SizedBox(width: 8),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Banner and Logo Stack (Twitter/X style)
                      SizedBox(
                        height: 220,
                        child: Stack(
                          alignment: Alignment.topCenter,
                          clipBehavior: Clip.none,
                          children: [
                            // Banner
                            GestureDetector(
                              onTap: () => _pickImage(false),
                              child: Stack(
                                children: [
                                  Container(
                                    height: 160,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      image: _newBannerFile != null 
                                          ? DecorationImage(image: FileImage(_newBannerFile!), fit: BoxFit.cover)
                                          : (_originalBanner.isNotEmpty
                                              ? DecorationImage(image: NetworkImage(_originalBanner), fit: BoxFit.cover)
                                              : null),
                                    ),
                                    child: (_newBannerFile == null && _originalBanner.isEmpty)
                                        ? const Center(child: Icon(Icons.image_outlined, color: Color(0xFFCBD5E1), size: 40))
                                        : null,
                                  ),
                                  // Floating Camera Badge for Banner
                                  Positioned(
                                    right: 16,
                                    bottom: 16,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2)),
                                        ],
                                      ),
                                      child: const Icon(Icons.camera_alt_outlined, size: 18, color: Color(0xFF0F172A)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Logo
                            Positioned(
                              bottom: 0,
                              child: GestureDetector(
                                onTap: () => _pickImage(true),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      height: 100,
                                      width: 100,
                                      decoration: BoxDecoration(
                                        color: _newLogoFile == null && _originalLogo.isEmpty ? const Color(0xFFF0FDF4) : Colors.white,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 4),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.06),
                                            blurRadius: 12,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                        image: _newLogoFile != null 
                                            ? DecorationImage(image: FileImage(_newLogoFile!), fit: BoxFit.cover)
                                            : (_originalLogo.isNotEmpty
                                                ? DecorationImage(image: NetworkImage(_originalLogo), fit: BoxFit.cover)
                                                : null),
                                      ),
                                      child: (_newLogoFile == null && _originalLogo.isEmpty)
                                          ? const Icon(Icons.storefront_rounded, size: 40, color: AppColors.primary)
                                          : null,
                                    ),
                                    // Floating Camera Badge for Logo
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4, offset: const Offset(0, 2)),
                                          ],
                                          border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                                        ),
                                        child: const Icon(Icons.camera_alt_outlined, size: 14, color: Color(0xFF0F172A)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      GestureDetector(
                        onTap: () => _pickImage(true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Text(
                            'Edit picture or banner',
                            style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Minimalist Form Fields
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Store Story', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _descController,
                              maxLines: 5,
                              maxLength: 1000,
                              style: const TextStyle(fontSize: 15, color: Color(0xFF0F172A), height: 1.5),
                              decoration: InputDecoration(
                                hintText: 'Tell your story...',
                                hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFF1F5F9))),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                                contentPadding: const EdgeInsets.all(16),
                                counterStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'Story cannot be empty';
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
