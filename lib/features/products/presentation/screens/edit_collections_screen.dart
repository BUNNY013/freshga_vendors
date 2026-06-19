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

  @override
  void initState() {
    super.initState();
    _product = widget.product;
  }

  Future<void> _handleSubmit() async {
    setState(() => _isSaving = true);
    // Dummy submit logic for Collections
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() => _isSaving = false);
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Collections submitted for review!')));
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
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary), onPressed: () => context.pop()),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Collections & Categories', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w900, fontSize: 18)),
            Text('Manage placement', style: TextStyle(color: AppColors.grey500, fontSize: 12, fontWeight: FontWeight.w500)),
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
              child: _isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Submit Review', style: TextStyle(fontWeight: FontWeight.bold)),
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
              decoration: BoxDecoration(color: const Color(0xFFF8F5FF), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFEFE8FF))),
              child: const Row(
                children: [
                  Icon(Icons.admin_panel_settings, color: Color(0xFF673AB7), size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text('Content updates require admin review.', style: TextStyle(color: Color(0xFF673AB7), fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
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
                  const Text('Subcategories', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F9F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('Subcategories feature coming in Phase 2!', style: TextStyle(color: AppColors.grey500)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
