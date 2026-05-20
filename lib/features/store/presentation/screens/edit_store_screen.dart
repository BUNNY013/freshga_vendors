import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/models/store_model.dart';
import '../../../../core/theme/app_colors.dart';

class EditStoreScreen extends StatefulWidget {
  const EditStoreScreen({super.key});

  @override
  State<EditStoreScreen> createState() => _EditStoreScreenState();
}

class _EditStoreScreenState extends State<EditStoreScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;
  StoreModel? _store;

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _instaController;
  late TextEditingController _youtubeController;
  late TextEditingController _facebookController;

  // Image files
  File? _newLogoFile;
  File? _newBannerFile;

  // Upload progress
  double _logoUploadProgress = 0;
  double _bannerUploadProgress = 0;
  bool _uploadingLogo = false;
  bool _uploadingBanner = false;

  // Settings
  String _dispatchTime = '24 hours';
  List<String> _selectedCategories = [];

  static const _allCategories = [
    'Pickles', 'Snacks', 'Sweets', 'Chutneys', 'Baked Goods',
    'Beverages', 'Rice & Grains', 'Spices', 'Papads', 'Jams & Spreads',
    'Health Foods', 'Festival Specials',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descController = TextEditingController();
    _instaController = TextEditingController();
    _youtubeController = TextEditingController();
    _facebookController = TextEditingController();
    _loadStoreData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _instaController.dispose();
    _youtubeController.dispose();
    _facebookController.dispose();
    super.dispose();
  }

  Future<void> _loadStoreData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final userModel = UserModel.fromJson(userDoc.data()!);
    if (userModel.storeId.isNotEmpty) {
      final storeDoc = await FirebaseFirestore.instance
          .collection('stores')
          .doc(userModel.storeId)
          .get();
      if (storeDoc.exists) {
        _store = StoreModel.fromJson(storeDoc.data()!);
        _nameController.text = _store!.storeName;
        _descController.text = _store!.description;
        _instaController.text = _store!.instagramLink;
        _youtubeController.text = _store!.youtubeLink;
        _facebookController.text = _store!.facebookLink;
        _dispatchTime = _store!.dispatchTime;
        _selectedCategories = List<String>.from(_store!.categories);
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _pickImage(bool isLogo) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    setState(() {
      if (isLogo) {
        _newLogoFile = File(picked.path);
      } else {
        _newBannerFile = File(picked.path);
      }
    });
  }

  Future<String?> _uploadImage(File file, bool isLogo) async {
    if (_store == null) return null;
    final path = isLogo
        ? 'store_assets/logos/${_store!.storeId}.jpg'
        : 'store_assets/banners/${_store!.storeId}.jpg';
    final ref = FirebaseStorage.instance.ref().child(path);
    final task = ref.putFile(file);
    task.snapshotEvents.listen((snapshot) {
      final progress = snapshot.bytesTransferred / snapshot.totalBytes;
      if (mounted) {
        setState(() {
          if (isLogo) {
            _logoUploadProgress = progress;
          } else {
            _bannerUploadProgress = progress;
          }
        });
      }
    });
    await task;
    return await ref.getDownloadURL();
  }

  Future<void> _saveStore() async {
    if (!_formKey.currentState!.validate() || _store == null) return;
    setState(() => _isSaving = true);

    try {
      String logoUrl = _store!.logo;
      String bannerUrl = _store!.banner;

      if (_newLogoFile != null) {
        setState(() => _uploadingLogo = true);
        logoUrl = await _uploadImage(_newLogoFile!, true) ?? logoUrl;
        if (mounted) setState(() => _uploadingLogo = false);
      }

      if (_newBannerFile != null) {
        setState(() => _uploadingBanner = true);
        bannerUrl = await _uploadImage(_newBannerFile!, false) ?? bannerUrl;
        if (mounted) setState(() => _uploadingBanner = false);
      }

      final updatedStore = _store!.copyWith(
        storeName: _nameController.text.trim(),
        storeSlug: _nameController.text.trim().toLowerCase().replaceAll(' ', '-'),
        description: _descController.text.trim(),
        logo: logoUrl,
        banner: bannerUrl,
        instagramLink: _instaController.text.trim(),
        youtubeLink: _youtubeController.text.trim(),
        facebookLink: _facebookController.text.trim(),
        dispatchTime: _dispatchTime,
        categories: _selectedCategories,
        updatedAt: DateTime.now().toIso8601String(),
      );

      await FirebaseFirestore.instance
          .collection('stores')
          .doc(_store!.storeId)
          .update(updatedStore.toJson());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Store updated successfully! ✅'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Edit Store',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Stack(
              children: [
                // ── Scrollable content ──────────────────────────────────
                SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 100),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Banner + Logo
                        _buildBannerLogoSection(),
                        const SizedBox(height: 20),

                        // 2. Store Identity
                        _buildSection(
                          icon: Icons.storefront_outlined,
                          title: 'Store Identity',
                          children: [
                            _buildField(
                              controller: _nameController,
                              label: 'Store Name',
                              hint: 'e.g. FreshGa HomeMades',
                              icon: Icons.badge_outlined,
                              validator: (v) =>
                                  v == null || v.isEmpty ? 'Store name is required' : null,
                            ),
                            const SizedBox(height: 16),
                            _buildField(
                              controller: _descController,
                              label: 'Brand Story / Bio',
                              hint: 'Tell customers what makes your food special...',
                              icon: Icons.auto_stories_outlined,
                              maxLines: 4,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // 3. Social Links
                        _buildSection(
                          icon: Icons.share_outlined,
                          title: 'Social Links',
                          children: [
                            _buildField(
                              controller: _instaController,
                              label: 'Instagram URL',
                              hint: 'https://instagram.com/yourpage',
                              icon: Icons.camera_alt_outlined,
                              keyboardType: TextInputType.url,
                            ),
                            const SizedBox(height: 14),
                            _buildField(
                              controller: _youtubeController,
                              label: 'YouTube Channel URL',
                              hint: 'https://youtube.com/@yourchannel',
                              icon: Icons.play_circle_outline,
                              keyboardType: TextInputType.url,
                            ),
                            const SizedBox(height: 14),
                            _buildField(
                              controller: _facebookController,
                              label: 'Facebook Page URL',
                              hint: 'https://facebook.com/yourpage',
                              icon: Icons.facebook,
                              keyboardType: TextInputType.url,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // 4. Store Settings
                        _buildSection(
                          icon: Icons.settings_outlined,
                          title: 'Store Settings',
                          children: [
                            _buildDispatchDropdown(),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // 5. Categories
                        _buildSection(
                          icon: Icons.category_outlined,
                          title: 'Categories',
                          subtitle: 'Select what your store sells',
                          children: [
                            _buildCategoriesGrid(),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                // ── Sticky bottom Save button ────────────────────────────
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 16,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSaving || _isLoading ? null : _saveStore,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppColors.grey300,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_outline, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Save Changes',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // ─── Banner + Logo Section ───────────────────────────────────────────────

  Widget _buildBannerLogoSection() {
    return Column(
      children: [
        // ── Banner ───────────────────────────────────────────────────────
        Stack(
          children: [
            // Banner image
            GestureDetector(
              onTap: () => _pickImage(false),
              child: Container(
                height: 200,
                width: double.infinity,
                color: AppColors.grey200,
                child: _newBannerFile != null
                    ? Image.file(_newBannerFile!, fit: BoxFit.cover)
                    : (_store?.banner.isNotEmpty == true
                        ? Image.network(
                            _store!.banner,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _bannerFallback(),
                          )
                        : _bannerFallback()),
              ),
            ),
            // Overlay
            Positioned.fill(
              child: GestureDetector(
                onTap: () => _pickImage(false),
                child: Container(color: Colors.black.withOpacity(0.2)),
              ),
            ),
            // Upload progress
            if (_uploadingBanner)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          value: _bannerUploadProgress,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${(_bannerUploadProgress * 100).toInt()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            // Change banner chip
            Positioned(
              bottom: 12,
              right: 12,
              child: GestureDetector(
                onTap: () => _pickImage(false),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.camera_alt, color: Colors.white, size: 15),
                      SizedBox(width: 6),
                      Text(
                        'Change Banner',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        // ── Logo + status indicators ──────────────────────────────────────
        Container(
          width: double.infinity,
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Column(
            children: [
              // Logo circle
              GestureDetector(
                onTap: () => _pickImage(true),
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.grey100,
                        border: Border.all(color: AppColors.grey200, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: _newLogoFile != null
                            ? Image.file(_newLogoFile!, fit: BoxFit.cover)
                            : (_store?.logo.isNotEmpty == true
                                ? Image.network(
                                    _store!.logo,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.fastfood,
                                      size: 38,
                                      color: AppColors.grey400,
                                    ),
                                  )
                                : const Icon(
                                    Icons.fastfood,
                                    size: 38,
                                    color: AppColors.grey400,
                                  )),
                      ),
                    ),
                    // Upload spinner
                    if (_uploadingLogo)
                      Positioned.fill(
                        child: ClipOval(
                          child: Container(
                            color: Colors.black.withOpacity(0.45),
                            child: Center(
                              child: CircularProgressIndicator(
                                value: _logoUploadProgress,
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    // Camera badge
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tap to change logo',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.grey500,
                  fontWeight: FontWeight.w500,
                ),
              ),
              // Selection status chips
              if (_newLogoFile != null || _newBannerFile != null) ...[
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_newLogoFile != null)
                      _buildSelectedChip('✓ New logo ready'),
                    if (_newLogoFile != null && _newBannerFile != null)
                      const SizedBox(width: 8),
                    if (_newBannerFile != null)
                      _buildSelectedChip('✓ New banner ready'),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          color: Colors.green,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _bannerFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFD66853), Color(0xFFE8896B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.store_mall_directory_outlined,
          size: 56,
          color: Colors.white38,
        ),
      ),
    );
  }

  // ─── Section wrapper ─────────────────────────────────────────────────────

  Widget _buildSection({
    required IconData icon,
    required String title,
    String? subtitle,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: AppColors.grey500),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: AppColors.grey200),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }

  // ─── Input field ─────────────────────────────────────────────────────────

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.grey400, fontSize: 13),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        filled: true,
        fillColor: AppColors.grey100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.grey200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  // ─── Dispatch dropdown ────────────────────────────────────────────────────

  Widget _buildDispatchDropdown() {
    return DropdownButtonFormField<String>(
      value: _dispatchTime,
      decoration: InputDecoration(
        labelText: 'Dispatch / Delivery Time',
        prefixIcon: const Icon(Icons.local_shipping_outlined, color: AppColors.primary, size: 20),
        filled: true,
        fillColor: AppColors.grey100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.grey200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      items: const [
        DropdownMenuItem(value: 'Same Day', child: Text('Same Day')),
        DropdownMenuItem(value: '24 hours', child: Text('Within 24 hours')),
        DropdownMenuItem(value: '48 hours', child: Text('Within 48 hours')),
        DropdownMenuItem(value: '3-4 days', child: Text('3–4 days')),
        DropdownMenuItem(value: '1 week', child: Text('Within 1 week')),
      ],
      onChanged: (val) {
        if (val != null) setState(() => _dispatchTime = val);
      },
    );
  }

  // ─── Categories grid ─────────────────────────────────────────────────────

  Widget _buildCategoriesGrid() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _allCategories.map((cat) {
        final isSelected = _selectedCategories.contains(cat);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedCategories.remove(cat);
              } else {
                _selectedCategories.add(cat);
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.grey100,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.grey300,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected) ...[
                  const Icon(Icons.check, color: Colors.white, size: 13),
                  const SizedBox(width: 4),
                ],
                Text(
                  cat,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
