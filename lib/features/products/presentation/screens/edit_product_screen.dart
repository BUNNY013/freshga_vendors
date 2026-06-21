import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/product_model.dart';
import '../providers/product_provider.dart';
import '../widgets/product_preview_sheet.dart';

class EditProductScreen extends StatefulWidget {
  final ProductModel product;

  const EditProductScreen({super.key, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  late ProductModel _product;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _product = widget.product.applyDraftUpdates();
  }

  Future<void> _handleDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product'),
        content: const Text('Are you sure you want to delete this product? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textPrimary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isSaving = true);
      final provider = context.read<ProductProvider>();
      final success = await provider.deleteProduct(_product.productId);
      if (mounted) {
        setState(() => _isSaving = false);
        if (success) {
          context.pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete product')),
          );
        }
      }
    }
  }

  Future<void> _handleArchive() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Archive Product'),
        content: const Text('Are you sure you want to archive this product? It will be hidden from customers, but kept in your records.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textPrimary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade800),
            child: const Text('Archive', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isSaving = true);
      final provider = context.read<ProductProvider>();
      await provider.updateProductStatus(_product.productId, 'Archived');
      if (mounted) {
        setState(() {
          _product = _product.copyWith(status: 'Archived');
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product Archived')),
        );
      }
    }
  }

  Future<void> _confirmToggleAvailability(bool makeAvailable) async {
    final title = makeAvailable ? 'Make Product Available?' : 'Make Product Unavailable?';
    final content = makeAvailable 
      ? 'This product will become visible to customers and they can start ordering it.'
      : 'This product will be hidden from the customer app. Existing orders will not be affected.';
      
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: Text(content, style: const TextStyle(fontSize: 14)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: makeAvailable ? const Color(0xFF4CAF50) : const Color(0xFFF57F17),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
            ),
            child: Text(makeAvailable ? 'Make Available' : 'Make Unavailable', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _toggleAvailability(makeAvailable);
    }
  }

  Future<void> _toggleAvailability(bool available) async {
    final newStatus = available ? 'Live' : 'Unavailable';
    if (_product.status == newStatus) return;

    setState(() {
      _product = _product.copyWith(status: newStatus);
    });

    final provider = context.read<ProductProvider>();
    await provider.updateProductStatus(_product.productId, newStatus);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(available ? 'Product is now Available' : 'Product is now Unavailable'),
          backgroundColor: available ? const Color(0xFF4CAF50) : const Color(0xFFF57F17),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _getPriceRange() {
    if (_product.variants.isEmpty) return '₹${_product.price.toStringAsFixed(0)}';
    final prices = _product.variants.map((v) => v.price).toList();
    prices.sort();
    if (prices.first == prices.last) return '₹${prices.first.toStringAsFixed(0)}';
    return '₹${prices.first.toStringAsFixed(0)} - ₹${prices.last.toStringAsFixed(0)}';
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate).toLocal();
      const monthNames = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      final month = monthNames[date.month - 1];
      return '${date.day} $month, ${date.year}';
    } catch (_) {
      return 'Unknown';
    }
  }

  Future<void> _handleSubmitReview() async {
    if (_product.requiredFixes.isNotEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please address all required fixes before submitting.')));
       return;
    }

    setState(() => _isSaving = true);
    final provider = context.read<ProductProvider>();
    final success = await provider.submitDraftForReview(widget.product);
    
    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product submitted for review!')));
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage ?? 'Failed to submit')));
      }
    }
  }

  Future<void> _handleWithdraw() async {
    setState(() => _isSaving = true);
    final provider = context.read<ProductProvider>();
    final success = await provider.withdrawSubmission(widget.product);
    
    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Submission withdrawn. Moved to drafts.')));
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage ?? 'Failed to withdraw')));
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Live':
        return const Color(0xFF4CAF50);
      case 'Draft':
      case 'Live + Draft Changes':
        return Colors.grey;
      case 'Under Review':
      case 'Submitted':
      case 'Update Under Review':
      case 'Live + Update Pending':
        return Colors.blue;
      case 'Changes Required':
        return Colors.red;
      case 'Unavailable':
      case 'Hidden':
        return const Color(0xFFF57F17);
      case 'Archived':
        return Colors.grey.shade800;
      case 'Vendor Suspended':
        return Colors.deepPurple;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAFB),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Edit Product',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w900, fontSize: 18),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 10, bottom: 10),
            child: OutlinedButton.icon(
              onPressed: () => ProductPreviewSheet.show(context, _product),
              icon: const Icon(Icons.remove_red_eye_outlined, size: 16, color: AppColors.primary),
              label: const Text('Preview', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                backgroundColor: AppColors.primary.withOpacity(0.05),
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroCard(),
            const SizedBox(height: 32),
            _buildQuickActions(),
            const SizedBox(height: 32),
            _buildProductSections(),
            const SizedBox(height: 32),
            _buildProductStatus(),
            const SizedBox(height: 32),
            _buildHelpCard(),
            const SizedBox(height: 32),
            _buildMoreActions(),
            const SizedBox(height: 100), // padding for bottom bar
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBottomBar() {
    final status = widget.product.status;
    final isDraft = status == 'Draft' || status == 'Live + Draft Changes' || status == 'Changes Required';
    final isPending = status == 'Under Review' || status == 'Live + Update Pending' || status == 'Update Under Review';

    if (!isDraft && !isPending) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: isDraft 
        ? ElevatedButton(
            onPressed: _isSaving ? null : _handleSubmitReview,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isSaving 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Submit for Review', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          )
        : ElevatedButton(
            onPressed: _isSaving ? null : _handleWithdraw,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isSaving 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.error, strokeWidth: 2))
                : const Text('Withdraw Submission', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
    );
  }

  Widget _buildHeroCard() {
    final statusColor = _getStatusColor(_product.status);
    
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: 140,
                height: 140,
                child: _product.images.isNotEmpty
                    ? Image.network(_product.images.first, fit: BoxFit.cover)
                    : Container(color: Colors.grey.shade200, child: const Icon(Icons.image_not_supported, color: Colors.grey)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _product.name,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textPrimary, height: 1.2),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 6, height: 6, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text(_product.status, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _product.categoryName,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.textPrimary),
                  ),
                  if (_product.subCategoryIds.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${_product.subCategoryIds.length} Subcategories',
                      style: const TextStyle(color: AppColors.grey500, fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    _getPriceRange(),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_product.variants.length} Variants',
                    style: const TextStyle(color: AppColors.grey500, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(Icons.favorite_border, Colors.red, '${_product.likes}', 'Likes'),
              Container(width: 1, height: 30, color: const Color(0xFFF0F0F0)),
              _buildStatItem(Icons.inventory_2_outlined, Colors.brown, '${_product.totalOrders}', 'Orders'),
              Container(width: 1, height: 30, color: const Color(0xFFF0F0F0)),
              _buildStatItem(Icons.remove_red_eye_outlined, const Color(0xFF607D8B), '${_product.likes * 8 + 42}', 'Views'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, Color iconColor, String value, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: iconColor.withOpacity(0.8), size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.textPrimary)),
            Text(label, style: const TextStyle(color: AppColors.grey500, fontSize: 11, fontWeight: FontWeight.w500)),
          ],
        )
      ],
    );
  }

  Widget _buildQuickActions() {
    final isAvailable = _product.status == 'Live';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildAvailabilityCard(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.remove_red_eye_outlined,
                title: 'View Product',
                subtitle: 'See live page',
                color: Colors.blue,
                onTap: () => ProductPreviewSheet.show(context, _product),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.share_outlined,
                title: 'Share Product',
                subtitle: 'Share link',
                color: const Color(0xFF673AB7),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product link copied!')));
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAvailabilityCard() {
    final isAvailable = _product.status == 'Live';
    final color = isAvailable ? const Color(0xFF4CAF50) : const Color(0xFFF57F17);
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 44, // Match icon container height
            child: Center(
              child: Transform.scale(
                scale: 0.9,
                child: CupertinoSwitch(
                  value: isAvailable,
                  activeColor: const Color(0xFF4CAF50),
                  trackColor: Colors.grey.shade300,
                  onChanged: (val) {
                    if (val != isAvailable) {
                      _confirmToggleAvailability(val);
                    }
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(isAvailable ? 'Available' : 'Unavailable', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: color)),
          const SizedBox(height: 4),
          Text(isAvailable ? 'Product is live' : 'Hidden from shop', style: const TextStyle(color: AppColors.grey500, fontSize: 10, fontWeight: FontWeight.w500), textAlign: TextAlign.center, maxLines: 1),
        ],
      ),
    );
  }

  Widget _buildActionCard({required IconData icon, required String title, required String subtitle, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))]),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 16),
            Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: color)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: AppColors.grey500, fontSize: 10, fontWeight: FontWeight.w500), textAlign: TextAlign.center, maxLines: 1),
          ],
        ),
      ),
    );
  }

  Widget _buildProductSections() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Product Sections', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF0F0F0)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            children: [
              _buildSectionTile(
                icon: Icons.image_outlined,
                title: 'Product Photos',
                subtitle: '${_product.images.length} photos',
                onTap: () => context.push('/edit-photos', extra: _product),
              ),
              const Divider(height: 1, color: Color(0xFFF0F0F0), indent: 56),
              _buildSectionTile(
                icon: Icons.article_outlined,
                title: 'Product Information',
                subtitle: 'Name, description & more',
                onTap: () => context.push('/edit-product-info', extra: _product),
              ),
              const Divider(height: 1, color: Color(0xFFF0F0F0), indent: 56),
              _buildSectionTile(
                icon: Icons.local_offer_outlined,
                title: 'Categories & Collections',
                subtitle: _product.categoryName,
                onTap: () => context.push('/edit-collections', extra: _product),
              ),
              const Divider(height: 1, color: Color(0xFFF0F0F0), indent: 56),
              _buildSectionTile(
                icon: Icons.inventory_2_outlined,
                title: 'Variants & Pricing',
                subtitle: '${_product.variants.length} variants',
                onTap: () => context.push('/edit-pricing', extra: _product),
              ),
              const Divider(height: 1, color: Color(0xFFF0F0F0), indent: 56),
              _buildSectionTile(
                icon: Icons.kitchen_outlined,
                title: 'Ingredients & Storage',
                subtitle: 'Ingredients, shelf life, storage',
                onTap: () => context.push('/edit-optional-details', extra: _product),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTile({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.primaryLight.withOpacity(0.3), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: AppColors.grey500, fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.grey400, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildProductStatus() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Product Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF0F0F0)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            children: [
              _buildStatusRow('Status', _product.status, isStatus: true),
              const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, color: Color(0xFFF0F0F0))),
              _buildStatusRow('Created On', _formatDate(_product.createdAt)),
              const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, color: Color(0xFFF0F0F0))),
              _buildStatusRow('Last Updated', _formatDate(_product.updatedAt)),
              const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, color: Color(0xFFF0F0F0))),
              _buildStatusRow('Product ID', 'FGP${_product.productId.substring(0, 6).toUpperCase()}'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRow(String label, String value, {bool isStatus = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.grey600, fontSize: 13, fontWeight: FontWeight.w600)),
        if (isStatus)
          Row(
            children: [
              Container(width: 6, height: 6, decoration: BoxDecoration(color: _getStatusColor(value), shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textPrimary)),
            ],
          )
        else
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildHelpCard() {
    if (_product.requiredFixes.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.error.withOpacity(0.2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const Icon(Icons.error_outline, color: AppColors.error, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Changes Required', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.error)),
                  const SizedBox(height: 4),
                  Text('Please fix the following sections before resubmitting:\n\n${_product.requiredFixes.join(', ')}', style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600, height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF4FAF5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8F5E9)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)]),
            child: const Icon(Icons.lightbulb_outline, color: Color(0xFFFBC02D), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Need help?', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                const Text('Learn how to optimize your product for more visibility and sales.', style: TextStyle(color: AppColors.grey600, fontSize: 13, fontWeight: FontWeight.w500, height: 1.4)),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Guide opening soon...')));
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('View Guide', style: TextStyle(fontWeight: FontWeight.w800)),
                      SizedBox(width: 4),
                      Icon(Icons.keyboard_arrow_down, size: 18)
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoreActions() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0F0F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: const Text('More Actions', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textPrimary)),
          childrenPadding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
          children: [
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.archive_outlined, color: Colors.grey.shade800, size: 20),
              ),
              title: Text('Archive Product', style: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.w800, fontSize: 14)),
              subtitle: Text('Hide from customers, keep in records', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
              contentPadding: EdgeInsets.zero,
              onTap: _handleArchive,
            ),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
              ),
              title: const Text('Delete Product', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w800, fontSize: 14)),
              subtitle: const Text('This action cannot be undone', style: TextStyle(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.w500)),
              contentPadding: EdgeInsets.zero,
              onTap: _handleDelete,
            ),
          ],
        ),
      ),
    );
  }
}
