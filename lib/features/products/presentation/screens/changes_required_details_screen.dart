import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/product_model.dart';
import '../providers/product_provider.dart';
import '../widgets/product_preview_sheet.dart';

class FeedbackItem {
  final String title;
  final String description;
  final IconData icon;

  FeedbackItem(this.title, this.description, this.icon);
}

class ChangesRequiredDetailsScreen extends StatelessWidget {
  final ProductModel product;

  const ChangesRequiredDetailsScreen({super.key, required this.product});

  FeedbackItem _parseFeedback(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('image') || lower.contains('photo') || lower.contains('quality') || lower.contains('blurry')) {
      return FeedbackItem('Product Image', text, Icons.image_outlined);
    } else if (lower.contains('name') || lower.contains('title') || lower.contains('promotional')) {
      return FeedbackItem('Product Name', text, Icons.text_fields_rounded);
    } else if (lower.contains('category') || lower.contains('categories')) {
      return FeedbackItem('Category', text, Icons.grid_view_rounded);
    } else if (lower.contains('ingredient') || lower.contains('shelf') || lower.contains('missing') || lower.contains('incomplete')) {
      return FeedbackItem('Product Information', text, Icons.format_list_bulleted_rounded);
    } else if (lower.contains('price') || lower.contains('pricing') || lower.contains('variant')) {
      return FeedbackItem('Pricing & Variants', text, Icons.attach_money_rounded);
    } else if (lower.contains('description') || lower.contains('unclear') || lower.contains('short')) {
      return FeedbackItem('Description', text, Icons.description_outlined);
    } else if (lower.contains('policy') || lower.contains('permitted') || lower.contains('guideline')) {
      return FeedbackItem('Policy Violation', text, Icons.gavel_rounded);
    } else {
      return FeedbackItem('Action Required', text, Icons.error_outline_rounded);
    }
  }

  List<FeedbackItem> _getFeedbackItems() {
    final isUpdate = product.pendingUpdate != null && product.pendingUpdate!.isNotEmpty;
    final feedbackStr = isUpdate ? (product.updateAdminFeedback ?? '') : (product.adminFeedback ?? '');
    
    if (feedbackStr.isEmpty) return [FeedbackItem('Review Required', 'Please review your product details and ensure they comply with guidelines.', Icons.info_outline)];

    return feedbackStr
        .split('\n')
        .map((e) => e.replaceAll('•', '').trim())
        .where((e) => e.isNotEmpty)
        .map((e) => _parseFeedback(e))
        .toList();
  }

  String _formatDate(DateTime date, {bool includeTime = false}) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final day = date.day.toString().padLeft(2, '0');
    final month = months[date.month - 1];
    final year = date.year;
    
    if (!includeTime) {
      return '$day $month $year';
    }
    
    int hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    
    if (hour == 0) {
      hour = 12;
    } else if (hour > 12) {
      hour -= 12;
    }
    final formattedHour = hour.toString().padLeft(2, '0');
    
    return '$day $month $year, $formattedHour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final isUpdate = product.pendingUpdate != null && product.pendingUpdate!.isNotEmpty;
    final feedbackItems = _getFeedbackItems();

    String formattedReviewedOn = 'Recently';
    try {
      final date = DateTime.parse(product.updatedAt);
      formattedReviewedOn = _formatDate(date, includeTime: true);
    } catch (_) {}

    String formattedSubmittedOn = 'Recently';
    try {
      final date = DateTime.parse(product.createdAt);
      formattedSubmittedOn = _formatDate(date);
    } catch (_) {}

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Very light cool grey background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('Review Required', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF1E293B), letterSpacing: -0.5)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            onPressed: () => ProductPreviewSheet.show(context, product),
            icon: const Icon(Icons.remove_red_eye_outlined, color: Color(0xFF64748B)),
            tooltip: 'Preview',
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Action Needed Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.error.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(color: AppColors.error.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                ]
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.assignment_late_rounded, color: AppColors.error, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Action Required', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w800, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(
                          'Please address the feedback below before publishing.',
                          style: TextStyle(color: Colors.black87.withOpacity(0.7), fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Product Summary Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: product.images.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: product.images.first,
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            errorWidget: (c, u, e) => _buildPlaceholder(),
                          )
                        : _buildPlaceholder(),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(product.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: -0.3)),
                        const SizedBox(height: 4),
                        Text(
                          product.categoryName,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 32),

            // What needs to be updated Title
            const Text('Required Updates', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF1E293B))),
            const SizedBox(height: 16),

            // Feedback Cards List
            ...feedbackItems.map((item) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))
                ]
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppColors.error.withOpacity(0.08), shape: BoxShape.circle),
                    child: Icon(item.icon, color: AppColors.error, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0F172A))),
                        const SizedBox(height: 6),
                        Text(item.description, style: const TextStyle(color: Color(0xFF475569), fontSize: 14, height: 1.4)),
                      ],
                    ),
                  ),
                ],
              ),
            )).toList(),

            const SizedBox(height: 48), // Padding for scroll
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16).copyWith(bottom: MediaQuery.of(context).padding.bottom + 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))
          ]
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.push('/edit-product', extra: product),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit Product', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1E293B),
                  side: BorderSide(color: Colors.grey.shade300),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  final provider = context.read<ProductProvider>();
                  final newStatus = isUpdate ? 'Update Under Review' : 'Under Review';
                  
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (c) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  );
                  
                  final updated = product.copyWith(status: newStatus);
                  final success = await provider.updateProduct(updated);
                  
                  if (context.mounted) {
                    Navigator.pop(context); // close dialog
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product resubmitted successfully!')));
                      context.pop(); // go back
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to resubmit. Try again.')));
                    }
                  }
                },
                icon: const Icon(Icons.upload_rounded, size: 18),
                label: const Text('Resubmit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 64,
      height: 64,
      color: Colors.grey.shade100,
      child: const Icon(Icons.image, color: Colors.grey),
    );
  }
}
