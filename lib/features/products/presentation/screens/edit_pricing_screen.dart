import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  bool _isSaving = false;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    
    _baseWeightCtrl = TextEditingController(text: _product.weight);
    final hasBaseDiscount = _product.originalPrice > _product.price && _product.price > 0;
    _baseOriginalPriceCtrl = TextEditingController(
      text: _product.originalPrice > 0 
          ? _product.originalPrice.toStringAsFixed(0) 
          : (_product.price > 0 ? _product.price.toStringAsFixed(0) : '')
    );
    _basePriceCtrl = TextEditingController(
      text: hasBaseDiscount ? _product.price.toStringAsFixed(0) : ''
    );

    bool isLiveOrWasLive = _product.lastApprovedAt != null || _product.status.startsWith('Live');
    _variants = List.from(isLiveOrWasLive
        ? _product.variants
        : (_product.draftVersion?['variants']?.map((e) => ProductVariantModel.fromJson(e as Map<String, dynamic>)) ?? _product.variants));
  }

  void _markDirty() {
    if (!_hasUnsavedChanges) setState(() => _hasUnsavedChanges = true);
  }

  @override
  void dispose() {
    _baseWeightCtrl.dispose();
    _basePriceCtrl.dispose();
    _baseOriginalPriceCtrl.dispose();
    super.dispose();
  }

  void _removeVariant(int index) {
    final int activeVariantsCount = _variants.where((v) => !v.isArchived).length;
    if (activeVariantsCount <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ You must maintain at least 1 variant / pack size. Add another size before deleting this one.'),
          backgroundColor: Color(0xFFD97706),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    setState(() {
      _variants[index] = _variants[index].copyWith(isArchived: true);
    });
    _saveVariantsToFirestore();
  }

  void _toggleVariantStock(int index, bool val) {
    setState(() {
      _variants[index] = _variants[index].copyWith(isAvailable: val);
    });
    _saveVariantsToFirestore();
  }

  Future<void> _saveVariantsToFirestore() async {
    double inputOriginalPrice = double.tryParse(_baseOriginalPriceCtrl.text.trim()) ?? 0;
    double inputDiscountPrice = double.tryParse(_basePriceCtrl.text.trim()) ?? 0;
    double basePrice = inputDiscountPrice > 0 ? inputDiscountPrice : inputOriginalPrice;
    double baseOriginalPrice = inputOriginalPrice;
    String baseWeight = _baseWeightCtrl.text.trim();

    List<ProductVariantModel> updatedVariants = _variants.where((v) => !v.isArchived).toList();

    try {
      final provider = context.read<ProductProvider>();
      Map<String, dynamic> updates = {};
      if (updatedVariants.isNotEmpty) {
        final defaultOrFirst = updatedVariants.firstWhere((v) => v.isDefault, orElse: () => updatedVariants.first);
        updates['variants'] = _variants.map((e) => e.toJson()).toList();
        updates['price'] = defaultOrFirst.discountPrice > 0 ? defaultOrFirst.discountPrice : defaultOrFirst.price;
        updates['originalPrice'] = defaultOrFirst.price;
        updates['weight'] = defaultOrFirst.label;
      } else {
        updates['variants'] = [];
        updates['price'] = basePrice;
        updates['originalPrice'] = baseOriginalPrice;
        updates['weight'] = baseWeight;
      }

      await provider.updateOperationalFields(_product.productId, updates, clearRequiredFix: 'packSizes');
      if (mounted) {
        setState(() => _hasUnsavedChanges = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Updated in real-time!'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating pricing: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .doc(widget.product.productId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.exists) {
          final liveProduct = ProductModel.fromJson(snapshot.data!.data() as Map<String, dynamic>);
          _product = liveProduct;
          if (!_hasUnsavedChanges) {
            bool isLiveOrWasLive = _product.lastApprovedAt != null || _product.status.startsWith('Live');
            _variants = List.from(isLiveOrWasLive
                ? _product.variants
                : (_product.draftVersion?['variants']?.map((e) => ProductVariantModel.fromJson(e as Map<String, dynamic>)) ?? _product.variants));
          }
        }

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
                  TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Discard', style: TextStyle(color: AppColors.error))),
                ],
              ),
            );
            if (discard == true && context.mounted) {
              Navigator.pop(context);
            }
          },
          child: Scaffold(
            backgroundColor: const Color(0xFFF9FAFB),
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
              title: const Text(
                'Pack Sizes & Pricing',
                style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 20),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: TextButton.icon(
                    onPressed: () => _openAddVariantSheet(pack: null, editIndex: null),
                    icon: const Icon(Icons.add_circle_outline, size: 18, color: AppColors.primary),
                    label: const Text('Add Size', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14)),
                  ),
                ),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Show reviewer feedback message inside the screen if pricing section requires fixes
                  if (_product.requiredFixes.contains('packSizes') || _product.reviewFeedback?['packSizes']?['status'] == 'needs_fix') ...[
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF5F5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFFE2E2), width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Reviewer Feedback • Action Required',
                                style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '"${_product.reviewFeedback?['packSizes']?['feedback'] ?? (_product.adminFeedback.isNotEmpty ? _product.adminFeedback : 'Please adjust your pack sizes & pricing.')}"',
                            style: const TextStyle(color: Color(0xFF991B1B), fontSize: 13, height: 1.35, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (_variants.isEmpty) ...[
                    const Text('Base Pricing', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 12),
                    _buildBasePricingCard(),
                    const SizedBox(height: 24),
                  ],

                  const Text('Variants (Pack Sizes)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  if (_variants.where((v) => !v.isArchived).isEmpty)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _openAddVariantSheet(pack: null, editIndex: null),
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

                  const SizedBox(height: 24),
                  // Only show price-drop follower notification for existing live products!
                  if (_product.lastApprovedAt != null || _product.status.startsWith('Live')) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.campaign_outlined, color: AppColors.primary, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Followers are notified!',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF15803D), fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'When you drop the price or add a discount on your live product, we automatically send a "Price Drop" alert to all your store followers\' feed.',
                                  style: TextStyle(color: Colors.green.shade900, fontSize: 13, height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.auto_awesome, color: AppColors.primary, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Smart Pricing Tip',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF15803D), fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Add more variants like 400g, 500g, and 1kg to give buyers options and increase sales.',
                                style: TextStyle(color: Colors.green.shade900, fontSize: 13, height: 1.4),
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
          ),
        );
      },
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
              Expanded(child: _buildVariantTextField('Original Price (₹)', '0', _baseOriginalPriceCtrl, TextInputType.number, Icons.attach_money)),
              const SizedBox(width: 16),
              Expanded(child: _buildVariantTextField('Discount Price (₹)', '0', _basePriceCtrl, TextInputType.number, Icons.local_offer_outlined)),
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

    final variant = _variants[index];

    int? discountPercentage;
    double? savingAmount;
    if (variant.price > 0 && variant.discountPrice > 0 && variant.discountPrice < variant.price) {
      discountPercentage = (((variant.price - variant.discountPrice) / variant.price) * 100).round();
      savingAmount = variant.price - variant.discountPrice;
    }
    double effectivePrice = (variant.discountPrice > 0 && variant.discountPrice < variant.price) ? variant.discountPrice : variant.price;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFEAECF0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Minimal Variant label, Stock pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Text(
                  'VARIANT $displayIndex',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _toggleVariantStock(index, !variant.isAvailable),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: variant.isAvailable ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: variant.isAvailable ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: variant.isAvailable ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        variant.isAvailable
                            ? ((variant.manageStock || variant.stock > 0)
                                ? 'In Stock (${variant.stock})'
                                : 'In Stock')
                            : 'Sold Out',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: variant.isAvailable ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Main Info Row: Label/Size + Price details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      variant.label.isNotEmpty ? variant.label : 'Unnamed Size',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                    ),
                    if (variant.manageStock || variant.stock > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        variant.stock > 0
                            ? '${variant.stock} units available'
                            : '0 units (Sold Out)',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      if (discountPercentage != null) ...[
                        Text(
                          '₹${variant.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF94A3B8),
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        '₹${effectivePrice.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                  if (discountPercentage != null)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '-$discountPercentage%',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF15803D)),
                      ),
                    ),
                ],
              ),
            ],
          ),

          if (variant.lengthCm > 0 || variant.weightGrams > 0) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.local_shipping_outlined,
                  size: 14,
                  color: Color(0xFF94A3B8),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    variant.lengthCm > 0
                        ? 'Box: ${variant.lengthCm.toStringAsFixed(0)}×${variant.widthCm.toStringAsFixed(0)}×${variant.heightCm.toStringAsFixed(0)} cm • Wt: ${variant.weightGrams}g'
                        : 'Wt: ${variant.weightGrams}g',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),

          // Action Buttons: Sleek Minimalist Edit and Delete
          Builder(
            builder: (context) {
              final bool isOnlyVariant = _variants.where((v) => !v.isArchived).length <= 1;
              return Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Tooltip(
                    message: isOnlyVariant
                        ? 'At least 1 variant required'
                        : 'Delete this variant',
                    child: OutlinedButton.icon(
                      onPressed: () => _removeVariant(index),
                      icon: Icon(Icons.delete_outline, size: 15, color: isOnlyVariant ? const Color(0xFFCBD5E1) : const Color(0xFF64748B)),
                      label: Text('Delete', style: TextStyle(color: isOnlyVariant ? const Color(0xFFCBD5E1) : const Color(0xFF64748B), fontWeight: FontWeight.w600, fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        minimumSize: Size.zero,
                        side: BorderSide(color: isOnlyVariant ? const Color(0xFFF1F5F9) : const Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () => _openAddVariantSheet(pack: variant, editIndex: index),
                icon: const Icon(Icons.edit_outlined, size: 15, color: Colors.white),
                label: const Text('Edit Variant', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size.zero,
                  backgroundColor: AppColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _openAddVariantSheet({ProductVariantModel? pack, int? editIndex}) {
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
    bool isDefault = pack?.isDefault ?? (_variants.where((v) => !v.isArchived).isEmpty);

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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Align(
                    alignment: Alignment.centerLeft, 
                    child: Text(editIndex != null ? "Edit Pack Size" : "Add New Pack Size", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  ),
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
                                variantId: pack?.variantId ?? DateTime.now().millisecondsSinceEpoch.toString(),
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
                                for (int i = 0; i < _variants.length; i++) {
                                  _variants[i] = _variants[i].copyWith(isDefault: false);
                                }
                              }
                              
                              if (editIndex != null && editIndex < _variants.length) {
                                _variants[editIndex] = newPack;
                              } else {
                                _variants.add(newPack);
                              }
                              
                              if (_variants.where((v) => !v.isArchived).length == 1) {
                                final firstIdx = _variants.indexWhere((v) => !v.isArchived);
                                if (firstIdx != -1) {
                                  _variants[firstIdx] = _variants[firstIdx].copyWith(isDefault: true);
                                }
                              }
                            });
                            
                            Navigator.pop(context);
                            _saveVariantsToFirestore();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            minimumSize: const Size(double.infinity, 54),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: Text(editIndex != null ? "Save Pack Size" : "Add Pack Size", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
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
