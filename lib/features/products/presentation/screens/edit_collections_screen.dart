import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/product_model.dart';
import '../providers/product_provider.dart';
import '../../utils/product_change_detector.dart';

class EditCollectionsScreen extends StatefulWidget {
  final ProductModel product;
  const EditCollectionsScreen({super.key, required this.product});
  @override
  State<EditCollectionsScreen> createState() => _EditCollectionsScreenState();
}

class _EditCollectionsScreenState extends State<EditCollectionsScreen> {
  late ProductModel _product;
  bool _isSaving = false;
  List<String> _subCategoryIds = [];

  @override
  void initState() {
    super.initState();
    _product = widget.product.applyDraftUpdates();
    _subCategoryIds = List.from(_product.subCategoryIds);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadSubCategories(_product.categoryId);
    });
  }

  bool get _isLocked => widget.product.status == 'Under Review' || widget.product.status == 'Live + Update Pending';

  bool get _hasChanges {
    final original = widget.product.applyDraftUpdates();
    if (_subCategoryIds.length != original.subCategoryIds.length) return true;
    for (final id in _subCategoryIds) {
      if (!original.subCategoryIds.contains(id)) return true;
    }
    return false;
  }

  bool get _canSave => _hasChanges && !_isSaving && !_isLocked;

  String get _buttonText {
    if (_isSaving) return 'Saving...';
    if (_isLocked) return 'Update Under Review';
    if (widget.product.status == 'Changes Required') return 'Save & Resubmit';
    return 'Save Changes';
  }

  Future<void> _handleSubmit() async {
    if (!_hasChanges) return;

    if (_subCategoryIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one collection')));
      return;
    }

    setState(() => _isSaving = true);
    try {
      final provider = context.read<ProductProvider>();
      
      final req = await provider.updateDraftContent(
        widget.product,
        {'subCategoryIds': _subCategoryIds},
        clearRequiredFix: 'categories',
      );

      if (mounted) {
        setState(() => _isSaving = false);
        context.pop();
        if (req == ReviewRequirement.noReview) {
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



  Widget _buildCategorySection() {
    final provider = context.watch<ProductProvider>();
    String? imageUrl;
    try {
      imageUrl = provider.categories.firstWhere((c) => c.categoryId == _product.categoryId).imageUrl;
    } catch (_) {}

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Main Category (Fixed)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                padding: imageUrl == null || imageUrl.isEmpty ? const EdgeInsets.all(8) : EdgeInsets.zero,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(8),
                ),
                clipBehavior: Clip.antiAlias,
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover, memCacheWidth: 100)
                    : const Icon(Icons.local_dining, color: Color(0xFF16A34A), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(_product.categoryName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              ),
              const Icon(Icons.lock_outline, size: 18, color: AppColors.grey500),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text('This is the main category and cannot be changed.', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
      ],
    );
  }



  Widget _buildSubcategoriesSection(ProductProvider provider) {
    final subCategories = provider.subCategories;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Collections (Subcategories)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            Row(
              children: [
                Text('${_subCategoryIds.length} selected', style: const TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_up, color: Color(0xFF16A34A), size: 18),
              ],
            )
          ],
        ),
        const SizedBox(height: 4),
        const Text('Choose all that apply to your product', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
        const SizedBox(height: 16),
        if (provider.isLoading && subCategories.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
        else if (subCategories.isEmpty)
          const Text("No collections available.", style: TextStyle(color: AppColors.grey500))
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final double width = (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: subCategories.map((sub) {
                  final isSelected = _subCategoryIds.contains(sub.subCategoryId);
                  return GestureDetector(
                    onTap: _isLocked ? null : () {
                      setState(() {
                        if (isSelected) {
                          _subCategoryIds.remove(sub.subCategoryId);
                        } else {
                          _subCategoryIds.add(sub.subCategoryId);
                        }
                      });
                    },
                    child: Container(
                      width: width,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isSelected ? const Color(0xFF16A34A) : Colors.grey.shade300, width: 1),
                      ),
                      child: Row(
                        children: [
                          if (isSelected)
                            const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 18)
                          else
                            Icon(Icons.radio_button_unchecked, color: Colors.grey.shade300, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(sub.name, style: TextStyle(fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500, fontSize: 13, color: isSelected ? const Color(0xFF111827) : const Color(0xFF475569)), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final feedbackData = _product.reviewFeedback?['collections'];
    final bool isNeedsFix = feedbackData?['status'] == 'needs_fix';
    final String feedbackMsg = feedbackData?['feedback'] ?? 'Please update the collections as requested.';

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
          centerTitle: false,
          titleSpacing: 0,
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary), onPressed: () => context.pop()),
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Categories', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 18)),
              Text('Choose collections for your product', style: TextStyle(color: AppColors.grey500, fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
          actions: const [],
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
              
              _buildCategorySection(),
              const SizedBox(height: 24),
              


              Consumer<ProductProvider>(
                builder: (context, provider, _) => _buildSubcategoriesSection(provider),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Selecting the right collections improves product visibility', style: TextStyle(color: Color(0xFF9A3412), fontSize: 13, fontWeight: FontWeight.bold)),
                          SizedBox(height: 2),
                          Text('You can update these anytime.', style: TextStyle(color: Color(0xFF9A3412), fontSize: 12)),
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
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
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
                    child: ElevatedButton.icon(
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
                      icon: _isSaving ? const SizedBox() : const Icon(Icons.save_outlined, size: 20),
                      label: _isSaving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(_buttonText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline, color: Colors.grey.shade500, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'Updates require admin review before going live.',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
