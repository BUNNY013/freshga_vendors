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
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 70,
        centerTitle: false,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
          onPressed: () => context.pop(),
        ),
        title: const Text('Manage Product', style: TextStyle(color: Color(0xFF1F2937), fontWeight: FontWeight.w600, fontSize: 20)),
        actions: [
          _buildAppbarAction(Icons.remove_red_eye_outlined, 'Preview', () => ProductPreviewSheet.show(context, _product)),
          _buildAppbarAction(Icons.share_outlined, 'Share', () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product link copied!')));
          }),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroCard(),
            const SizedBox(height: 16),
            _buildProductSections(),
            const SizedBox(height: 16),
            _buildAvailabilityCard(),
            const SizedBox(height: 16),
            _buildProductStatus(),
            const SizedBox(height: 16),
            _buildDangerZone(),
            const SizedBox(height: 40),
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
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 100,
                        height: 100,
                        child: _product.images.isNotEmpty
                            ? Image.network(_product.images.first, fit: BoxFit.cover)
                            : Container(color: Colors.grey.shade200, child: const Icon(Icons.image_not_supported, color: Colors.grey)),
                      ),
                    ),

                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _product.name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF111827), height: 1.2),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(width: 6, height: 6, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Text(_product.status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _product.categoryName,
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w400),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getPriceRange(),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            height: 28,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(14)),
                            alignment: Alignment.center,
                            child: Row(
                              children: [
                                const Icon(Icons.sell_outlined, size: 12, color: Color(0xFF374151)),
                                const SizedBox(width: 4),
                                Text('${_product.variants.length} Variants', style: const TextStyle(fontSize: 12, color: Color(0xFF374151), fontWeight: FontWeight.w500)),
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
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem(Icons.favorite, const Color(0xFFFEF2F2), const Color(0xFFEF4444), '${_product.likes}', 'Likes'),
                _buildStatItem(Icons.inventory_2_outlined, const Color(0xFFFFF7ED), const Color(0xFFF97316), '${_product.totalOrders}', 'Orders'),
                _buildStatItem(Icons.remove_red_eye_outlined, const Color(0xFFEFF6FF), const Color(0xFF3B82F6), '${_product.likes * 8 + 42}', 'Views'),
                _buildStatItem(Icons.star_border, const Color(0xFFFEF9C3), const Color(0xFFEAB308), '4.8', 'Rating'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, Color bgColor, Color iconColor, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF111827))),
        Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w400)),
      ],
    );
  }



  Widget _buildProductSections() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Product Sections', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(
            children: [
              _buildSectionTile(
                icon: Icons.image_outlined,
                title: 'Product Photos',
                subtitle: '${_product.images.length} photos added',
                status: '${_product.images.length} / 10',
                statusColor: const Color(0xFF64748B),
                onTap: () => context.push('/edit-photos', extra: _product),
              ),
              const Divider(height: 1, color: Color(0xFFE5E7EB), indent: 72),
              _buildSectionTile(
                icon: Icons.article_outlined,
                title: 'Product Information',
                subtitle: 'Name, description & more',
                status: 'Complete',
                statusColor: const Color(0xFF16A34A),
                onTap: () => context.push('/edit-product-info', extra: _product),
              ),
              const Divider(height: 1, color: Color(0xFFE5E7EB), indent: 72),
              _buildSectionTile(
                icon: Icons.local_offer_outlined,
                title: 'Categories',
                subtitle: '${_product.categoryName} • ${_product.subCategoryIds.isNotEmpty ? "Subcategories" : "General"}',
                status: '${_product.subCategoryIds.length + 1} Selected',
                statusColor: const Color(0xFF16A34A),
                onTap: () => context.push('/edit-collections', extra: _product),
              ),
              const Divider(height: 1, color: Color(0xFFE5E7EB), indent: 72),
              _buildSectionTile(
                icon: Icons.inventory_2_outlined,
                title: 'Variants & Pricing',
                subtitle: '${_product.variants.length} variants configured',
                status: '${_product.variants.length} Variants',
                statusColor: const Color(0xFF16A34A),
                onTap: () => context.push('/edit-pricing', extra: _product),
              ),
              const Divider(height: 1, color: Color(0xFFE5E7EB), indent: 72),
              _buildSectionTile(
                icon: Icons.local_shipping_outlined,
                title: 'Others',
                subtitle: 'Ingredients, shelf life, dispatch time & more',
                status: 'Configured',
                statusColor: const Color(0xFF16A34A),
                onTap: () => context.push('/edit-optional-details', extra: _product),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String status,
    required Color statusColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9), // Light grey background
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF16A34A), size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF111827)), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w400), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Text(status, style: TextStyle(color: statusColor, fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Color(0xFF64748B), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailabilityCard() {
    final isAvailable = _product.status == 'Live';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Availability', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF111827))),
              SizedBox(height: 4),
              Text('Show product on store', style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w400)),
            ],
          ),
          Transform.scale(
            scale: 0.9,
            child: CupertinoSwitch(
              value: isAvailable,
              activeColor: const Color(0xFF16A34A),
              trackColor: Colors.grey.shade300,
              onChanged: (val) {
                if (val != isAvailable) {
                  _confirmToggleAvailability(val);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductStatus() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Product Status', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(
            children: [
              _buildStatusRow('Status', _product.status, isStatus: true),
              const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, color: Color(0xFFE5E7EB))),
              _buildStatusRow('Created On', _formatDate(_product.createdAt)),
              const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, color: Color(0xFFE5E7EB))),
              _buildStatusRow('Last Updated', _formatDate(_product.updatedAt)),
              const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, color: Color(0xFFE5E7EB))),
              _buildStatusRow('Product ID', _product.productId.length > 6 ? 'FGP${_product.productId.substring(0, 6).toUpperCase()}' : _product.productId),
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
        Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500)),
        if (isStatus)
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: value == 'Live' ? const Color(0xFF16A34A) : const Color(0xFFF59E0B), shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(value, style: const TextStyle(color: Color(0xFF111827), fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          )
        else
          Text(value, style: const TextStyle(color: Color(0xFF111827), fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildAppbarAction(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF1F2937), size: 20),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildDangerZone() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Danger Zone', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(
            children: [
              _buildDangerTile(
                icon: Icons.archive_outlined,
                title: 'Archived Product',
                subtitle: 'Hide from store temporarily',
                onTap: _handleArchive,
              ),
              const Divider(height: 1, color: Color(0xFFE5E7EB), indent: 72),
              _buildDangerTile(
                icon: Icons.delete_outline,
                title: 'Delete Product',
                subtitle: 'Permanently remove product',
                onTap: _handleDelete,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDangerTile({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: const Color(0xFFEF4444), size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFFEF4444))),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w400)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}
