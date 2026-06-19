import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/product_model.dart';
import '../providers/product_provider.dart';

class EditOptionalDetailsScreen extends StatefulWidget {
  final ProductModel product;
  const EditOptionalDetailsScreen({super.key, required this.product});
  @override
  State<EditOptionalDetailsScreen> createState() => _EditOptionalDetailsScreenState();
}

class _EditOptionalDetailsScreenState extends State<EditOptionalDetailsScreen> {
  late ProductModel _product;
  bool _isSaving = false;
  late TextEditingController _storageCtrl;
  late TextEditingController _ingredientsCtrl;
  late TextEditingController _dispatchTimeCtrl;
  late TextEditingController _shelfLifeCtrl;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    final pending = _product.pendingUpdate ?? {};
    
    _storageCtrl = TextEditingController(text: pending['storageInstructions'] ?? _product.storageInstructions);
    _ingredientsCtrl = TextEditingController(text: pending['ingredients'] != null ? (pending['ingredients'] as List).join(', ') : _product.ingredients.join(', '));
    _dispatchTimeCtrl = TextEditingController(text: pending['dispatchTime'] ?? _product.dispatchTime);
    _shelfLifeCtrl = TextEditingController(text: pending['shelfLife'] ?? _product.shelfLife);
  }

  @override
  void dispose() {
    _storageCtrl.dispose();
    _ingredientsCtrl.dispose();
    _dispatchTimeCtrl.dispose();
    _shelfLifeCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    setState(() => _isSaving = true);
    try {
      final provider = context.read<ProductProvider>();
      Map<String, dynamic> currentPending = _product.pendingUpdate != null ? Map.from(_product.pendingUpdate!) : {};
      currentPending['storageInstructions'] = _storageCtrl.text.trim();
      currentPending['ingredients'] = _ingredientsCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      currentPending['dispatchTime'] = _dispatchTimeCtrl.text.trim();
      currentPending['shelfLife'] = _shelfLifeCtrl.text.trim();
      
      Map<String, dynamic> updates = {
        'pendingUpdate': currentPending,
        'status': (_product.status == 'Live' || _product.status == 'Approved') ? 'Update Under Review' : _product.status,
      };

      await provider.updateProductPartial(_product.productId, updates);
      if (mounted) {
        setState(() => _isSaving = false);
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Optional details submitted for review!')));
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
    final feedbackData = _product.reviewFeedback?['others'];
    final bool isNeedsFix = feedbackData?['status'] == 'needs_fix';
    final String feedbackMsg = feedbackData?['feedback'] ?? 'Please update the details as requested.';

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
            Text('Others', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w900, fontSize: 18)),
            Text('Dispatch, shelf life & more', style: TextStyle(color: AppColors.grey500, fontSize: 12, fontWeight: FontWeight.w500)),
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
                  const Text('Dispatch Time', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _dispatchTimeCtrl,
                    decoration: InputDecoration(
                      hintText: 'e.g. 2 Days',
                      filled: true,
                      fillColor: const Color(0xFFF9F9F9),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text('Shelf Life', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _shelfLifeCtrl,
                    decoration: InputDecoration(
                      hintText: 'e.g. 6 Months',
                      filled: true,
                      fillColor: const Color(0xFFF9F9F9),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text('Ingredients', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _ingredientsCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'e.g. Mango, Salt, Chili Powder (comma separated)',
                      filled: true,
                      fillColor: const Color(0xFFF9F9F9),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text('Storage Instructions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _storageCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'e.g. Keep in a cool dry place',
                      filled: true,
                      fillColor: const Color(0xFFF9F9F9),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
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
