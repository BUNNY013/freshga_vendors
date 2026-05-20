import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../providers/product_provider.dart';
import '../../../../data/models/product_model.dart';
import '../../../../data/models/product_variant_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../widgets/variant_card.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 5;

  final _formKeyBasics = GlobalKey<FormState>();
  final _formKeyIngredients = GlobalKey<FormState>();

  // Basic Info
  String _name = '';
  String _shortDescription = '';
  String _description = '';
  String _categoryId = 'cat_1'; // Hardcoded for now, would be fetched
  String _subCategoryId = 'sub_1'; // Hardcoded for now

  // Variants
  List<ProductVariantModel> _variants = [];

  // Ingredients & Tags
  String _ingredientsText = '';
  String _tagsText = '';

  @override
  void initState() {
    super.initState();
    // Start with one default variant
    _addEmptyVariant();
  }

  void _addEmptyVariant() {
    setState(() {
      _variants.add(
        ProductVariantModel(
          variantId: const Uuid().v4(),
          label: '',
          price: 0,
          discountPrice: 0,
          stock: 0,
          isAvailable: true,
        ),
      );
    });
  }

  void _nextPage() {
    if (_currentPage == 0 && !_formKeyBasics.currentState!.validate()) return;
    if (_currentPage == 0) _formKeyBasics.currentState!.save();
    
    if (_currentPage == 3 && !_formKeyIngredients.currentState!.validate()) return;
    if (_currentPage == 3) _formKeyIngredients.currentState!.save();

    if (_currentPage == 2 && _variants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add at least one variant')));
      return;
    }

    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _submit();
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      context.pop();
    }
  }

  Future<void> _submit() async {
    final provider = context.read<ProductProvider>();
    
    // Convert text to lists
    final ingredients = _ingredientsText.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final tags = _tagsText.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    
    // Slug generation
    final slug = _name.toLowerCase().replaceAll(' ', '-');

    final product = ProductModel(
      productId: '', // assigned in provider
      storeId: '', // assigned in provider
      storeName: '', // assigned in provider
      name: _name,
      slug: slug,
      shortDescription: _shortDescription,
      description: _description,
      categoryId: _categoryId,
      subCategoryId: _subCategoryId,
      images: [], // handled in provider
      variants: _variants,
      ingredients: ingredients,
      tags: tags,
      rating: 0.0,
      totalReviews: 0,
      totalOrders: 0,
      likes: 0,
      wishlistCount: 0,
      isFeatured: false,
      isTrending: false,
      isActive: true,
      searchKeywords: _name.toLowerCase().split(' '),
      createdAt: '',
      updatedAt: '',
    );

    final success = await provider.addProduct(product);
    if (success && mounted) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product published successfully!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Add Product', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Progress Bar
          LinearProgressIndicator(
            value: (_currentPage + 1) / _totalPages,
            backgroundColor: AppColors.grey200,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 4,
          ),
          const SizedBox(height: 16),
          
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (int page) {
                setState(() {
                  _currentPage = page;
                });
              },
              children: [
                _buildBasicsStep(),
                _buildImagesStep(),
                _buildVariantsStep(),
                _buildIngredientsStep(),
                _buildPreviewStep(),
              ],
            ),
          ),
          
          // Bottom Navigation
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                )
              ],
            ),
            child: Row(
              children: [
                if (_currentPage > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _prevPage,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Back'),
                    ),
                  ),
                if (_currentPage > 0) const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Consumer<ProductProvider>(
                    builder: (context, provider, child) {
                      final isLastPage = _currentPage == _totalPages - 1;
                      return ElevatedButton(
                        onPressed: provider.isLoading ? null : _nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: provider.isLoading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(isLastPage ? 'Publish Product' : 'Next Step', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      );
                    }
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKeyBasics,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Product Basics", style: AppTextStyles.h1),
            const SizedBox(height: 8),
            const Text("Tell us about your homemade product.", style: AppTextStyles.bodyText),
            const SizedBox(height: 24),
            
            _buildTextField(
              label: "Product Name",
              hint: "e.g., Spicy Mango Pickle",
              initialValue: _name,
              onSaved: (val) => _name = val ?? '',
              validator: (val) => val == null || val.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: "Short Description",
              hint: "A brief catchy description for the card",
              initialValue: _shortDescription,
              onSaved: (val) => _shortDescription = val ?? '',
              validator: (val) => val == null || val.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: "Full Description",
              hint: "Tell the story behind this product, how it's made, etc.",
              maxLines: 5,
              initialValue: _description,
              onSaved: (val) => _description = val ?? '',
              validator: (val) => val == null || val.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 24),
            
            // For now, static dropdowns for categories
            DropdownButtonFormField<String>(
              value: _categoryId,
              decoration: _inputDecoration("Category"),
              items: const [
                DropdownMenuItem(value: 'cat_1', child: Text("Pickles")),
                DropdownMenuItem(value: 'cat_2', child: Text("Cookies")),
                DropdownMenuItem(value: 'cat_3', child: Text("Sweets")),
              ],
              onChanged: (val) => setState(() => _categoryId = val!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _subCategoryId,
              decoration: _inputDecoration("Sub Category"),
              items: const [
                DropdownMenuItem(value: 'sub_1', child: Text("Mango Pickles")),
                DropdownMenuItem(value: 'sub_2', child: Text("Lemon Pickles")),
                DropdownMenuItem(value: 'sub_3', child: Text("Chocolate Cookies")),
              ],
              onChanged: (val) => setState(() => _subCategoryId = val!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagesStep() {
    return Consumer<ProductProvider>(
      builder: (context, provider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Product Images", style: AppTextStyles.h1),
              const SizedBox(height: 8),
              const Text("Upload appetizing photos of your product.", style: AppTextStyles.bodyText),
              const SizedBox(height: 24),
              
              if (provider.selectedImages.isNotEmpty)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: provider.selectedImages.length + 1,
                  itemBuilder: (context, index) {
                    if (index == provider.selectedImages.length) {
                      return GestureDetector(
                        onTap: provider.pickImages,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.primary.withOpacity(0.5), style: BorderStyle.solid),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo, color: AppColors.primary, size: 32),
                              SizedBox(height: 8),
                              Text("Add More", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      );
                    }
                    
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(
                            provider.selectedImages[index],
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () => provider.removeImage(index),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                              child: const Icon(Icons.close, size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                )
              else
                GestureDetector(
                  onTap: provider.pickImages,
                  child: Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 2, style: BorderStyle.solid),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_upload_outlined, color: AppColors.primary, size: 64),
                        SizedBox(height: 16),
                        Text("Tap to upload photos", style: TextStyle(color: AppColors.primary, fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Text("Supports JPG, PNG", style: TextStyle(color: AppColors.grey600)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVariantsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Product Variants", style: AppTextStyles.h1),
          const SizedBox(height: 8),
          const Text("Add different sizes, packs, or flavors.", style: AppTextStyles.bodyText),
          const SizedBox(height: 24),
          
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _variants.length,
            itemBuilder: (context, index) {
              return VariantCard(
                variant: _variants[index],
                onEdit: () => _editVariantDialog(index),
                onDuplicate: () {
                  setState(() {
                    _variants.add(_variants[index].copyWith(variantId: const Uuid().v4()));
                  });
                },
                onDelete: () {
                  setState(() {
                    _variants.removeAt(index);
                  });
                },
                onAvailabilityToggle: (val) {
                  setState(() {
                    _variants[index] = _variants[index].copyWith(isAvailable: val);
                  });
                },
              );
            },
          ),
          
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                _addEmptyVariant();
                // Optionally scroll to bottom
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Another Variant'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
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

  void _editVariantDialog(int index) {
    final variant = _variants[index];
    
    final labelCtrl = TextEditingController(text: variant.label);
    final priceCtrl = TextEditingController(text: variant.price.toString());
    final discountCtrl = TextEditingController(text: variant.discountPrice.toString());
    final stockCtrl = TextEditingController(text: variant.stock.toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Edit Variant", style: AppTextStyles.h2),
            const SizedBox(height: 24),
            TextField(
              controller: labelCtrl,
              decoration: _inputDecoration("Variant Label (e.g. 250g, Pack of 6)"),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: _inputDecoration("Price (₹)"))),
                const SizedBox(width: 16),
                Expanded(child: TextField(controller: discountCtrl, keyboardType: TextInputType.number, decoration: _inputDecoration("Discount Price"))),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: stockCtrl,
              keyboardType: TextInputType.number,
              decoration: _inputDecoration("Stock Available"),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _variants[index] = variant.copyWith(
                      label: labelCtrl.text,
                      price: double.tryParse(priceCtrl.text) ?? 0,
                      discountPrice: double.tryParse(discountCtrl.text) ?? 0,
                      stock: int.tryParse(stockCtrl.text) ?? 0,
                    );
                  });
                  context.pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Save Variant", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildIngredientsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKeyIngredients,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Ingredients & Tags", style: AppTextStyles.h1),
            const SizedBox(height: 8),
            const Text("Help customers find and understand your product.", style: AppTextStyles.bodyText),
            const SizedBox(height: 24),
            
            _buildTextField(
              label: "Ingredients (Comma separated)",
              hint: "e.g., Raw Mango, Mustard Oil, Spices",
              maxLines: 3,
              initialValue: _ingredientsText,
              onSaved: (val) => _ingredientsText = val ?? '',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: "Tags (Comma separated)",
              hint: "e.g., Spicy, Homemade, No Preservatives",
              maxLines: 3,
              initialValue: _tagsText,
              onSaved: (val) => _tagsText = val ?? '',
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.primary),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Adding tags makes your product show up in search more often!",
                      style: TextStyle(color: AppColors.primary, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Review Your Product", style: AppTextStyles.h1),
          const SizedBox(height: 8),
          const Text("This is a summary of how it will look.", style: AppTextStyles.bodyText),
          const SizedBox(height: 24),
          
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Consumer<ProductProvider>(
                  builder: (context, provider, _) {
                    if (provider.selectedImages.isNotEmpty) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          provider.selectedImages.first,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      );
                    }
                    return Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(color: AppColors.grey200, borderRadius: BorderRadius.circular(16)),
                      child: const Center(child: Icon(Icons.image, size: 64, color: AppColors.grey400)),
                    );
                  }
                ),
                const SizedBox(height: 20),
                Text(_name.isEmpty ? "Product Name" : _name, style: AppTextStyles.h2),
                const SizedBox(height: 8),
                Text(_shortDescription.isEmpty ? "Short Description" : _shortDescription, style: const TextStyle(color: AppColors.grey600)),
                const SizedBox(height: 16),
                
                if (_variants.isNotEmpty) ...[
                  const Text("Available Variants:", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _variants.map((v) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.grey200,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text("${v.label.isEmpty ? 'Variant' : v.label} - ₹${v.price.toStringAsFixed(0)}"),
                    )).toList(),
                  ),
                ]
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          const Center(
            child: Text("Ready to publish? 🚀", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    int maxLines = 1,
    String? initialValue,
    void Function(String?)? onSaved,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      initialValue: initialValue,
      maxLines: maxLines,
      decoration: _inputDecoration(label).copyWith(hintText: hint),
      onSaved: onSaved,
      validator: validator,
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.grey600),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.grey300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.grey300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    );
  }
}
