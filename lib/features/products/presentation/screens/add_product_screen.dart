import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/product_model.dart';
import '../../../../data/models/product_variant_model.dart';
import '../providers/product_provider.dart';
import '../widgets/vendor_product_preview.dart';
import 'under_review_details_screen.dart';

class AddProductScreen extends StatelessWidget {
  final ProductModel? product;
  const AddProductScreen({super.key, this.product});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProductProvider(),
      child: _AddProductWizard(product: product),
    );
  }
}

class _AddProductWizard extends StatefulWidget {
  final ProductModel? product;
  const _AddProductWizard({this.product});

  @override
  State<_AddProductWizard> createState() => _AddProductWizardState();
}

class _AddProductWizardState extends State<_AddProductWizard> {
  final PageController _pageController = PageController();
  final ScrollController _galleryScrollController = ScrollController();
  int _currentPage = 0;
  final int _totalPages = 3; 

  // State Variables
  String _categoryId = '';
  String _categoryName = '';
  List<String> _subCategoryIds = [];
  
  // Product Details State
  String _name = '';
  String _shortDescription = '';
  String _dispatchTimeQty = '';
  String _dispatchTimeUnit = 'Days';
  String get _dispatchTime => _dispatchTimeQty.isEmpty ? '' : '$_dispatchTimeQty $_dispatchTimeUnit';

  String _shelfLifeQty = '';
  String _shelfLifeUnit = 'Months';
  String get _shelfLife => _shelfLifeQty.isEmpty ? '' : '$_shelfLifeQty $_shelfLifeUnit';
  
  // Packs & Extras
  List<ProductVariantModel> _packSizes = [];
  List<String> _ingredients = [];
  String _storageInstructions = '';
  bool _showStock = false;
  String _dietaryType = 'Pure Veg'; // 'Pure Veg', 'Non-Veg', 'Vegan', 'Contains Egg'

  // Form Keys
  final _formDetails = GlobalKey<FormState>();
  final TextEditingController _ingredientCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ProductProvider>();
      provider.loadCategories();
      
      if (widget.product != null) {
        final p = widget.product!;
        setState(() {
          _categoryId = p.categoryId;
          _categoryName = p.categoryName;
          _subCategoryIds = List.from(p.subCategoryIds);
          
          _name = p.name;
          _shortDescription = p.shortDescription;
          _storageInstructions = p.storageInstructions;
          _showStock = p.showStockToCustomers;
          
          // Parse dispatch
          if (p.dispatchTime.contains(' ')) {
            final parts = p.dispatchTime.split(' ');
            _dispatchTimeQty = parts[0];
            _dispatchTimeUnit = parts[1];
          }
          // Parse shelf
          if (p.shelfLife.contains(' ')) {
            final parts = p.shelfLife.split(' ');
            _shelfLifeQty = parts[0];
            _shelfLifeUnit = parts[1];
          }
          
          _packSizes = List.from(p.variants);
          _ingredients = List.from(p.ingredients);
          if (p.tags.isNotEmpty) {
            final validDietary = ['Pure Veg', 'Non-Veg', 'Vegan', 'Contains Egg', 'Egg'];
            for (var tag in p.tags) {
              if (validDietary.contains(tag)) {
                _dietaryType = tag == 'Egg' ? 'Contains Egg' : tag;
                break;
              }
            }
          }
        });
        
        // Ensure subcategories are loaded so they populate the UI on Step 2
        provider.loadSubCategories(p.categoryId);
        
        // We shouldn't load network images into local File picker directly 
        // without downloading, but for MVP we assume the user just edits text or adds new files.
        // Or the provider handles existing images.
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _galleryScrollController.dispose();
    _ingredientCtrl.dispose();
    super.dispose();
  }

  bool _hasValidSubCategories(ProductProvider provider) {
    if (_subCategoryIds.isEmpty) return false;
    return _subCategoryIds.any((id) => provider.subCategories.any((s) => s.subCategoryId == id));
  }

