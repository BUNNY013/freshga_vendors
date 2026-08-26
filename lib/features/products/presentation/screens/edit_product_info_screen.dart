import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/presentation/widgets/premium_text_field.dart';
import '../../../../data/models/product_model.dart';
import '../providers/product_provider.dart';
import '../../utils/product_change_detector.dart';

class EditProductInfoScreen extends StatefulWidget {
  final ProductModel product;

  const EditProductInfoScreen({super.key, required this.product});

  @override
  State<EditProductInfoScreen> createState() => _EditProductInfoScreenState();
}

class _EditProductInfoScreenState extends State<EditProductInfoScreen> {
  late ProductModel _product;
  
  late TextEditingController _nameCtrl;
  late TextEditingController _shortDescCtrl;
  late TextEditingController _descCtrl;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _product = widget.product.applyDraftUpdates();
    
    _nameCtrl = TextEditingController(text: _product.name ?? '')..addListener(_onFieldChanged);
    _shortDescCtrl = TextEditingController(text: _product.shortDescription ?? '')..addListener(_onFieldChanged);
    _descCtrl = TextEditingController(text: _product.description ?? '')..addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _shortDescCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    setState(() {});
  }

  bool get _isLocked => widget.product.status == 'Under Review' || widget.product.status == 'Live + Update Pending';

  bool get _hasChanges {
    final original = widget.product.applyDraftUpdates();
    if (_nameCtrl.text.trim() != (original.name ?? '')) return true;
    if (_shortDescCtrl.text.trim() != (original.shortDescription ?? '')) return true;
    if (_descCtrl.text.trim() != (original.description ?? '')) return true;
    return false;
  }

  bool get _canSave => _hasChanges && !_isSaving && !_isLocked;

  String get _buttonText {
    if (_isSaving) return 'Saving...';
    if (_isLocked) return 'Update Under Review';
    if (widget.product.status == 'Changes Required') return 'Save Changes';
    return 'Save Changes';
  }

  Future<void> _handleSubmit() async {
    if (!_hasChanges) return;

    final name = _nameCtrl.text.trim();
    final shortDesc = _shortDescCtrl.text.trim();
    final desc = _descCtrl.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product name is required.')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final provider = context.read<ProductProvider>();
      
      final req = await provider.updateDraftContent(
        widget.product,
        {
          'name': name,
          'shortDescription': shortDesc,
          'description': desc,
        },
        clearRequiredFix: 'information',
      );

      if (mounted) {
        setState(() => _isSaving = false);
        if (req == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.errorMessage ?? 'Failed to save changes. Please try again.'),
              backgroundColor: AppColors.error,
            ),
          );
          return;
        }
        context.pop();
        
        if (widget.product.status == 'Changes Required' || req == ReviewRequirement.noReview) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Changes saved successfully.')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Update submitted for review. Your current live version remains visible until approval.')));
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showPreviewModal() {
    final priceDisplay = _product.variants.isNotEmpty 
        ? '₹${_product.variants.first.price.toStringAsFixed(0)}' 
        : '₹${_product.price.toStringAsFixed(0)}';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Customer Preview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _product.images.isNotEmpty 
                            ? CachedNetworkImage(imageUrl: _product.images.first, width: 80, height: 80, fit: BoxFit.cover, memCacheWidth: 200)
                            : Container(width: 80, height: 80, color: Colors.grey.shade200),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_nameCtrl.text.isEmpty ? 'Product Name' : _nameCtrl.text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text(_shortDescCtrl.text.isEmpty ? 'Short description preview' : _shortDescCtrl.text, style: TextStyle(color: Colors.grey.shade600, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 8),
                            Text(priceDisplay, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => context.pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: const Text('Close Preview', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges || _isSaving,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final bool? discard = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Discard Changes?'),
            content: const Text('You have unsaved changes. Are you sure you want to discard them?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Continue Editing')),
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
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          centerTitle: false,
          titleSpacing: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => context.pop(),
          ),
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Product Information',
                style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 18),
              ),
              Text(
                'Edit name, description & details',
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
              if (widget.product.requiredFixes.contains('information') || widget.product.reviewFeedback?['information']?['status'] == 'needs_fix') ...[
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
                        '"${widget.product.reviewFeedback?['information']?['feedback'] ?? (widget.product.adminFeedback.isNotEmpty ? widget.product.adminFeedback : 'Please update your product name or description.')}"',
                        style: const TextStyle(color: Color(0xFF991B1B), fontSize: 13, height: 1.35, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
              PremiumTextField(
                label: 'Product Name',
                isRequired: true,
                controller: _nameCtrl,
                maxLength: 60,
                hintText: 'Grandma Mango Pickle',
                helperText: 'Use a simple and searchable product name.',
                readOnly: _isLocked,
              ),
              const SizedBox(height: 24),
              PremiumTextField(
                label: 'Short Description',
                isRequired: true,
                controller: _shortDescCtrl,
                maxLength: 120,
                maxLines: 3,
                hintText: 'Traditional homemade mango pickle made using authentic Andhra recipe.',
                helperText: 'Shown on product cards and previews.',
                readOnly: _isLocked,
              ),
              const SizedBox(height: 24),
              PremiumTextField(
                label: 'Product Description',
                isRequired: true,
                controller: _descCtrl,
                maxLength: 1000,
                maxLines: 8,
                hintText: 'Describe ingredients, preparation style, taste, texture and what makes your product special.',
                helperText: 'Displayed on the product details page.',
                readOnly: _isLocked,
              ),
              const SizedBox(height: 32),

              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFEDD5)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFFEA580C), size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Changes you make may require admin review before being visible to customers.',
                        style: TextStyle(color: Color(0xFF9A3412), fontSize: 13),
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
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
          ),
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: OutlinedButton(
                  onPressed: _isSaving ? null : () => context.pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _canSave ? _handleSubmit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    disabledBackgroundColor: Colors.grey.shade300,
                    disabledForegroundColor: Colors.grey.shade600,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(_buttonText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
