import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/product_model.dart';
import '../providers/product_provider.dart';
import '../widgets/product_preview_sheet.dart';

class ChangesRequiredDetailsScreen extends StatelessWidget {
  final ProductModel product;

  const ChangesRequiredDetailsScreen({super.key, required this.product});

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

  Widget _buildPlaceholder() {
    return Container(
      width: 80,
      height: 80,
      color: Colors.grey.shade100,
      child: const Icon(Icons.inventory_2_outlined, color: Colors.grey, size: 24),
    );
  }

  IconData _getIcon(String id) {
    switch (id) {
      case 'photos': return Icons.image_outlined;
      case 'information': return Icons.description_outlined;
      case 'collections': return Icons.category_outlined;
      case 'packSizes': return Icons.inventory_2_outlined;
      case 'others': return Icons.settings_outlined;
      default: return Icons.circle_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      final isUpdate = product.pendingUpdate != null && product.pendingUpdate!.isNotEmpty;
      final Map<String, dynamic> feedback = product.reviewFeedback ?? {};

      String formattedReviewedOn = 'Recently';
      try {
        final date = DateTime.parse(product.updatedAt);
        formattedReviewedOn = _formatDate(date, includeTime: false);
      } catch (_) {}

      final List<Map<String, String>> sections = [
        {'id': 'photos', 'title': 'Product Photos', 'subtitle': 'Update the product images', 'route': '/edit-photos'},
        {'id': 'information', 'title': 'Product Information', 'subtitle': 'Name, description & more', 'route': '/edit-product-info'},
        {'id': 'collections', 'title': 'Collections & Categories', 'subtitle': 'Update your catalog placement', 'route': '/edit-collections'},
        {'id': 'packSizes', 'title': 'Pack Sizes & Pricing', 'subtitle': '${product.variants.length} pack sizes added', 'route': '/edit-pricing'},
        {'id': 'others', 'title': 'Others', 'subtitle': 'Ingredients, shelf life, storage & more', 'route': '/edit-optional-details'},
      ];

      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC), // Very light cool grey background
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: const Text('Edit Product', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF1E293B), letterSpacing: -0.5)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
            onPressed: () => context.pop(),
          ),
          actions: [
            TextButton.icon(
              onPressed: () => ProductPreviewSheet.show(context, product),
              icon: const Icon(Icons.remove_red_eye_outlined, color: AppColors.primary, size: 18),
              label: const Text('Preview', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: AppColors.primary.withOpacity(0.3))),
              ),
            ),
            const SizedBox(width: 8),
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
                  color: const Color(0xFFFFF5F5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.error.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                      child: const Icon(Icons.warning_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Changes Required', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w800, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text(
                            'Our team reviewed your product and found some issues that need to be fixed before it can go live.',
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
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: product.images.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: product.images.first,
                              width: 80,
                              height: 80,
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
                          Text(product.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: -0.3)),
                          const SizedBox(height: 6),
                          Text(
                            product.categoryName,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(4)),
                            child: const Text('Changes Required', style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold)),
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Combined Admin Feedback Notes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Admin Feedback', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF1E293B))),
                  Text('Reviewed on $formattedReviewedOn', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.chat_bubble_outline, color: AppColors.error.withOpacity(0.7), size: 18),
                        const SizedBox(width: 8),
                        const Text('Notes from the review team:', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...sections.where((s) => feedback[s['id']]?['status'] == 'needs_fix').map((s) {
                      final sectionFeedback = feedback[s['id']];
                      final msg = sectionFeedback?['feedback'] ?? 'Please update this section.';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0, left: 26),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 6.0),
                              child: Icon(Icons.circle, size: 6, color: AppColors.error),
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(msg.toString(), style: const TextStyle(color: Colors.black87, height: 1.4))),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              const Text('Product Details', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF1E293B))),
              const SizedBox(height: 4),
              Text('Fix the highlighted sections below', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              const SizedBox(height: 16),

              // Section Checklist
              ...sections.map((section) {
                final sectionData = feedback[section['id']];
                final status = sectionData?['status'] ?? 'pending';
                
                bool isNeedsFix = status == 'needs_fix';
                bool isApproved = status == 'approved';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () {
                      context.push(section['route']!, extra: product);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isNeedsFix ? const Color(0xFFFFF5F5) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isNeedsFix ? const Color(0xFFFFEAEA) : Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isNeedsFix ? Colors.white : const Color(0xFFF4FAF5),
                              shape: BoxShape.circle,
                              border: Border.all(color: isNeedsFix ? const Color(0xFFFFEAEA) : Colors.transparent),
                            ),
                            child: Icon(_getIcon(section['id']!), color: isNeedsFix ? AppColors.error : Colors.green, size: 20),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: Text(section['title']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                                    if (isNeedsFix) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                        child: const Text('Required', style: TextStyle(color: AppColors.error, fontSize: 10, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  section['subtitle']!,
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          if (isNeedsFix)
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                              child: const Icon(Icons.priority_high, color: Colors.white, size: 12),
                            )
                          else if (isApproved)
                            const Icon(Icons.check_circle, color: Colors.green, size: 20),
                          const SizedBox(width: 8),
                          Icon(Icons.chevron_right, color: Colors.grey.shade400),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),

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
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))
            ]
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.pop();
                      },
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Delete'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final provider = context.read<ProductProvider>();
                        await provider.resubmitProduct(product.productId);
                        if (context.mounted) {
                          context.pop();
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product resubmitted for review!')));
                        }
                      },
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: const Text('Resubmit Product', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 6),
                  Text('After resubmission, your product will go under review again.', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                ],
              ),
            ],
          ),
        ),
      );
    } catch (e, stackTrace) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Text('An error occurred during build:\n$e\n\n$stackTrace', style: const TextStyle(color: Colors.red)),
        ),
      );
    }
  }
}