  void _nextPage() {
    if (_currentPage == 0) {
      if (_categoryId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a category')));
        return;
      }
    } else if (_currentPage == 1) {
      final provider = context.read<ProductProvider>();
      if (!_hasValidSubCategories(provider)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one sub category for this category')));
        return;
      }
    } else if (_currentPage == 2) {
      // Final submission validation
      final provider = context.read<ProductProvider>();
      if (provider.selectedImages.isEmpty && (widget.product == null || widget.product!.images.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add at least one photo')));
        return;
      }
      if (_packSizes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add at least one pack size')));
        return;
      }
      
      // We no longer automatically submit here; the sticky bottom bar buttons trigger submission explicitly.
      return;
    }

    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _showExitConfirmationSheet();
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.grey600, fontWeight: FontWeight.w500),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.red, width: 1)),
    );
  }

  InputDecoration _premiumInputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: AppColors.grey500, fontWeight: FontWeight.w500, fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
    );
  }

  Widget _buildLabel(String text, {bool required = false}) {
    return RichText(
      text: TextSpan(
        text: text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        children: [
          if (required) const TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _prevPage();
      },
      child: Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            _currentPage == 0 ? Icons.close_rounded : Icons.arrow_back_ios_new,
            color: AppColors.textPrimary,
            size: _currentPage == 0 ? 24 : 20,
          ),
          onPressed: _prevPage,
        ),
        title: const Text(
          'Add Product',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w900,
            fontSize: 26,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: false,
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F8E9),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              'Step ${_currentPage + 1} of $_totalPages',
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          if (_currentPage > 0) ...[
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary, size: 24),
              onPressed: _showExitConfirmationSheet,
              tooltip: 'Cancel',
            ),
          ] else
            const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          _buildTopStepper(),
          if (widget.product?.status == 'Changes Required' && widget.product!.adminFeedback.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3F3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFCDCD)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFD32F2F), size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Changes Required", style: TextStyle(color: Color(0xFFD32F2F), fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 2),
                        Text(widget.product!.adminFeedback, style: const TextStyle(color: Color(0xFFC62828), fontSize: 13, height: 1.4)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: PageView(
              controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (page) => setState(() => _currentPage = page),
        children: [
          _buildStep1Type(),
            _buildStep2Collections(),
            _buildStep3ProductDetails(),
          ],
        ),
      )],
      ),
      bottomNavigationBar: _buildStickyBottomBar(),
      ),
    );
  }

  Widget _buildTopStepper() {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_totalPages * 2 - 1, (index) {
          if (index % 2 != 0) {
            // Line
            int lineIdx = index ~/ 2;
            bool isActive = _currentPage > lineIdx;
            return Container(
              width: 40, height: 2,
              color: isActive ? AppColors.primary : AppColors.grey300,
            );
          } else {
            // Dot
            int dotIdx = index ~/ 2;
            bool isCurrent = _currentPage == dotIdx;
            bool isPast = _currentPage > dotIdx;
            return Container(
              width: 12, height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isPast || isCurrent ? AppColors.primary : AppColors.grey300,
                border: isCurrent ? Border.all(color: AppColors.primaryLight, width: 3) : null,
              ),
            );
          }
        }),
      ),
    );
  }

  Widget _buildStickyBottomBar() {
    final provider = context.watch<ProductProvider>();
    if (_currentPage == 2) {
      return Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFF16A34A), Color(0xFF15803D)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF16A34A).withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: provider.isLoading ? null : _showSubmitConfirmationDialog,
              borderRadius: BorderRadius.circular(16),
              child: Center(
                child: provider.isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            widget.product?.status == 'Changes Required' ? "Resubmit for Review" : "Submit Product for Review",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      );
    }

    String buttonText = "Continue";
    if (_currentPage == 0) {
      buttonText = _categoryId.isNotEmpty ? "Continue →" : "Continue →";
    } else if (_currentPage == 1) {
      buttonText = "Continue →";
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: ElevatedButton(
        onPressed: (_currentPage == 0 && _categoryId.isEmpty) || (_currentPage == 1 && (provider.isLoading || !_hasValidSubCategories(provider))) ? null : _nextPage,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.primaryLight,
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              buttonText.replaceAll(" →", ""),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }

  // --- STEP 1: CATEGORY SELECTION ---

  Widget _buildStep1Type() {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        final categories = provider.categories;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("What are you selling?", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              const Text("Choose the type of product you sell", style: TextStyle(fontSize: 16, color: AppColors.grey600)),
              const SizedBox(height: 32),
              
              if (provider.isLoading && categories.isEmpty)
                const Center(child: CircularProgressIndicator(color: AppColors.primary))
              else if (categories.isEmpty)
                const Center(child: Text("No categories available", style: TextStyle(color: AppColors.grey500)))
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.75, 
                  ),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    final isSelected = _categoryId == cat.categoryId;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_categoryId != cat.categoryId) {
                            _subCategoryIds.clear();
                          }
                          _categoryId = cat.categoryId;
                          _categoryName = cat.name;
                        });
                        provider.loadSubCategories(cat.categoryId); 
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primaryLight.withOpacity(0.5) : const Color(0xFFFFF4EA), 
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isSelected ? AppColors.primary : Colors.transparent, width: isSelected ? 2.5 : 0),
                          boxShadow: isSelected ? [BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4))] : [],
                        ),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 16.0),
                                      child: cat.imageUrl.isNotEmpty
                                          ? Transform.scale(
                                              scale: isSelected ? 1.05 : 1.15,
                                              child: CachedNetworkImage(
                                                imageUrl: cat.imageUrl,
                                                fit: BoxFit.contain,
                                                placeholder: (context, url) => const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))),
                                                errorWidget: (context, url, error) => const Icon(Icons.image_not_supported, color: Colors.grey),
                                              ),
                                            )
                                          : const Icon(Icons.category, color: Colors.grey, size: 40),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                    child: Text(
                                      cat.name,
                                      style: TextStyle(
                                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                        fontSize: 12,
                                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                        letterSpacing: -0.1,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Positioned(
                                top: 8, right: 8,
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.check_circle, color: AppColors.primary, size: 24),
                                ),
                              )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 48),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(16)),
                child: const Row(
                  children: [
                    Text("⭐", style: TextStyle(fontSize: 24)),
                    SizedBox(width: 16),
                    Expanded(child: Text("Don't worry!\nYou can add more details later.", style: TextStyle(color: Color(0xFFF57F17), fontWeight: FontWeight.bold))),
                  ],
                ),
              )
            ],
          ),
        );
      }
    );
  }

  // --- STEP 2: SUB CATEGORIES ---

  Widget _buildStep2Collections() {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        final subCategories = provider.subCategories;

        // Build selected summary string
        String summary = "";
        if (_subCategoryIds.isNotEmpty) {
          final selectedSubs = subCategories.where((s) => _subCategoryIds.contains(s.subCategoryId)).toList();
          if (selectedSubs.isNotEmpty) {
            summary = "${_subCategoryIds.length} Selected: ";
            summary += "[${selectedSubs.first.name}] ";
            if (selectedSubs.length > 1) {
              summary += "[${selectedSubs[1].name}] ";
            }
            if (selectedSubs.length > 2) {
              summary += "[+${selectedSubs.length - 2}]";
            }
          }
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Choose the type of $_categoryName",
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Row(
                children: [
                  Icon(Icons.checklist_rtl_rounded, size: 18, color: AppColors.primary),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      "You can select multiple types that match your product",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.grey600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              
              if (provider.isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: AppColors.primary),
                        SizedBox(height: 12),
                        Text("Loading sub categories...", style: TextStyle(color: AppColors.grey500, fontSize: 13)),
                      ],
                    ),
                  ),
                )
              else if (subCategories.isEmpty)
                const Text("No sub categories available for this category.", style: TextStyle(color: AppColors.grey500))
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.70,
                  ),
                  itemCount: subCategories.length,
                  itemBuilder: (context, index) {
                    final sub = subCategories[index];
                    final isSelected = _subCategoryIds.contains(sub.subCategoryId);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _subCategoryIds.remove(sub.subCategoryId);
                          } else {
                            _subCategoryIds.add(sub.subCategoryId);
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : Colors.transparent,
                            width: isSelected ? 2.5 : 0,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.18),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  )
                                ]
                              : [],
                        ),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 16.0),
                                      child: sub.imageUrl.isNotEmpty
                                          ? Transform.scale(
                                              scale: isSelected ? 1.05 : 1.15,
                                              child: CachedNetworkImage(
                                                imageUrl: sub.imageUrl,
                                                fit: BoxFit.contain,
                                                placeholder: (context, url) => const Center(
                                                  child: SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: AppColors.primary,
                                                    ),
                                                  ),
                                                ),
                                                errorWidget: (context, url, error) =>
                                                    const Icon(Icons.image_not_supported, color: Colors.grey),
                                              ),
                                            )
                                          : const Icon(Icons.category, color: Colors.grey, size: 40),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    height: 34,
                                    alignment: Alignment.topCenter,
                                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                    child: Text(
                                      sub.name,
                                      style: TextStyle(
                                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                        fontSize: 11.5,
                                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                        letterSpacing: -0.1,
                                        height: 1.15,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              ),
                             ),
                            if (isSelected)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${_subCategoryIds.indexOf(sub.subCategoryId) + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      height: 1.0,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              
              const SizedBox(height: 32),
              if (_subCategoryIds.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(Icons.collections_bookmark, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(child: Text(summary, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary))),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(12)),
                  child: const Text("Customers can discover your product through these collections.", style: TextStyle(color: AppColors.grey500)),
                ),
            ],
          ),
        );
      },
    );
  }

  // --- STEP 3: SINGLE SCROLL PRODUCT DETAILS WITH ELEVATED CARDS ---

  Widget _buildStep3ProductDetails() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Form(
        key: _formDetails,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Consumer<ProductProvider>(
              builder: (context, provider, _) {
                final subCategories = provider.subCategories;
                final selectedSubs = subCategories.where((s) => _subCategoryIds.contains(s.subCategoryId)).toList();
                
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.category_rounded, size: 20, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            _categoryName,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textPrimary),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => _pageController.animateToPage(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                            child: const Text("Edit", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        ],
                      ),
                      if (selectedSubs.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: selectedSubs.map((sub) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(color: const Color(0xFFBBF7D0)),
                            ),
                            child: Text(
                              sub.name,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          )).toList(),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            _buildPhotosSection(),
            const SizedBox(height: 24),

            _buildIdentityAndDietarySection(),
            const SizedBox(height: 24),

            _buildPacksSection(),
            const SizedBox(height: 24),

            _buildFreshnessAndHandlingSection(),
            const SizedBox(height: 24),

            _buildPreviewSection(),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCard({
    required String title,
    required IconData icon,
    required Widget child,
    String? subtitle,
    String? trailing,
    Widget? trailingWidget,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.grey500)),
                    ],
                  ],
                ),
              ),
              if (trailingWidget != null)
                trailingWidget
              else if (trailing != null)
                Text(trailing, style: const TextStyle(fontSize: 12, color: AppColors.grey500, fontWeight: FontWeight.w600)),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
          ),
          child,
        ],
      ),
    );
  }

  // --- SECTIONS FOR STEP 3 ---

  void _showFullScreenImage(File imageFile) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.file(
                  imageFile,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotosSection() {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        return _buildStepCard(
          title: "1. Product Photos & Media",
          subtitle: "Cover photo + up to 9 gallery photos",
          icon: Icons.photo_library_outlined,
          trailingWidget: Row(
            children: [
              Text("${provider.selectedImages.length}/10", style: const TextStyle(fontSize: 13, color: AppColors.grey600, fontWeight: FontWeight.bold)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (provider.selectedImages.isNotEmpty)
                Stack(
                  children: [
                    GestureDetector(
                      onTap: () => _showFullScreenImage(provider.selectedImages.first),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: SizedBox(
                            width: double.infinity,
                            child: Image.file(provider.selectedImages.first, fit: BoxFit.cover),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12, left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("Cover Photo (1:1)", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            SizedBox(width: 6),
                            Icon(Icons.zoom_in, color: Colors.white70, size: 14),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12, right: 12,
                      child: GestureDetector(
                        onTap: () => provider.removeImage(0),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                        ),
                      ),
                    )
                  ],
                )
              else
                GestureDetector(
                  onTap: provider.pickImages,
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.grey200),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined, color: AppColors.primary, size: 44),
                            SizedBox(height: 10),
                            Text("Add Cover Photo (1:1 Square)", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 14)),
                            SizedBox(height: 4),
                            Text("Perfect for customer app product cards", style: TextStyle(color: AppColors.grey500, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              
              if (provider.selectedImages.length > 1) ...[
                const SizedBox(height: 16),
                const Text(
                  "Gallery Photos",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
              ] else ...[
                const SizedBox(height: 12),
              ],
              Scrollbar(
                controller: _galleryScrollController,
                thumbVisibility: provider.selectedImages.length > 1,
                trackVisibility: provider.selectedImages.length > 1,
                thickness: 5,
                radius: const Radius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SingleChildScrollView(
                    controller: _galleryScrollController,
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        for (int i = 1; i < provider.selectedImages.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                GestureDetector(
                                  onTap: () => _showFullScreenImage(provider.selectedImages[i]),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: SizedBox(
                                      width: 70, height: 70,
                                      child: Image.file(provider.selectedImages[i], fit: BoxFit.cover),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: -4, left: -4,
                                  child: GestureDetector(
                                    onTap: () => provider.removeImage(i),
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                      child: const Icon(Icons.close, color: Colors.black, size: 14),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        if (provider.selectedImages.length < 10)
                          GestureDetector(
                            onTap: provider.pickImages,
                            child: Container(
                              width: 70, height: 70,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F8E9),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF81C784), style: BorderStyle.none),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add, color: AppColors.primary),
                                  Text("Add\nPhoto", textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              if (provider.selectedImages.length < 10)
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: OutlinedButton.icon(
                    onPressed: provider.pickImages,
                    icon: const Icon(Icons.add_photo_alternate_outlined, size: 20),
                    label: Text("Add More Photos (${provider.selectedImages.length}/10)", style: const TextStyle(fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 46),
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildIdentityAndDietarySection() {
    final options = [
      {'title': 'Pure Veg', 'sub': '100% Vegetarian', 'color': const Color(0xFF2E7D32), 'icon': '🟢'},
      {'title': 'Non-Veg', 'sub': 'Contains Meat / Fish', 'color': const Color(0xFFC62828), 'icon': '🔴'},
      {'title': 'Vegan', 'sub': 'No Dairy or Honey', 'color': const Color(0xFF1565C0), 'icon': '🌱'},
      {'title': 'Contains Egg', 'sub': 'Egg / Bakery items', 'color': const Color(0xFFF57F17), 'icon': '🟡'},
    ];

    return _buildStepCard(
      title: "2. Basic Identity & Dietary",
      subtitle: "Name, FSSAI food classification & short description",
      icon: Icons.local_dining_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLabel("Product Name", required: true),
              Text("${_name.length}/60", style: const TextStyle(fontSize: 12, color: AppColors.grey500)),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: _name,
            maxLength: 60,
            buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
            decoration: _premiumInputDecoration("Grandma Mango Pickle"),
            onSaved: (val) => _name = val?.trim() ?? '',
            validator: (val) => val == null || val.trim().length < 3 ? 'Name must be at least 3 characters' : null,
            onChanged: (val) => setState(() => _name = val),
          ),
          const SizedBox(height: 20),

          _buildLabel("FSSAI Dietary Classification", required: true),
          const SizedBox(height: 4),
          const Text(
            "Required by FSSAI food safety regulations. Clear labeling builds customer trust and avoids allergen disputes.",
            style: TextStyle(color: AppColors.grey500, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: 78,
            ),
            itemCount: options.length,
            itemBuilder: (context, index) {
              final opt = options[index];
              final isSelected = _dietaryType == opt['title'];
              final color = opt['color'] as Color;

              return GestureDetector(
                onTap: () => setState(() => _dietaryType = opt['title'] as String),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withOpacity(0.08) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSelected ? color : Colors.grey.shade300, width: isSelected ? 2 : 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 26, height: 26,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected ? color.withOpacity(0.15) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(opt['icon'] as String, style: const TextStyle(fontSize: 13)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              opt['title'] as String,
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isSelected ? color : AppColors.textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              opt['sub'] as String,
                              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.check_circle, color: color, size: 16),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLabel("Short Description", required: true),
              Text("${_shortDescription.length}/120", style: const TextStyle(fontSize: 12, color: AppColors.grey500)),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: _shortDescription,
            maxLength: 120,
            maxLines: 2,
            buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
            decoration: _premiumInputDecoration("Traditional Andhra style homemade..."),
            onSaved: (val) => _shortDescription = val?.trim() ?? '',
            validator: (val) => val == null || val.trim().length < 10 ? 'Description must be at least 10 characters' : null,
            onChanged: (val) => setState(() => _shortDescription = val),
          ),
        ],
      ),
    );
  }

  Widget _buildPacksSection() {
    return _buildStepCard(
      title: "3. Pack Sizes & Pricing Studio",
      subtitle: "Configure variants, selling prices & inventory",
      icon: Icons.inventory_2_outlined,
      trailingWidget: GestureDetector(
        onTap: () => _openAddPackSheet(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(20)),
          child: const Row(
            children: [
              Icon(Icons.add, size: 14, color: AppColors.primary),
              SizedBox(width: 4),
              Text("Add Pack", style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
            ]
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_packSizes.isEmpty)
            const Text("Please add at least one pack size.", style: TextStyle(color: Colors.red, fontSize: 13)),
            
          Column(
            children: _packSizes.asMap().entries.map((entry) {
              int index = entry.key;
              ProductVariantModel pack = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(pack.label, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                            if (pack.discountPrice > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: Text(
                                  "-${(((pack.price - pack.discountPrice) / pack.price) * 100).toInt()}%", 
                                  style: const TextStyle(color: Color(0xFF15803D), fontWeight: FontWeight.bold, fontSize: 11)
                                ),
                              ),
                            ],
                          ],
                        ),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => _openAddPackSheet(pack: pack, editIndex: index),
                              child: const Icon(Icons.edit_outlined, color: AppColors.grey500, size: 20),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () {
                                if (_packSizes.length <= 1) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('⚠️ You must maintain at least 1 variant / pack size. Add another size before deleting this one.'),
                                      backgroundColor: Color(0xFFD97706),
                                      duration: Duration(seconds: 3),
                                    ),
                                  );
                                  return;
                                }
                                setState(() => _packSizes.removeAt(index));
                              },
                              child: Icon(
                                Icons.delete_outline,
                                color: _packSizes.length <= 1 ? const Color(0xFFCBD5E1) : Colors.redAccent,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(height: 1, color: Color(0xFFE5E7EB)),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Selling Price", style: TextStyle(color: AppColors.grey500, fontSize: 12)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text("₹${pack.discountPrice > 0 ? pack.discountPrice.toInt() : pack.price.toInt()}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  if (pack.discountPrice > 0) ...[
                                    const SizedBox(width: 6),
                                    Text("₹${pack.price.toInt()}", style: const TextStyle(color: AppColors.grey400, fontSize: 12, decoration: TextDecoration.lineThrough)),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 30, color: const Color(0xFFE5E7EB)),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Inventory", style: TextStyle(color: AppColors.grey500, fontSize: 12)),
                                const SizedBox(height: 4),
                                Text((pack.manageStock || pack.stock > 0) ? "${pack.stock} in stock" : "Unlimited", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (pack.lengthCm > 0 || pack.weightGrams > 0) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          children: [
                            const Icon(Icons.local_shipping_outlined, size: 16, color: AppColors.grey600),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                pack.lengthCm > 0
                                    ? "Weight: ${pack.weightGrams}g  |  Size: ${pack.lengthCm}x${pack.widthCm}x${pack.heightCm} cm"
                                    : "Weight: ${pack.weightGrams}g",
                                style: const TextStyle(color: AppColors.grey600, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(8)),
            child: const Row(
              children: [
                Icon(Icons.lightbulb_outline, color: AppColors.grey500, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text("Tip: Add more pack sizes to increase your sales.", style: TextStyle(color: AppColors.grey500, fontSize: 12)),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  void _openAddPackSheet({ProductVariantModel? pack, int? editIndex}) {
    String parsedQty = '';
    String parsedUnit = 'g';
    if (pack != null) {
      if (pack.unit.isNotEmpty) {
        parsedUnit = pack.unit;
        parsedQty = pack.label.replaceAll(pack.unit, '').trim();
      } else if (pack.label.endsWith(' pcs')) { parsedUnit = 'pcs'; parsedQty = pack.label.replaceAll(' pcs', ''); }
      else if (pack.label.endsWith(' pack')) { parsedUnit = 'pack'; parsedQty = pack.label.replaceAll(' pack', ''); }
      else if (pack.label.endsWith('kg')) { parsedUnit = 'kg'; parsedQty = pack.label.replaceAll('kg', ''); }
      else if (pack.label.endsWith('ml')) { parsedUnit = 'ml'; parsedQty = pack.label.replaceAll('ml', ''); }
      else if (pack.label.endsWith('L')) { parsedUnit = 'L'; parsedQty = pack.label.replaceAll('L', ''); }
      else if (pack.label.endsWith('g')) { parsedUnit = 'g'; parsedQty = pack.label.replaceAll('g', ''); }
    }

    String unitType = pack?.unitType.isNotEmpty == true ? pack!.unitType : 'weight';
    bool isDefault = pack?.isDefault ?? (_packSizes.isEmpty);

    final qtyCtrl = TextEditingController(text: parsedQty);
    String selectedUnit = parsedUnit;
    final priceCtrl = TextEditingController(text: pack?.price.toInt().toString() ?? '');
    final discountCtrl = TextEditingController(text: pack != null && pack.discountPrice > 0 ? pack.discountPrice.toInt().toString() : '');
    
    // Inventory
    bool manageStock = pack?.manageStock ?? false;
    final stockCtrl = TextEditingController(text: manageStock ? pack!.stock.toString() : '');
    
    // Logistics (Shiprocket)
    final weightCtrl = TextEditingController(text: pack?.weightGrams.toString() ?? '');
    final lengthCtrl = TextEditingController(text: pack?.lengthCm.toInt().toString() ?? '');
    final widthCtrl = TextEditingController(text: pack?.widthCm.toInt().toString() ?? '');
    final heightCtrl = TextEditingController(text: pack?.heightCm.toInt().toString() ?? '');

    String? qtyError;
    String? priceError;
    String? discountError;
    String? stockError;
    String? weightError;
    String? dimError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          double? pVal = double.tryParse(priceCtrl.text);
          double? dVal = double.tryParse(discountCtrl.text);
          int? discountPercentage;
          double? savingAmount;
          if (pVal != null && pVal > 0 && dVal != null && dVal > 0 && dVal < pVal) {
            discountPercentage = (((pVal - dVal) / pVal) * 100).round();
            savingAmount = pVal - dVal;
          }

          List<String> availableUnits = ['g', 'kg'];
          List<String> quickChips = ['250g', '500g', '1kg'];
          if (unitType == 'volume') {
            availableUnits = ['ml', 'L'];
            quickChips = ['250ml', '500ml', '1L'];
          } else if (unitType == 'pack') {
            availableUnits = ['pcs', 'pack'];
            quickChips = ['1 pack', '6 pcs', '12 pcs'];
          } else if (unitType == 'custom') {
            availableUnits = ['g', 'kg', 'ml', 'L', 'pcs', 'pack', 'unit'];
            quickChips = [];
          }
          if (!availableUnits.contains(selectedUnit) && availableUnits.isNotEmpty) {
            selectedUnit = availableUnits.first;
          }

          return Container(
            height: MediaQuery.of(context).size.height * 0.88,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 24, bottom: 16),
                  child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Align(alignment: Alignment.centerLeft, child: Text("Add New Pack Size", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24, left: 24, right: 24, top: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel("Unit Category", required: true),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            for (final type in [
                              {'id': 'weight', 'label': '⚖️ Weight'},
                              {'id': 'volume', 'label': '🥛 Volume'},
                              {'id': 'pack', 'label': '📦 Pack'},
                              {'id': 'custom', 'label': '✏️ Custom'},
                            ])
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setSheetState(() => unitType = type['id']!),
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 6),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: unitType == type['id'] ? AppColors.primary : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      type['label']!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: unitType == type['id'] ? Colors.white : AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        if (quickChips.isNotEmpty) ...[
                          const Text("Quick Select", style: TextStyle(fontSize: 12, color: AppColors.grey500, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: quickChips.map((chip) {
                              return ActionChip(
                                label: Text(chip, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                backgroundColor: const Color(0xFFF1F8E9),
                                side: const BorderSide(color: Color(0xFF81C784)),
                                onPressed: () {
                                  setSheetState(() {
                                    final numPart = chip.replaceAll(RegExp(r'[^0-9.]'), '');
                                    final unitPart = chip.replaceAll(RegExp(r'[0-9. ]'), '');
                                    qtyCtrl.text = numPart;
                                    if (availableUnits.contains(unitPart)) {
                                      selectedUnit = unitPart;
                                    }
                                    if (weightCtrl.text.isEmpty && selectedUnit == 'g') {
                                      weightCtrl.text = numPart;
                                    } else if (weightCtrl.text.isEmpty && selectedUnit == 'kg') {
                                      weightCtrl.text = ((double.tryParse(numPart) ?? 1) * 1000).toInt().toString();
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 12),
                        ],

                        _buildLabel("Pack Size Quantity & Unit", required: true),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: qtyCtrl,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))],
                                decoration: _premiumInputDecoration("e.g., 250, 1, 6").copyWith(errorText: qtyError),
                                onChanged: (_) => setSheetState(() => qtyError = null),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 1,
                              child: DropdownButtonFormField<String>(
                                value: selectedUnit,
                                decoration: _premiumInputDecoration(""),
                                items: availableUnits
                                    .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontWeight: FontWeight.w500))))
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) setSheetState(() => selectedUnit = val);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel("Price (₹)", required: true),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: priceCtrl,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                                    decoration: _premiumInputDecoration("0").copyWith(errorText: priceError),
                                    onChanged: (_) => setSheetState(() => priceError = null),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel("Discount Price (₹)"),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: discountCtrl,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                                    decoration: _premiumInputDecoration("Optional").copyWith(errorText: discountError),
                                    onChanged: (_) => setSheetState(() => discountError = null),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        if (discountPercentage != null && savingAmount != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.local_offer_outlined, color: Color(0xFF64748B), size: 14),
                                const SizedBox(width: 8),
                                Text(
                                  "$discountPercentage% OFF  •  Customer saves ₹${savingAmount.toStringAsFixed(0)}",
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF334155)),
                                ),
                              ],
                            ),
                          ),
                        ],
                        
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Divider(),
                        ),
                        
                        // Inventory Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Track Inventory", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            Switch(
                              value: manageStock,
                              activeColor: AppColors.primary,
                              onChanged: (val) => setSheetState(() => manageStock = val),
                            ),
                          ],
                        ),
                        const Text("If disabled, customers can buy unlimited quantities.", style: TextStyle(color: Colors.grey, fontSize: 13)),
                        
                        if (manageStock) ...[
                          const SizedBox(height: 16),
                          _buildLabel("Stock Quantity", required: true),
                          const SizedBox(height: 8),
                          TextField(
                            controller: stockCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: _premiumInputDecoration("e.g. 50").copyWith(errorText: stockError),
                            onChanged: (_) => setSheetState(() => stockError = null),
                          ),
                        ],
                        
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Divider(),
                        ),
                        
                        // Logistics (Shiprocket) Section
                        const Text("Optional Logistics (for future Courier delivery)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        const Text("Not needed for local Self-Delivery. Only fill if using automated courier shipping.", style: TextStyle(color: Colors.grey, fontSize: 13)),
                        const SizedBox(height: 16),
                        
                        _buildLabel("Actual Weight (grams)", required: false),
                        const SizedBox(height: 8),
                        TextField(
                          controller: weightCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: _premiumInputDecoration("e.g. 250").copyWith(errorText: weightError),
                          onChanged: (_) => setSheetState(() => weightError = null),
                        ),
                        
                        const SizedBox(height: 16),
                        _buildLabel("Box Dimensions (cm)", required: false),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextField(
                                controller: lengthCtrl,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: _premiumInputDecoration("L").copyWith(errorText: dimError),
                                onChanged: (_) => setSheetState(() => dimError = null),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: widthCtrl,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: _premiumInputDecoration("W").copyWith(errorText: dimError),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: heightCtrl,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: _premiumInputDecoration("H").copyWith(errorText: dimError),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: () {
                            bool isValid = true;
                            setSheetState(() {
                              if (qtyCtrl.text.isEmpty) {
                                qtyError = "Required";
                                isValid = false;
                              }
                              
                              double? price = double.tryParse(priceCtrl.text);
                              if (price == null || price <= 0) {
                                priceError = "Invalid price";
                                isValid = false;
                              }

                              double? discount = double.tryParse(discountCtrl.text);
                              if (discountCtrl.text.isNotEmpty) {
                                if (discount == null || discount <= 0) {
                                  discountError = "Invalid";
                                  isValid = false;
                                } else if (price != null && discount >= price) {
                                  discountError = "Must be < price";
                                  isValid = false;
                                }
                              }

                              if (manageStock) {
                                if (stockCtrl.text.isEmpty || int.tryParse(stockCtrl.text) == null) {
                                  stockError = "Required for tracking";
                                  isValid = false;
                                }
                              }
                            });

                            if (!isValid) return;
                            
                            String formattedLabel = qtyCtrl.text.trim();
                            if (selectedUnit == 'pcs' || selectedUnit == 'pack' || selectedUnit == 'unit') {
                              formattedLabel += ' $selectedUnit';
                            } else {
                              formattedLabel += selectedUnit;
                            }

                            setState(() {
                              final newPack = ProductVariantModel(
                                variantId: pack?.variantId ?? const Uuid().v4(),
                                label: formattedLabel,
                                price: double.parse(priceCtrl.text),
                                discountPrice: double.tryParse(discountCtrl.text) ?? 0,
                                stock: int.tryParse(stockCtrl.text) ?? 0,
                                isAvailable: manageStock ? ((int.tryParse(stockCtrl.text) ?? 0) > 0) : true,
                                manageStock: manageStock,
                                weightGrams: int.tryParse(weightCtrl.text) ?? 0,
                                lengthCm: double.tryParse(lengthCtrl.text) ?? 0,
                                widthCm: double.tryParse(widthCtrl.text) ?? 0,
                                heightCm: double.tryParse(heightCtrl.text) ?? 0,
                                unitType: unitType,
                                unit: selectedUnit,
                                isDefault: isDefault,
                              );

                              if (isDefault) {
                                for (int i = 0; i < _packSizes.length; i++) {
                                  _packSizes[i] = _packSizes[i].copyWith(isDefault: false);
                                }
                              }

                              if (editIndex != null) {
                                _packSizes[editIndex] = newPack;
                              } else {
                                _packSizes.add(newPack);
                              }
                            });
                            context.pop();
                          },
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 56),
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text("Save Pack Size", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildFreshnessAndHandlingSection() {
    return _buildStepCard(
      title: "4. Freshness & Handling Specifications",
      subtitle: "Shelf life, preparation timelines & ingredients",
      icon: Icons.timer_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel("Shelf Life", required: true),
          const SizedBox(height: 2),
          const Text("How long the product stays fresh from the day it is prepared.", style: TextStyle(color: AppColors.grey500, fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: TextFormField(
                  initialValue: _shelfLifeQty,
                  keyboardType: TextInputType.number,
                  decoration: _premiumInputDecoration("e.g. 3").copyWith(contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16)),
                  onChanged: (val) => _shelfLifeQty = val,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: DropdownButtonFormField<String>(
                  value: _shelfLifeUnit,
                  decoration: _premiumInputDecoration("").copyWith(contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16)),
                  isExpanded: true,
                  items: ['Days', 'Weeks', 'Months', 'Years'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontWeight: FontWeight.w500)))).toList(),
                  onChanged: (val) => setState(() => _shelfLifeUnit = val ?? 'Months'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          _buildLabel("Dispatch Time", required: true),
          const SizedBox(height: 2),
          const Text("Time taken to prepare and handover to delivery partner.", style: TextStyle(color: AppColors.grey500, fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: TextFormField(
                  initialValue: _dispatchTimeQty,
                  keyboardType: TextInputType.number,
                  decoration: _premiumInputDecoration("e.g. 2").copyWith(contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16)),
                  onChanged: (val) => _dispatchTimeQty = val,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: DropdownButtonFormField<String>(
                  value: _dispatchTimeUnit,
                  decoration: _premiumInputDecoration("").copyWith(contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16)),
                  isExpanded: true,
                  items: ['Hours', 'Days', 'Weeks'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontWeight: FontWeight.w500)))).toList(),
                  onChanged: (val) => setState(() => _dispatchTimeUnit = val ?? 'Days'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          _buildLabel("Ingredients (Optional)"),
          const SizedBox(height: 8),
          TextFormField(
            controller: _ingredientCtrl,
            decoration: _premiumInputDecoration("e.g., Raw Mango, Mustard Seeds").copyWith(
              suffixIcon: IconButton(
                icon: const Icon(Icons.add_circle, color: AppColors.primary),
                onPressed: () {
                  if (_ingredientCtrl.text.isNotEmpty) {
                    setState(() => _ingredients.add(_ingredientCtrl.text.trim()));
                    _ingredientCtrl.clear();
                  }
                },
              ),
            ),
            onFieldSubmitted: (val) {
              if (val.trim().isNotEmpty) {
                setState(() => _ingredients.add(val.trim()));
                _ingredientCtrl.clear();
              }
            },
          ),
          if (_ingredients.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _ingredients.map((item) => Chip(
                label: Text(item, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () => setState(() => _ingredients.remove(item)),
                backgroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFFE5E7EB)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
              )).toList(),
            ),
          ],

          const SizedBox(height: 20),
          _buildLabel("Storage Instructions (Optional)"),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: _storageInstructions,
            maxLines: 2,
            decoration: _premiumInputDecoration("Keep in a cool and dry place. Use clean spoon."),
            onChanged: (val) => _storageInstructions = val,
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewSection() {
    final provider = context.read<ProductProvider>();
    return _buildStepCard(
      title: "5. Customer App Preview",
      subtitle: "Tap card to see full interactive experience",
      icon: Icons.smartphone_outlined,
      child: GestureDetector(
        onTap: _openFullScreenPreview,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 80, height: 80,
                      child: provider.selectedImages.isNotEmpty 
                        ? Image.file(provider.selectedImages.first, fit: BoxFit.cover)
                        : Container(color: AppColors.grey200, child: const Icon(Icons.image_outlined, color: AppColors.grey400)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_name.isEmpty ? "Product Name" : _name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Text("FreshGa Homemade", style: TextStyle(color: AppColors.grey600, fontSize: 12)),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                              child: const Icon(Icons.check, color: Colors.white, size: 8),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              "₹${_packSizes.isNotEmpty ? (_packSizes.first.discountPrice > 0 ? _packSizes.first.discountPrice.toInt() : _packSizes.first.price.toInt()) : '0'}",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary),
                            ),
                            if (_packSizes.isNotEmpty && _packSizes.first.discountPrice > 0) ...[
                              const SizedBox(width: 8),
                              Text(
                                "₹${_packSizes.first.price.toInt()}",
                                style: const TextStyle(color: AppColors.grey400, fontSize: 13, decoration: TextDecoration.lineThrough),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_packSizes.isNotEmpty)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _packSizes.asMap().entries.map((entry) {
                      bool isFirst = entry.key == 0;
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isFirst ? const Color(0xFFF1F8E9) : Colors.white,
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: isFirst ? AppColors.primary : AppColors.grey200),
                        ),
                        child: Text("${entry.value.label} ₹${entry.value.price.toInt()}", style: TextStyle(color: isFirst ? AppColors.primary : AppColors.textPrimary, fontWeight: isFirst ? FontWeight.bold : FontWeight.w500, fontSize: 12)),
                      );
                    }).toList(),
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }

  void _openFullScreenPreview() {
    final provider = context.read<ProductProvider>();
    Navigator.push(context, MaterialPageRoute(builder: (_) => ChangeNotifierProvider.value(
      value: provider,
      child: VendorProductPreview(
        name: _name.isEmpty ? "Product Name" : _name,
        shortDescription: _shortDescription.isEmpty ? "Product short description..." : _shortDescription,
        description: _shortDescription, 
        price: _packSizes.isNotEmpty ? _packSizes.first.price : 0,
        originalPrice: _packSizes.isNotEmpty ? _packSizes.first.discountPrice > 0 ? _packSizes.first.price : 0 : 0,
        weight: '', 
        shelfLife: _shelfLife,
        dispatchTime: _dispatchTime, 
        variants: _packSizes,
        ingredients: _ingredients,
        tags: _subCategoryIds, 
        images: provider.selectedImages,
      ),
    )));
  }

  void _showExitConfirmationSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 24),
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF3F2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.bookmark_border_rounded, color: Color(0xFFDC2626), size: 26),
              ),
              const SizedBox(height: 16),
              const Text(
                'Save as Draft?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  "If you discard now, you'll lose any changes you've made to this product.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF64748B),
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              if (_currentPage == 2) ...[
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    _handleSubmission('Draft');
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    alignment: Alignment.center,
                    child: Text(
                      (widget.product != null && widget.product!.status == 'Draft') ? 'Update Draft' : 'Save Draft',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ],
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  context.pop();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  alignment: Alignment.center,
                  child: const Text(
                    'Discard',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                ),
              ),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              InkWell(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  alignment: Alignment.center,
                  child: const Text(
                    'Keep Editing',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _showSubmitConfirmationDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 24),
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.verified_outlined, color: Color(0xFF16A34A), size: 30),
              ),
              const SizedBox(height: 16),
              Text(
                widget.product?.status == 'Changes Required' ? 'Resubmit for Review?' : 'Submit for Review?',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  "Your product will be reviewed by our admin team within 24 hours before going live on the customer app.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: Color(0xFF475569),
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _handleSubmission('Under Review');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text(
                          'Submit Now',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // --- SUBMISSION LOGIC ---

  void _handleSubmission(String targetStatus) async {
    if (widget.product?.status == 'Changes Required') {
      final doc = await FirebaseFirestore.instance.collection('products').doc(widget.product!.productId).get();
      final currentFixes = doc.exists ? List<String>.from(doc.data()!['requiredFixes'] ?? []) : widget.product!.requiredFixes;
      if (currentFixes.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please address all required changes before resubmitting. Remaining: ${currentFixes.join(", ")}'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }
    // Validate current page if we are on details
    if (_currentPage == 2 && _formDetails.currentState != null) {
      if (!_formDetails.currentState!.validate()) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields in Product Details')));
        return;
      }
      _formDetails.currentState!.save();
    }
    
    // Quick checks
    if (_categoryId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a category')));
      return;
    }
    if (_name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product name is required')));
      return;
    }
    if (_packSizes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add at least one pack size & pricing')));
      return;
    }
    if (_shelfLife.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter Shelf Life (e.g. 3 Months)')));
      return;
    }
    if (_dispatchTime.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter Dispatch Time (e.g. 24 Hours)')));
      return;
    }

    final provider = context.read<ProductProvider>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );
    
    final productModel = ProductModel(
      productId: widget.product?.productId ?? '',
      storeId: widget.product?.storeId ?? '',
      storeName: widget.product?.storeName ?? '',
      name: _name,
      slug: _name.toLowerCase().replaceAll(' ', '-'),
      description: _shortDescription, // Can expand later
      shortDescription: _shortDescription,
      categoryId: _categoryId,
      categoryName: _categoryName,
      subCategoryIds: _subCategoryIds,
      price: _packSizes.isNotEmpty ? _packSizes.first.price : 0,
      originalPrice: _packSizes.isNotEmpty ? _packSizes.first.discountPrice > 0 ? _packSizes.first.price : 0 : 0,
      weight: '',
      shelfLife: _shelfLife,
      dispatchTime: _dispatchTime,
      storageInstructions: _storageInstructions,
      showStockToCustomers: _showStock,
      status: targetStatus,
      adminFeedback: targetStatus == 'Under Review' ? '' : (widget.product?.adminFeedback ?? ''),
      isStoreVerified: widget.product?.isStoreVerified ?? false,
      images: widget.product?.images ?? [],
      variants: _packSizes,
      ingredients: _ingredients,
      tags: [_dietaryType],
      rating: widget.product?.rating ?? 0.0,
      totalReviews: widget.product?.totalReviews ?? 0,
      totalOrders: widget.product?.totalOrders ?? 0,
      likes: widget.product?.likes ?? 0,
      wishlistCount: widget.product?.wishlistCount ?? 0,
      isFeatured: widget.product?.isFeatured ?? false,
      isTrending: widget.product?.isTrending ?? false,
      isActive: targetStatus == 'Live',
      searchKeywords: _name.toLowerCase().split(' '),
      createdAt: widget.product?.createdAt ?? DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
    );

    ProductModel? finalProduct;
    if (widget.product != null) {
      bool updated = await provider.updateFullProduct(productModel);
      if (updated) finalProduct = productModel;
    } else {
      finalProduct = await provider.addProduct(productModel);
    }

    if (!mounted) return;
    context.pop(); // Close dialog

    if (finalProduct != null) {
      if (targetStatus == 'Under Review') {
        _showSuccessScreen(finalProduct);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved as draft', style: TextStyle(color: Colors.white)), backgroundColor: Color(0xFF4CAF50)));
        context.pop(); // Go back to products list
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage ?? 'Failed to save product'), backgroundColor: AppColors.error));
    }
  }

  void _showSuccessScreen(ProductModel finalProduct) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog.fullscreen(
        child: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 40),
                            
                            // Premium Success Icon
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 64,
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 32),
                            const Text(
                              "Product Submitted", 
                              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              "Your product has been sent for review.", 
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.green),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "FreshGa reviews products before making them visible to customers to ensure quality. Usually completed within 24 hours.", 
                              textAlign: TextAlign.center, 
                              style: TextStyle(color: Colors.grey.shade600, height: 1.5, fontSize: 14),
                            ),
                            
                            const SizedBox(height: 40),
                            
                            // Progress Timeline
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade100),
                              ),
                              child: Column(
                                children: [
                                  _buildTimelineItem(Icons.check_circle, "Product Created", Colors.green),
                                  _buildTimelineItem(Icons.check_circle, "Submitted", Colors.green),
                                  _buildTimelineItem(Icons.hourglass_empty, "Under Review", Colors.orange, isLast: true),
                                ],
                              ),
                            ),
                            
                            const Spacer(),
                            const SizedBox(height: 40),
                            
                            OutlinedButton(
                              onPressed: () {
                                Navigator.of(ctx).pop(); // dismiss success screen dialog
                                context.pushReplacement('/under-review-details', extra: finalProduct);
                              },
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 56),
                                foregroundColor: Colors.black87,
                                side: BorderSide(color: Colors.grey.shade300),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: const Text("View Product Status", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(ctx).pop(); // dismiss success screen dialog
                                context.pop(); // pop AddProductScreen back to products list
                              },
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 56),
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: const Text("Back To Products", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineItem(IconData icon, String text, Color color, {bool isLast = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Icon(icon, color: color, size: 24),
            if (!isLast)
              Container(width: 2, height: 32, color: color.withOpacity(0.5)),
          ],
        ),
        const SizedBox(width: 16),
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(text, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color == AppColors.primary ? AppColors.textPrimary : AppColors.grey500)),
        ),
      ],
    );
  }
}
