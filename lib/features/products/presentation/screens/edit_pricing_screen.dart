import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/product_model.dart';
import '../../../../data/models/product_variant_model.dart';
import '../providers/product_provider.dart';

class EditPricingScreen extends StatefulWidget {
  final ProductModel product;

  const EditPricingScreen({super.key, required this.product});

  @override
  State<EditPricingScreen> createState() => _EditPricingScreenState();
}

class _EditPricingScreenState extends State<EditPricingScreen> {
  late ProductModel _product;
  
  // Base pricing controllers
  late TextEditingController _baseWeightCtrl;
  late TextEditingController _basePriceCtrl;
  late TextEditingController _baseOriginalPriceCtrl;

  // Variants state
  List<ProductVariantModel> _variants = [];
  final List<TextEditingController> _variantLabelCtrls = [];
  final List<TextEditingController> _variantPriceCtrls = [];
  final List<TextEditingController> _variantDiscountPriceCtrls = [];

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    
    _baseWeightCtrl = TextEditingController(text: _product.weight);
    _basePriceCtrl = TextEditingController(text: _product.price > 0 ? _product.price.toStringAsFixed(0) : '');
    _baseOriginalPriceCtrl = TextEditingController(text: _product.originalPrice > 0 ? _product.originalPrice.toStringAsFixed(0) : '');

