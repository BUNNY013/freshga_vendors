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
  bool _hasUnsavedChanges = false;

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

  void _markDirty() {
    if (!_hasUnsavedChanges) setState(() => _hasUnsavedChanges = true);
  }

  @override
  void dispose() {
    _baseWeightCtrl.dispose();
    _basePriceCtrl.dispose();
    _baseOriginalPriceCtrl.dispose();
    for (var c in _variantLabelCtrls) c.dispose();
    for (var c in _variantPriceCtrls) c.dispose();
    for (var c in _variantDiscountPriceCtrls) c.dispose();
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
      _hasUnsavedChanges = true;
    });
  }

  void _removeVariant(int index) {
    setState(() {
      _variants[index] = _variants[index].copyWith(isArchived: true);
      _hasUnsavedChanges = true;
    });
  }

  Future<void> _handleSave() async {
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
      
      Map<String, dynamic> updates = {};
      if (updatedVariants.isNotEmpty) {
        updates['variants'] = updatedVariants.map((e) => e.toJson()).toList();
        updates['price'] = updatedVariants.first.price;
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
        setState(() {
          _isSaving = false;
          _hasUnsavedChanges = false;
        });
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
    return PopScope(
      canPop: !_hasUnsavedChanges || _isSaving,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final bool? discard = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Discard Changes?'),
            content: const Text('You have unsaved changes. Are you sure you want to discard them?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Continue Editing', style: TextStyle(color: AppColors.primary))),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Discard', style: TextStyle(color: Colors.red))),
            ],
          ),
        );
        if (discard == true && mounted) {
          context.pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          centerTitle: false,
          titleSpacing: 0,
          backgroundColor: Colors.white,
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
                style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(
                'Add different pack sizes and set pricing',
                style: TextStyle(color: AppColors.grey500, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_variants.isEmpty) ...[
                const Text('Base Pricing', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 12),
                _buildBasePricingCard(),
                const SizedBox(height: 24),
              ],

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Variants (Pack Sizes)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  if (_variants.isNotEmpty)
                    TextButton.icon(
                      onPressed: _addVariant,
                      icon: const Icon(Icons.add, size: 18, color: AppColors.primary),
                      label: const Text('Add Size', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                    )
                ],
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.local_offer_outlined, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Add multiple pack sizes to give customers more choices.',
                        style: TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (_variants.where((v) => !v.isArchived).isEmpty)
                // Add first size button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _addVariant,
                    icon: const Icon(Icons.add, color: AppColors.primary),
                    label: const Text('Add Size', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
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
                
              if (_variants.where((v) => !v.isArchived).isNotEmpty) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _addVariant,
                    icon: const Icon(Icons.add, color: AppColors.primary),
                    label: const Text('Add Another Size', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.grey.shade300, style: BorderStyle.solid), // Dashed look approximation
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3FF), // Light purple
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.auto_awesome, color: Color(0xFF7C3AED), size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Smart Tip', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6D28D9), fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(
                            'Add more variants like 400g, 1kg, 500g to increase visibility and sales.',
                            style: TextStyle(color: Colors.grey.shade800, fontSize: 13, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
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
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(_product.status == 'Draft' ? 'Save & Submit Review' : 'Save Changes', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outline, color: AppColors.grey500, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'Your changes will be reviewed before going live.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
          _buildVariantTextField('Pack Size / Weight', 'e.g., 500g', _baseWeightCtrl, TextInputType.text, Icons.inventory_2_outlined),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildVariantTextField('Selling Price (₹)', '0', _basePriceCtrl, TextInputType.number, Icons.attach_money)),
              const SizedBox(width: 16),
              Expanded(child: _buildVariantTextField('Original Price (₹)', '0', _baseOriginalPriceCtrl, TextInputType.number, Icons.money_off)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVariantCard(int index) {
    if (_variants[index].isArchived) return const SizedBox.shrink();
    
    int displayIndex = 1;
    for (int i = 0; i < index; i++) {
      if (!_variants[i].isArchived) displayIndex++;
    }

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
              Row(
                children: [
                  const Icon(Icons.drag_indicator, color: AppColors.grey400, size: 20),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      'Variant $displayIndex',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 12),
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => _removeVariant(index),
                child: const Icon(Icons.delete_outline, color: AppColors.grey500, size: 20),
              )
            ],
          ),
          const SizedBox(height: 16),
          _buildVariantTextField('Size Label', 'e.g., 800g', _variantLabelCtrls[index], TextInputType.text, Icons.inventory_2_outlined),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildVariantTextField('Selling Price (₹)', '0', _variantPriceCtrls[index], TextInputType.number, Icons.attach_money)),
              const SizedBox(width: 16),
              Expanded(child: _buildVariantTextField('Original Price (₹)', '0', _variantDiscountPriceCtrls[index], TextInputType.number, Icons.money_off)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVariantTextField(String label, String hint, TextEditingController controller, TextInputType keyboardType, IconData iconData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(iconData, color: AppColors.primary, size: 16),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  onChanged: (_) => _markDirty(),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: const TextStyle(color: AppColors.grey400, fontWeight: FontWeight.normal, fontSize: 14),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
