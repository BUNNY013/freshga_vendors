import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/product_model.dart';
import '../providers/product_provider.dart';

class EditPhotosScreen extends StatefulWidget {
  final ProductModel product;

  const EditPhotosScreen({super.key, required this.product});

  @override
  State<EditPhotosScreen> createState() => _EditPhotosScreenState();
}

class _EditPhotosScreenState extends State<EditPhotosScreen> {
  late ProductModel _product;
  bool _isSaving = false;
  late List<String> _images;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    final pending = _product.pendingUpdate ?? {};
    _images = List<String>.from(pending['images'] ?? _product.images);
  }

  Future<void> _handleSubmit() async {
    setState(() => _isSaving = true);
    try {
      final provider = context.read<ProductProvider>();
      Map<String, dynamic> currentPending = _product.pendingUpdate != null ? Map.from(_product.pendingUpdate!) : {};
      currentPending['images'] = _images;
      
      Map<String, dynamic> updates = {
        'pendingUpdate': currentPending,
        'status': (_product.status == 'Live' || _product.status == 'Approved') ? 'Update Under Review' : _product.status,
      };

      await provider.updateProductPartial(_product.productId, updates);
      if (mounted) {
        setState(() => _isSaving = false);
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photos submitted for review!')));
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
            Text('Product Photos', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w900, fontSize: 18)),
            Text('Manage images', style: TextStyle(color: AppColors.grey500, fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 10, bottom: 10),
            child: ElevatedButton(
              onPressed: _isSaving ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF673AB7),
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size(0, 36),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: _isSaving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Submit Review', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F5FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEFE8FF)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.admin_panel_settings, color: Color(0xFF673AB7), size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Content updates require admin review. Your current live details will remain visible to customers until approved.',
                      style: TextStyle(color: Color(0xFF673AB7), fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ..._images.map((img) => Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(img, width: 100, height: 100, fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 4, right: 4,
                      child: GestureDetector(
                        onTap: () => setState(() => _images.remove(img)),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                          child: const Icon(Icons.close, color: Colors.white, size: 14),
                        ),
                      ),
                    ),
                  ],
                )),
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image picker not implemented in MVP')));
                  },
                  child: Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined, color: AppColors.primary, size: 28),
                        SizedBox(height: 4),
                        Text('Add Photo', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
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