    _variants = List.from(_product.draftVersion?['variants']?.map((e) => ProductVariantModel.fromJson(e as Map<String, dynamic>)) ?? _product.variants);
    for (var v in _variants) {
      _variantLabelCtrls.add(TextEditingController(text: v.label));
      _variantPriceCtrls.add(TextEditingController(text: v.price > 0 ? v.price.toStringAsFixed(0) : ''));
      _variantDiscountPriceCtrls.add(TextEditingController(text: v.discountPrice > 0 ? v.discountPrice.toStringAsFixed(0) : ''));
    }
  }

  @override
  void dispose() {
    _baseWeightCtrl.dispose();
    _basePriceCtrl.dispose();
    _baseOriginalPriceCtrl.dispose();
    for (var c in _variantLabelCtrls) {
      c.dispose();
    }
    for (var c in _variantPriceCtrls) {
      c.dispose();
    }
    for (var c in _variantDiscountPriceCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _addVariant() {
    setState(() {
      _variants.add(ProductVariantModel(
        variantId: DateTime.now().millisecondsSinceEpoch.toString(), 
        label: '', 
        price: 0, 
        discountPrice: 0,
        stock: 0,
        isAvailable: true,
      ));
      _variantLabelCtrls.add(TextEditingController());
      _variantPriceCtrls.add(TextEditingController());
      _variantDiscountPriceCtrls.add(TextEditingController());
    });
  }

  void _removeVariant(int index) {
    setState(() {
      _variants[index] = _variants[index].copyWith(isArchived: true);
    });
  }

  Future<void> _handleSave() async {
    // Collect data
    double basePrice = double.tryParse(_basePriceCtrl.text.trim()) ?? 0;
    double baseOriginalPrice = double.tryParse(_baseOriginalPriceCtrl.text.trim()) ?? 0;
    String baseWeight = _baseWeightCtrl.text.trim();

    List<ProductVariantModel> updatedVariants = [];
    for (int i = 0; i < _variants.length; i++) {
      if (_variants[i].isArchived) {
        updatedVariants.add(_variants[i]);
        continue;
      }
      
      String label = _variantLabelCtrls[i].text.trim();
      double p = double.tryParse(_variantPriceCtrls[i].text.trim()) ?? 0;
      double op = double.tryParse(_variantDiscountPriceCtrls[i].text.trim()) ?? 0;
      if (label.isNotEmpty && p > 0) {
        updatedVariants.add(ProductVariantModel(
          variantId: _variants[i].variantId.isEmpty ? DateTime.now().millisecondsSinceEpoch.toString() : _variants[i].variantId,
          label: label, 
          price: p, 
          discountPrice: op,
          stock: _variants[i].stock,
          isAvailable: _variants[i].isAvailable,
          isArchived: false,
        ));
      }
    }

    if (updatedVariants.isEmpty && basePrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please provide a valid price.')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final provider = context.read<ProductProvider>();
      
      // Update logic via provider (assuming provider has a general update method or we update Firestore directly)
      // Since operational changes are instant, we update the main doc immediately.
      
      Map<String, dynamic> updates = {};
      if (updatedVariants.isNotEmpty) {
        updates['variants'] = updatedVariants.map((e) => e.toJson()).toList();
        updates['price'] = updatedVariants.first.price; // keep base sync
        updates['originalPrice'] = updatedVariants.first.discountPrice;
        updates['weight'] = updatedVariants.first.label;
      } else {
        updates['variants'] = [];
        updates['price'] = basePrice;
        updates['originalPrice'] = baseOriginalPrice;
        updates['weight'] = baseWeight;
      }

      await provider.updateOperationalFields(_product.productId, updates);

      if (mounted) {
        setState(() => _isSaving = false);
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pricing updated instantly!')));
      }
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating pricing: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedbackData = _product.reviewFeedback?['packSizes'];
    final bool isNeedsFix = feedbackData?['status'] == 'needs_fix';
    final String feedbackMsg = feedbackData?['feedback'] ?? 'Please update the pricing/pack sizes as requested.';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pack Sizes & Pricing',
              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w900, fontSize: 18),
            ),
            Text(
              'Update your product pricing',
              style: TextStyle(color: AppColors.grey500, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isNeedsFix) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF5F5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.error.withOpacity(0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Changes Required', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(feedbackMsg, style: const TextStyle(color: Colors.black87, fontSize: 13, height: 1.4)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            if (_variants.isEmpty) ...[
              _buildSectionTitle('Base Pricing'),
              const SizedBox(height: 12),
              _buildBasePricingCard(),
              const SizedBox(height: 24),
            ],

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionTitle('Pack Sizes (Variants)'),
                if (_variants.isNotEmpty)
                  TextButton.icon(
                    onPressed: _addVariant,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Size', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                  )
              ],
            ),
            const SizedBox(height: 12),

            if (_variants.where((v) => !v.isArchived).isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200, style: BorderStyle.solid),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.inventory_2_outlined, size: 40, color: AppColors.grey400),
                    const SizedBox(height: 16),
                    const Text('Selling multiple sizes?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    const Text('Add variants like 250g, 500g, 1kg.', style: TextStyle(color: AppColors.grey500, fontSize: 13)),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _addVariant,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Pack Sizes'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF4FAF5),
                        foregroundColor: AppColors.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                      ),
                    )
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _variants.length,
                separatorBuilder: (c, i) => _variants[i].isArchived ? const SizedBox.shrink() : const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  return _buildVariantCard(index);
                },
              ),
              
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16).copyWith(bottom: MediaQuery.of(context).padding.bottom + 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF673AB7),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSaving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Save & Submit Review', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.flash_on, color: Color(0xFFF57F17), size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Pricing updates are published instantly without requiring admin review.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
    );
  }

  Widget _buildBasePricingCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _buildTextField('Pack Size / Weight', 'e.g., 500g, 1 Pack', _baseWeightCtrl, TextInputType.text),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildTextField('Selling Price (₹)', '0', _basePriceCtrl, TextInputType.number)),
              const SizedBox(width: 16),
              Expanded(child: _buildTextField('Original Price (₹)', '0', _baseOriginalPriceCtrl, TextInputType.number)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVariantCard(int index) {
    if (_variants[index].isArchived) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Variant ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
              InkWell(
                onTap: () => _removeVariant(index),
                child: const Icon(Icons.close, color: AppColors.grey500, size: 20),
              )
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField('Size Label', 'e.g., 250g', _variantLabelCtrls[index], TextInputType.text),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildTextField('Selling Price (₹)', '0', _variantPriceCtrls[index], TextInputType.number)),
              const SizedBox(width: 16),
              Expanded(child: _buildTextField('Original Price (₹)', '0', _variantDiscountPriceCtrls[index], TextInputType.number)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller, TextInputType keyboardType) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.grey400, fontWeight: FontWeight.normal),
            filled: true,
            fillColor: const Color(0xFFF9F9F9),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }
}
