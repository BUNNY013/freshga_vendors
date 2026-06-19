import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/product_model.dart';
import '../providers/product_provider.dart';

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
    _product = widget.product;
    _subCategoryIds = List.from(_product.pendingUpdate?['subCategoryIds'] ?? _product.subCategoryIds);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadSubCategories(_product.categoryId);
    });
  }

  Future<void> _handleSubmit() async {
    if (_subCategoryIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one collection')));
      return;
    }

    setState(() => _isSaving = true);
    try {
      final provider = context.read<ProductProvider>();
      
      Map<String, dynamic> currentPending = _product.pendingUpdate != null ? Map.from(_product.pendingUpdate!) : {};
      currentPending['subCategoryIds'] = _subCategoryIds;
      
      Map<String, dynamic> updates = {
        'pendingUpdate': currentPending,
        'status': (_product.status == 'Live' || _product.status == 'Approved') ? 'Update Under Review' : _product.status,
      };

      await provider.updateProductPartial(_product.productId, updates);

      if (mounted) {
        setState(() => _isSaving = false);
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Collections submitted for review!')));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedbackData = _product.reviewFeedback?['collections'];
    final bool isNeedsFix = feedbackData?['status'] == 'needs_fix';
    final String feedbackMsg = feedbackData?['feedback'] ?? 'Please update the collections as requested.';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary), onPressed: () => context.pop()),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Collections & Categories', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w900, fontSize: 18)),
            Text('Manage placement', style: TextStyle(color: AppColors.grey500, fontSize: 12, fontWeight: FontWeight.w500)),
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
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Current Category', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F9F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(_product.categoryName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 24),
                  const Text('Subcategories (Collections)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Consumer<ProductProvider>(
                    builder: (context, provider, _) {
                      final subCategories = provider.subCategories;
                      if (provider.isLoading && subCategories.isEmpty) {
                        return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
                      }
                      if (subCategories.isEmpty) {
                        return const Text("No sub categories available for this category.", style: TextStyle(color: AppColors.grey500));
                      }
                      return Wrap(
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
                                  Text(sub.name, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, color: isSelected ? AppColors.primary : AppColors.textPrimary)),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
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
                    onPressed: _isSaving ? null : _handleSubmit,
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
                const Icon(Icons.admin_panel_settings, color: Color(0xFF673AB7), size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Content updates require admin review before going live.',
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
}
