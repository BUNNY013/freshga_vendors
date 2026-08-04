import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/product_model.dart';
import '../providers/product_provider.dart';

class ChangesRequiredDetailsScreen extends StatelessWidget {
  final ProductModel product;

  const ChangesRequiredDetailsScreen({super.key, required this.product});

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final day = date.day.toString().padLeft(2, '0');
    final month = months[date.month - 1];
    return '$day $month ${date.year}';
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 70,
      height: 70,
      color: Colors.grey.shade100,
      child: const Icon(Icons.inventory_2_outlined, color: Colors.grey, size: 22),
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
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('products').doc(product.productId).snapshots(),
      builder: (context, snapshot) {
        final currentProduct = (snapshot.hasData && snapshot.data!.exists && snapshot.data!.data() != null)
            ? ProductModel.fromJson(snapshot.data!.data() as Map<String, dynamic>)
            : product;

        return _buildScreenContent(context, currentProduct);
      },
    );
  }

  Widget _buildScreenContent(BuildContext context, ProductModel product) {
    try {
      final bool isLiveProduct = product.lastApprovedAt != null ||
          product.status.startsWith('Live') ||
          (product.pendingUpdate != null && product.pendingUpdate!.isNotEmpty);

      final Map<String, dynamic> feedback = product.reviewFeedback ?? {};

      String formattedReviewedOn = 'Recently';
      try {
        final date = DateTime.parse(product.updatedAt);
        formattedReviewedOn = _formatDate(date);
      } catch (_) {}

      final List<Map<String, String>> sections = [
        {'id': 'photos', 'title': 'Product Photos', 'subtitle': 'Images & gallery', 'route': '/edit-photos'},
        {'id': 'information', 'title': 'Product Information', 'subtitle': 'Name & description', 'route': '/edit-product-info'},
        {'id': 'collections', 'title': 'Collections & Categories', 'subtitle': 'Catalog placement', 'route': '/edit-collections'},
        {'id': 'packSizes', 'title': 'Pack Sizes & Pricing', 'subtitle': '${product.variants.length} size(s) added', 'route': '/edit-pricing'},
        {'id': 'others', 'title': 'Others', 'subtitle': 'Ingredients & shelf life', 'route': '/edit-optional-details'},
      ];

      final needsFixCount = sections.where((s) => product.requiredFixes.contains(s['id']) || feedback[s['id']]?['status'] == 'needs_fix').length;
      final approvedCount = sections.length - needsFixCount;

      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleSpacing: 0,
          title: const Text(
            'Changes Required',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF1E293B), letterSpacing: -0.5),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
            onPressed: () => context.pop(),
          ),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Color(0xFF475569)),
              onSelected: (val) {
                if (val == 'delete') {
                  _showDeleteConfirmDialog(context, product, isLiveProduct);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 18, color: Colors.red.shade600),
                      const SizedBox(width: 8),
                      Text(
                        isLiveProduct ? 'Discard Pending Update' : 'Delete Product Draft',
                        style: TextStyle(color: Colors.red.shade600, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Sleek Action Banner (Concise, zero overflow)
              _buildActionBanner(isLiveProduct),
              const SizedBox(height: 16),

              // 2. Compact Product Summary Card
              _buildProductSummaryCard(product, isLiveProduct),
              const SizedBox(height: 24),

              // 3. Reviewer Notes Card
              _buildReviewerNotesCard(context, product, feedback, sections, formattedReviewedOn, needsFixCount),
              const SizedBox(height: 24),

              // 4. Section Checklist with Progress
              _buildChecklistHeader(approvedCount, sections.length),
              const SizedBox(height: 12),
              _buildSectionChecklist(context, product, feedback, sections),

              const SizedBox(height: 40),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomBar(context, product, isLiveProduct),
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

  Widget _buildActionBanner(bool isLiveProduct) {
    if (isLiveProduct) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFDE68A), width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFD97706),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.info_outline, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Live Store Product • Update Needs Fix',
                    style: TextStyle(color: Color(0xFF92400E), fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your live product is active on the store. Fix the highlighted items below to apply your recent update.',
                    style: TextStyle(color: const Color(0xFF78350F).withOpacity(0.9), fontSize: 12, height: 1.35),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.error.withOpacity(0.2), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.warning_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Draft Product • Changes Required',
                  style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w800, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'Please fix the highlighted items below to submit your product for review.',
                  style: TextStyle(color: Colors.black87.withOpacity(0.75), fontSize: 12, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductSummaryCard(ProductModel product, bool isLiveProduct) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
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
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: -0.3, color: Color(0xFF0F172A), height: 1.25),
                ),
                const SizedBox(height: 2),
                Text(
                  product.categoryName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (isLiveProduct)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(5)),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle, size: 6, color: Color(0xFF16A34A)),
                            SizedBox(width: 4),
                            Text('Live on Store', style: TextStyle(color: Color(0xFF15803D), fontSize: 11, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: isLiveProduct ? Colors.orange.shade50 : const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 12,
                            color: isLiveProduct ? Colors.orange.shade800 : AppColors.error,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isLiveProduct ? 'Update Needs Fix' : 'Draft • Action Required',
                            style: TextStyle(
                              color: isLiveProduct ? Colors.orange.shade800 : AppColors.error,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewerNotesCard(
    BuildContext context,
    ProductModel product,
    Map<String, dynamic> feedback,
    List<Map<String, String>> sections,
    String formattedReviewedOn,
    int needsFixCount,
  ) {
    final fixSections = sections.where((s) => product.requiredFixes.contains(s['id']) || feedback[s['id']]?['status'] == 'needs_fix').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Clean header with zero overflow
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text('Reviewer Feedback', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF1E293B))),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: needsFixCount > 0 ? const Color(0xFFFEE2E2) : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$needsFixCount Required',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: needsFixCount > 0 ? AppColors.error : Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
            Text(formattedReviewedOn, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (fixSections.isEmpty && product.adminFeedback.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF5F5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFFE2E2)),
                  ),
                  child: Text(
                    product.adminFeedback,
                    style: const TextStyle(color: Color(0xFF991B1B), fontSize: 13, height: 1.35),
                  ),
                ),
              ] else if (fixSections.isEmpty) ...[
                const Text(
                  'No specific section items flagged. Please review your details and resubmit.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ] else ...[
                ...fixSections.map((s) {
                  final sectionFeedback = feedback[s['id']];
                  final msg = sectionFeedback?['feedback'] ?? (product.adminFeedback.isNotEmpty ? product.adminFeedback : 'Please update this section.');
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBFB),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFFE2E2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Icon(_getIcon(s['id']!), size: 16, color: AppColors.error),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      s['title']!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF991B1B)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: () => context.push(s['route']!, extra: product),
                              icon: const Icon(Icons.arrow_forward, size: 13),
                              label: const Text('Fix Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade100),
                          ),
                          child: Text(
                            msg.toString(),
                            style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13, height: 1.35, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChecklistHeader(int approvedCount, int totalCount) {
    final progress = totalCount > 0 ? (approvedCount / totalCount) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Product Checklist', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF1E293B))),
            Text(
              '$approvedCount / $totalCount Approved',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: approvedCount == totalCount ? Colors.green.shade700 : const Color(0xFFD97706),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 5,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              approvedCount == totalCount ? Colors.green.shade600 : const Color(0xFFF59E0B),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionChecklist(
    BuildContext context,
    ProductModel product,
    Map<String, dynamic> feedback,
    List<Map<String, String>> sections,
  ) {
    return Column(
      children: sections.map((section) {
        final sectionData = feedback[section['id']];
        final status = sectionData?['status'] ?? 'pending';

        final bool isNeedsFix = product.requiredFixes.contains(section['id']) || status == 'needs_fix';
        final bool isApproved = !isNeedsFix;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            onTap: () => context.push(section['route']!, extra: product),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isNeedsFix ? const Color(0xFFFFF5F5) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isNeedsFix ? const Color(0xFFFFE2E2) : Colors.grey.shade200,
                  width: isNeedsFix ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isNeedsFix ? Colors.white : const Color(0xFFF0FDF4),
                      shape: BoxShape.circle,
                      border: Border.all(color: isNeedsFix ? const Color(0xFFFFEAEA) : Colors.transparent),
                    ),
                    child: Icon(_getIcon(section['id']!), color: isNeedsFix ? AppColors.error : Colors.green.shade600, size: 18),
                  ),
                  const SizedBox(width: 12),
                  // CRITICAL: Use Expanded around the Title & Subtitle so long names NEVER overflow!
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          section['title']!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isNeedsFix
                              ? '⚠️ "${sectionData?['feedback'] ?? (product.adminFeedback.isNotEmpty ? product.adminFeedback : 'Needs adjustment')}"'
                              : section['subtitle']!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isNeedsFix ? const Color(0xFF991B1B) : Colors.grey.shade500,
                            fontSize: 11,
                            fontWeight: isNeedsFix ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Compact status badge on the right side
                  if (isNeedsFix)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(6)),
                      child: const Text(
                        'Required',
                        style: TextStyle(color: AppColors.error, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    )
                  else if (isApproved)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(6)),
                      child: const Text(
                        'Approved',
                        style: TextStyle(color: Color(0xFF15803D), fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  const SizedBox(width: 6),
                  Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 18),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomBar(BuildContext context, ProductModel product, bool isLiveProduct) {
    final bool hasRemainingFixes = product.requiredFixes.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16).copyWith(bottom: MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, -4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasRemainingFixes) ...[
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFED7AA)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFD97706)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Complete ${product.requiredFixes.length} required fix(es) above before resubmitting.',
                      style: const TextStyle(color: Color(0xFF92400E), fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                if (hasRemainingFixes) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Please address all required changes before resubmitting. Remaining: ${product.requiredFixes.join(", ")}',
                      ),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }
                final provider = context.read<ProductProvider>();
                final success = await provider.submitDraftForReview(product);
                if (context.mounted) {
                  if (success) {
                    context.pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Product resubmitted for review successfully! 🎉'),
                        backgroundColor: Color(0xFF16A34A),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(provider.errorMessage ?? 'Failed to resubmit product.')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.send_rounded, size: 18),
              label: Text(
                isLiveProduct ? 'Resubmit Update' : 'Resubmit Product',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                backgroundColor: hasRemainingFixes ? const Color(0xFFF59E0B) : const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 12, color: Colors.grey.shade500),
              const SizedBox(width: 5),
              Text(
                'Re-review usually takes under 24 hours.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Center(
            child: InkWell(
              onTap: () => _showDeleteConfirmDialog(context, product, isLiveProduct),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  isLiveProduct ? 'Discard update & keep live store version' : 'Discard & delete this draft product',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 11,
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, ProductModel product, bool isLiveProduct) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isLiveProduct ? 'Discard Pending Update?' : 'Delete Draft Product?'),
        content: Text(
          isLiveProduct
              ? 'Are you sure you want to discard your pending changes? Your live product will continue selling on the store without interruption.'
              : 'Are you sure you want to delete this draft product? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final provider = context.read<ProductProvider>();
              final success = await provider.deleteProduct(product.productId);
              if (context.mounted) {
                if (success) {
                  context.pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isLiveProduct ? 'Pending update discarded.' : 'Draft product deleted.'),
                      backgroundColor: Colors.grey.shade800,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(provider.errorMessage ?? 'Failed to delete.')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: Text(isLiveProduct ? 'Discard Update' : 'Delete Draft'),
          ),
        ],
      ),
    );
  }
}
