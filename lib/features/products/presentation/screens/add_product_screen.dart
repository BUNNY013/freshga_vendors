import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/product_model.dart';
import '../../../../data/models/product_variant_model.dart';
import '../providers/product_provider.dart';
import '../widgets/vendor_product_preview.dart';

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
  bool _showStock = true;

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
    _ingredientCtrl.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage == 0) {
      if (_categoryId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a category')));
        return;
      }
    } else if (_currentPage == 1) {
      if (_subCategoryIds.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one sub category')));
        return;
      }
    } else if (_currentPage == 2) {
      // Final submission validation
      if (!_formDetails.currentState!.validate()) return;
      _formDetails.currentState!.save();
      
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
      context.pop();
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
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAFB),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20),
          onPressed: _prevPage,
        ),
        title: const Text('Add Product', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F8E9),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              'Step ${_currentPage + 1} of $_totalPages',
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          )
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
    if (_currentPage == 2) {
      return Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFF1F8E9), borderRadius: BorderRadius.circular(12)),
              child: const Row(
                children: [
                  Icon(Icons.verified_user_outlined, color: AppColors.primary, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Ready to publish?", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 14)),
                        Text("Your product will be reviewed within 24 hours.", style: TextStyle(color: AppColors.grey600, fontSize: 12)),
                      ],
                    )
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleSubmission('Draft'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Save as Draft", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: ElevatedButton(
                    onPressed: () => _handleSubmission('Under Review'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      widget.product?.status == 'Changes Required' ? "Resubmit" : "Submit for Review", 
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                    ),
                  ),
                ),
              ],
            )
          ],
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
        onPressed: (_currentPage == 0 && _categoryId.isEmpty) || (_currentPage == 1 && _subCategoryIds.isEmpty) ? null : _nextPage,
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
                            Column(
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
              Text("Selected: $_categoryName", style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              const Text("Where should customers find this product?", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.textPrimary, height: 1.2)),
              const SizedBox(height: 8),
              const Text("Select one or more collections", style: TextStyle(fontSize: 16, color: AppColors.grey600)),
              const SizedBox(height: 32),
              
              if (subCategories.isEmpty)
                const Text("No sub categories available for this category.", style: TextStyle(color: AppColors.grey500))
              else
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: subCategories.map((sub) {
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
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primaryLight.withOpacity(0.5) : Colors.white,
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: isSelected ? AppColors.primary : AppColors.grey300, width: isSelected ? 2 : 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected) ...[
                              const Icon(Icons.check_circle, color: AppColors.primary, size: 18),
                              const SizedBox(width: 8),
                            ],
                            if (sub.imageUrl.isNotEmpty && !isSelected) ...[
                              CachedNetworkImage(
                                imageUrl: sub.imageUrl,
                                width: 20, height: 20,
                                errorWidget: (c, u, e) => const Icon(Icons.category, size: 20),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Text(sub.name, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, color: isSelected ? AppColors.primary : AppColors.textPrimary)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
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
      }
    );
  }

  // --- STEP 3: SINGLE SCROLL PRODUCT DETAILS ---

  Widget _buildStep3ProductDetails() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Form(
        key: _formDetails,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPhotosSection(),
            const SizedBox(height: 32),

            _buildInfoSection(),
            const SizedBox(height: 32),

            _buildPacksSection(),
            const SizedBox(height: 32),

            _buildOptionalSection(),
            const SizedBox(height: 32),

            _buildPreviewSection(),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {String? trailing, Widget? trailingWidget}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          if (trailingWidget != null) trailingWidget
          else if (trailing != null) Text(trailing, style: const TextStyle(fontSize: 13, color: AppColors.grey500, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // --- SECTIONS FOR STEP 3 ---

  Widget _buildPhotosSection() {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader("Product Photos", trailingWidget: Row(
              children: [
                const Text("(Max 10 photos)", style: TextStyle(fontSize: 13, color: AppColors.grey500)),
                const SizedBox(width: 8),
                Text("${provider.selectedImages.length}/10", style: const TextStyle(fontSize: 13, color: AppColors.grey500, fontWeight: FontWeight.bold)),
              ]
            )),
            
            if (provider.selectedImages.isNotEmpty)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 200,
                      child: Image.file(provider.selectedImages.first, fit: BoxFit.cover),
                    ),
                  ),
                  Positioned(
                    top: 12, right: 12,
                    child: GestureDetector(
                      onTap: () => provider.removeImage(0),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.close, color: Colors.black, size: 20),
                      ),
                    ),
                  )
                ]
              )
            else
              GestureDetector(
                onTap: provider.pickImages,
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.grey200),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined, color: AppColors.primary, size: 40),
                        SizedBox(height: 8),
                        Text("Add Cover Photo", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      ],
                    ),
                  ),
                ),
              ),
              
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (int i = 1; i < provider.selectedImages.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              width: 70, height: 70,
                              child: Image.file(provider.selectedImages[i], fit: BoxFit.cover),
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
          ],
        );
      }
    );
  }

  Widget _buildInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("Product Information"),
        
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
        const SizedBox(height: 16),

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
    );
  }

  Widget _buildPacksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("Pack Sizes & Prices", trailingWidget: GestureDetector(
          onTap: _openAddPackSheet,
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
        )),
        
        if (_packSizes.isEmpty)
          const Text("Please add at least one pack size.", style: TextStyle(color: Colors.red, fontSize: 13)),
          
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _packSizes.asMap().entries.map((entry) {
              int index = entry.key;
              ProductVariantModel pack = entry.value;
              return Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: const Color(0xFFE5E7EB))),
                      child: GestureDetector(
                        onTap: () => setState(() => _packSizes.removeAt(index)),
                        child: const Icon(Icons.delete_outline, color: AppColors.grey500, size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(pack.label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text("₹${pack.price.toInt()}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text("Stock: ${pack.stock}", style: const TextStyle(color: AppColors.grey500, fontSize: 12)),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {}, // Future Edit feature
                          child: const Icon(Icons.edit_outlined, color: AppColors.grey400, size: 16),
                        )
                      ],
                    )
                  ],
                ),
              );
            }).toList(),
          ),
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
              Text("Tip: Add more pack sizes to increase your sales.", style: TextStyle(color: AppColors.grey500, fontSize: 12)),
            ],
          ),
        )
      ],
    );
  }

  void _openAddPackSheet() {
    final qtyCtrl = TextEditingController();
    String selectedUnit = 'g';
    final priceCtrl = TextEditingController();
    final discountCtrl = TextEditingController();
    final stockCtrl = TextEditingController();

    String? qtyError;
    String? priceError;
    String? discountError;
    String? stockError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Add New Pack Size", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                _buildLabel("Pack Size", required: true),
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
                        items: ['g', 'kg', 'ml', 'L', 'pcs', 'pack']
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
                const SizedBox(height: 16),
                _buildLabel("Stock Quantity"),
                const SizedBox(height: 8),
                TextField(
                  controller: stockCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: _premiumInputDecoration("e.g. 50 (Optional)").copyWith(errorText: stockError),
                  onChanged: (_) => setSheetState(() => stockError = null),
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

                      if (stockCtrl.text.isNotEmpty && int.tryParse(stockCtrl.text) == null) {
                        stockError = "Invalid";
                        isValid = false;
                      }
                    });

                    if (!isValid) return;
                    
                    String formattedLabel = qtyCtrl.text.trim();
                    if (selectedUnit == 'pcs' || selectedUnit == 'pack') {
                      formattedLabel += ' $selectedUnit';
                    } else {
                      formattedLabel += selectedUnit;
                    }

                    setState(() {
                      _packSizes.add(ProductVariantModel(
                        variantId: const Uuid().v4(),
                        label: formattedLabel,
                        price: double.parse(priceCtrl.text),
                        discountPrice: double.tryParse(discountCtrl.text) ?? 0,
                        stock: int.tryParse(stockCtrl.text) ?? 0,
                        isAvailable: true,
                      ));
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
                const SizedBox(height: 32),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildOptionalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel("Ingredients"),
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
        
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel("Dispatch Time"),
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
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel("Shelf Life"),
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
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),
        _buildLabel("Storage Instructions"),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: _storageInstructions,
          maxLines: 2,
          decoration: _premiumInputDecoration("Keep in a cool and dry place. Use clean spoon."),
          onChanged: (val) => _storageInstructions = val,
        ),
        
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE5E7EB)), borderRadius: BorderRadius.circular(12)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Show stock count to customers", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 14)),
                  SizedBox(height: 2),
                  Text("Increases transparency and urgency", style: TextStyle(fontSize: 12, color: AppColors.grey500)),
                ],
              ),
              Switch(
                value: _showStock,
                onChanged: (val) => setState(() => _showStock = val),
                activeColor: Colors.white,
                activeTrackColor: AppColors.primary,
              )
            ],
          ),
        )
      ],
    );
  }

  Widget _buildPreviewSection() {
    final provider = context.read<ProductProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("Preview", trailing: "(This is how customers will see)"),
        GestureDetector(
          onTap: _openFullScreenPreview,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.grey200),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
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
                              )
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Row(
                            children: [
                              Icon(Icons.star, color: Colors.amber, size: 14),
                              SizedBox(width: 4),
                              Text("4.8 (124)  320+ sold", style: TextStyle(color: AppColors.grey600, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text("From ₹${_packSizes.isNotEmpty ? _packSizes.first.price.toInt() : 0}", style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14)),
                        ],
                      ),
                    )
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
      ],
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

  // --- SUBMISSION LOGIC ---

  void _handleSubmission(String targetStatus) async {
    // Validate current page if we are on details
    if (_currentPage == 2) {
      if (!_formDetails.currentState!.validate()) return;
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
      tags: [],
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

    bool success = false;
    if (widget.product != null) {
      // We don't have an updateProduct yet that accepts ProductModel, we'll need to create it! 
      // But for now provider.addProduct handles replacing since it does .set() if we ensure we use same ID.
      // Actually we'll need provider.updateFullProduct. We will add it next.
      success = await provider.updateFullProduct(productModel);
    } else {
      success = await provider.addProduct(productModel);
    }

    if (!mounted) return;
    context.pop(); // Close dialog

    if (success) {
      if (targetStatus == 'Under Review') {
        _showSuccessScreen();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved as draft', style: TextStyle(color: Colors.white)), backgroundColor: Color(0xFF4CAF50)));
        context.pop(); // Go back to products list
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage ?? 'Failed to save product'), backgroundColor: AppColors.error));
    }
  }

  void _showSuccessScreen() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => Scaffold(
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
                              onPressed: () => context.pop(),
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
                              onPressed: () => context.pop(),
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
