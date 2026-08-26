import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
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
    String newStatus = available ? 'Live' : 'Unavailable';
    if (available) {
      if (['Under Review', 'Submitted', 'Update Under Review', 'Live + Update Pending', 'Draft', 'Changes Required'].contains(_product.status)) {
        return;
      }
      if (_product.pendingUpdate != null || _product.pendingReviewVersion != null) {
        newStatus = 'Live + Update Pending';
      }
    }
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

  Future<void> _toggleMasterStock(bool inStock) async {
    setState(() {
      final newVariants = _product.variants.map((v) => v.copyWith(isAvailable: inStock)).toList();
      _product = _product.copyWith(variants: newVariants);
    });
    final provider = context.read<ProductProvider>();
    await provider.updateOperationalFields(_product.productId, {
      'variants': _product.variants.map((e) => e.toJson()).toList(),
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(inStock ? 'All pack sizes marked In Stock 🟢' : 'All pack sizes marked Sold Out 🔴'),
          backgroundColor: inStock ? const Color(0xFF4CAF50) : const Color(0xFFC62828),
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
    if (widget.product.status == 'Changes Required') {
      final doc = await FirebaseFirestore.instance.collection('products').doc(widget.product.productId).get();
      final currentFixes = doc.exists ? List<String>.from(doc.data()!['requiredFixes'] ?? []) : widget.product.requiredFixes;
      if (currentFixes.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please address all required changes before resubmitting. Remaining: ${currentFixes.join(", ")}'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
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
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .doc(widget.product.productId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.exists) {
          final liveProduct = ProductModel.fromJson(snapshot.data!.data() as Map<String, dynamic>);
          _product = liveProduct.applyDraftUpdates();
        }
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            toolbarHeight: 68,
            centerTitle: false,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
              onPressed: () => context.pop(),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: InkWell(
                  onTap: () => ProductPreviewSheet.show(context, _product),
                  borderRadius: BorderRadius.circular(100),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.remove_red_eye_outlined, size: 16, color: Color(0xFF0F172A)),
                        SizedBox(width: 6),
                        Text('Preview', style: TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: InkWell(
                  onTap: () {
                    Share.share(
                      'Check out ${_product.name} on FreshGa!\n\nhttps://freshga-homemades.web.app/product/${_product.productId}',
                      subject: 'Check out this product!',
                    );
                  },
                  borderRadius: BorderRadius.circular(100),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Icon(Icons.share_outlined, color: Color(0xFF0F172A), size: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Manage Product', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w800, fontSize: 28, letterSpacing: -0.5)),
                const SizedBox(height: 4),
                const Padding(
                  padding: EdgeInsets.only(bottom: 24),
                  child: Text('View, edit & manage your product', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500, fontSize: 14)),
                ),
                _buildProductHeroHeader(),
                const SizedBox(height: 16),
                _buildPerformanceRibbon(),
                const SizedBox(height: 20),
                _buildQuickTogglesCard(),
                const SizedBox(height: 24),
                _buildInstantEditsGroup(),
                const SizedBox(height: 24),
                _buildAuditedDetailsGroup(),
                const SizedBox(height: 24),
                _buildProductAuditCard(),
                const SizedBox(height: 28),
                _buildDangerZone(),
                const SizedBox(height: 40),
              ],
            ),
          ),
          bottomNavigationBar: _buildBottomBar(),
        );
      },
    );
  }

  Widget _buildProductHeroHeader() {
    final isLiveProduct = _product.lastApprovedAt != null || _product.status.startsWith('Live') || _product.status == 'Approved';
    final displayStatus = isLiveProduct ? 'LIVE' : _product.status.toUpperCase();
    final statusColor = isLiveProduct ? const Color(0xFF16A34A) : _getStatusColor(_product.status);

    String dietaryLabel = 'Pure Veg';
    Color dietaryBg = Colors.white;
    Color dietaryText = const Color(0xFF16A34A);
    Color dietaryBorder = const Color(0xFF22C55E);
    if (_product.tags.contains('Non-Veg')) {
      dietaryLabel = 'Non-Veg';
      dietaryText = const Color(0xFFC62828);
      dietaryBorder = const Color(0xFFEF4444);
    } else if (_product.tags.contains('Vegan')) {
      dietaryLabel = 'Vegan';
      dietaryText = const Color(0xFF1565C0);
      dietaryBorder = const Color(0xFF3B82F6);
    } else if (_product.tags.contains('Contains Egg') || _product.tags.contains('Egg')) {
      dietaryLabel = 'Contains Egg';
      dietaryText = const Color(0xFFF57F17);
      dietaryBorder = const Color(0xFFF97316);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: _product.images.isNotEmpty
                      ? Image.network(_product.images.first, fit: BoxFit.cover)
                      : Container(color: Colors.grey.shade200, child: const Icon(Icons.image_not_supported, color: Colors.grey)),
                ),
              ),
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: dietaryBg,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: dietaryBorder, width: 1.2),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4, offset: const Offset(0, 2))],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.eco, size: 11, color: dietaryText),
                      const SizedBox(width: 4),
                      Text(dietaryLabel, style: TextStyle(fontSize: 10, color: dietaryText, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 6, height: 6, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Text(displayStatus, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        '${_product.variants.length} ${_product.variants.length == 1 ? "Variant" : "Variants"}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF475569), fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _product.name,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0F172A), height: 1.25),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _product.categoryName,
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Text(
                  _getPriceRange(),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF16A34A)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceRibbon() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildMetricCard(Icons.favorite_border, const Color(0xFFEF4444), const Color(0xFFFEF2F2), '${_product.likes}', 'Likes')),
            const SizedBox(width: 12),
            Expanded(child: _buildMetricCard(Icons.shopping_bag_outlined, const Color(0xFFF97316), const Color(0xFFFFF7ED), '${_product.totalOrders}', 'Orders')),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildMetricCard(Icons.visibility_outlined, const Color(0xFF3B82F6), const Color(0xFFEFF6FF), '${_product.likes * 8 + 42}', 'Views')),
            const SizedBox(width: 12),
            Expanded(child: _buildMetricCard(Icons.star_border, const Color(0xFFF59E0B), const Color(0xFFFEF9C3), _product.rating > 0 ? _product.rating.toStringAsFixed(1) : 'New', 'Rating')),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(IconData icon, Color iconColor, Color bgColor, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF0F172A), height: 1.1), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF64748B), height: 1.1), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTogglesCard() {
    final isAvailable = !['Unavailable', 'Hidden', 'Disabled by Admin', 'Archived', 'Vendor Suspended'].contains(_product.status);
    final isMasterInStock = _product.variants.any((v) => v.isAvailable);
    final activeVariantsCount = _product.variants.where((v) => v.isAvailable).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.bolt, color: Color(0xFF15803D), size: 18),
                const SizedBox(width: 4),
                const Text('QUICK STORE CONTROLS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF15803D), letterSpacing: 0.8)),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(6)),
              child: const Text('INSTANT APPLY', style: TextStyle(color: Color(0xFF15803D), fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF86EFAC), width: 1.3),
            boxShadow: [BoxShadow(color: const Color(0xFF22C55E).withOpacity(0.06), blurRadius: 14, offset: const Offset(0, 4))],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.storefront_outlined, color: Color(0xFF16A34A), size: 22),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Store Visibility', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF0F172A))),
                                SizedBox(height: 2),
                                Text('Show / Hide product on customer app', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Transform.scale(
                          scale: 0.95,
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
                        const SizedBox(height: 2),
                        Text(
                          isAvailable ? 'Live' : 'Hidden',
                          style: TextStyle(color: isAvailable ? const Color(0xFF16A34A) : const Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isMasterInStock ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isMasterInStock ? Icons.inventory_2_outlined : Icons.remove_circle_outline,
                              color: isMasterInStock ? const Color(0xFF16A34A) : const Color(0xFFEF4444),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('In Stock / Ready to Order', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF0F172A))),
                                const SizedBox(height: 2),
                                Text(
                                  isMasterInStock
                                      ? '$activeVariantsCount of ${_product.variants.length} pack sizes available'
                                      : 'All pack sizes marked Sold Out',
                                  style: TextStyle(color: isMasterInStock ? const Color(0xFF64748B) : const Color(0xFFEF4444), fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Transform.scale(
                      scale: 0.95,
                      child: CupertinoSwitch(
                        value: isMasterInStock,
                        activeColor: const Color(0xFF16A34A),
                        trackColor: Colors.red.shade200,
                        onChanged: (val) {
                          _toggleMasterStock(val);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInstantEditsGroup() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.bolt, color: Color(0xFF475569), size: 18),
            SizedBox(width: 4),
            Text('INSTANT SETTINGS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569), letterSpacing: 0.8)),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 3))],
          ),
          child: Column(
            children: [
              _buildModernSectionTile(
                icon: Icons.sell_outlined,
                iconBg: const Color(0xFFDCFCE7),
                iconColor: const Color(0xFF16A34A),
                title: 'Variants & Pricing',
                subtitle: '${_product.variants.length} pack sizes • Price: ${_getPriceRange()}',
                onTap: () => context.push('/edit-pricing', extra: _product),
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0), indent: 64),
              _buildModernSectionTile(
                icon: Icons.eco_outlined,
                iconBg: const Color(0xFFDCFCE7),
                iconColor: const Color(0xFF16A34A),
                title: 'Freshness & Preparation',
                subtitle: 'Shelf life: ${_product.shelfLife} • Dispatch: ${_product.dispatchTime}',
                onTap: () => context.push('/edit-optional-details', extra: _product),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAuditedDetailsGroup() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.shield_outlined, color: Color(0xFF475569), size: 18),
            SizedBox(width: 4),
            Text('CORE IDENTITY & DETAILS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569), letterSpacing: 0.8)),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 3))],
          ),
          child: Column(
            children: [
              _buildModernSectionTile(
                icon: Icons.image_outlined,
                iconBg: const Color(0xFFEFF6FF),
                iconColor: const Color(0xFF3B82F6),
                title: 'Product Photos',
                subtitle: '${_product.images.length} of 10 photos uploaded',
                requiresReview: true,
                onTap: () => context.push('/edit-photos', extra: _product),
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0), indent: 64),
              _buildModernSectionTile(
                icon: Icons.article_outlined,
                iconBg: const Color(0xFFEFF6FF),
                iconColor: const Color(0xFF3B82F6),
                title: 'Title & Description',
                subtitle: '${_product.name} • ${_product.description.isNotEmpty ? (_product.description.length > 35 ? "${_product.description.substring(0, 35)}..." : _product.description) : "Add description"}',
                requiresReview: true,
                onTap: () => context.push('/edit-product-info', extra: _product),
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0), indent: 64),
              _buildModernSectionTile(
                icon: Icons.local_offer_outlined,
                iconBg: const Color(0xFFEFF6FF),
                iconColor: const Color(0xFF3B82F6),
                title: 'Categories & Tags',
                subtitle: '${_product.categoryName} • ${_product.tags.isNotEmpty ? _product.tags.join(", ") : "${_product.subCategoryIds.length} subcategories"}',
                requiresReview: true,
                onTap: () => context.push('/edit-collections', extra: _product),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _handleSectionTap(VoidCallback onProceed) {
    final isLiveOrApproved = _product.lastApprovedAt != null || _product.status.startsWith('Live');
    final hasPendingOrChanges = _product.status == 'Under Review' || 
                                _product.status == 'Live + Update Pending' || 
                                _product.status == 'Update Under Review' || 
                                _product.status == 'Changes Required';

    if (isLiveOrApproved && hasPendingOrChanges) {
      _showWithdrawBeforeEditingDialog(onProceed);
    } else {
      onProceed();
    }
  }

  void _showWithdrawBeforeEditingDialog(VoidCallback onProceed) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Active Submission',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E293B)),
              ),
            ),
          ],
        ),
        content: const Text(
          'This product already has changes in "Under Review" or "Changes Required".\n\nTo make new changes to this live product, please withdraw your existing review submission first.',
          style: TextStyle(color: Color(0xFF475569), height: 1.5, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final provider = context.read<ProductProvider>();
              final success = await provider.withdrawSubmission(_product);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Old submission withdrawn. Ready for new edits! ⚡'),
                    backgroundColor: Color(0xFF16A34A),
                  ),
                );
                onProceed();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Withdraw & Edit', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildModernSectionTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool requiresReview = false,
  }) {
    return InkWell(
      onTap: () => requiresReview ? _handleSectionTap(onTap) : onTap(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF0F172A)), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(subtitle, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Color(0xFF94A3B8), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildProductAuditCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('PRODUCT INFO', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569), letterSpacing: 0.8)),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 3))],
          ),
          child: Column(
            children: [
              _buildProductInfoRow(
                icon: Icons.calendar_today_outlined,
                iconBg: const Color(0xFFDCFCE7),
                iconColor: const Color(0xFF16A34A),
                label: 'Status',
                valueWidget: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF16A34A), shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(_product.status, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0), indent: 64),
              _buildProductInfoRow(
                icon: Icons.tag,
                iconBg: const Color(0xFFF1F5F9),
                iconColor: const Color(0xFF475569),
                label: 'Product ID',
                value: _product.productId.length > 8 ? 'FGP-${_product.productId.substring(0, 8).toUpperCase()}' : _product.productId,
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0), indent: 64),
              _buildProductInfoRow(
                icon: Icons.event_outlined,
                iconBg: const Color(0xFFF1F5F9),
                iconColor: const Color(0xFF475569),
                label: 'Created On',
                value: _formatDate(_product.createdAt),
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0), indent: 64),
              _buildProductInfoRow(
                icon: Icons.access_time_outlined,
                iconBg: const Color(0xFFF1F5F9),
                iconColor: const Color(0xFF475569),
                label: 'Last Updated',
                value: _formatDate(_product.updatedAt),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductInfoRow({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    String? value,
    Widget? valueWidget,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 14, fontWeight: FontWeight.w500)),
          ),
          if (valueWidget != null)
            valueWidget
          else
            Text(value ?? '', style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildDangerZone() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('DANGER ZONE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFEF4444), letterSpacing: 0.8)),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFCA5A5), width: 1.5),
            boxShadow: [BoxShadow(color: const Color(0xFFEF4444).withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 3))],
          ),
          child: Column(
            children: [
              _buildDangerTile(
                icon: Icons.delete_outline,
                title: 'Delete Product',
                subtitle: 'Permanently erase product and all variant data',
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
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: const Color(0xFFEF4444), size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF0F172A))),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFFCA5A5), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final status = widget.product.status;
    if (widget.product.lastApprovedAt != null || 
        status.startsWith('Live') || 
        status == 'Changes Required' || 
        status == 'Approved') {
      return const SizedBox.shrink();
    }

    final isDraft = status == 'Draft';
    final isPending = status == 'Under Review' || status == 'Update Under Review';

    if (!isDraft && !isPending) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, -4))],
      ),
      child: isDraft 
        ? InkWell(
            onTap: _isSaving ? null : _handleSubmitReview,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: const Color(0xFF4F46E5).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: _isSaving 
                  ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
                  : const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send_outlined, color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text('Submit for Review', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                          ],
                        ),
                        SizedBox(height: 2),
                        Text('Submit changes to admin for approval', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w400)),
                      ],
                    ),
            ),
          )
        : ElevatedButton(
            onPressed: _isSaving ? null : _handleWithdraw,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: _isSaving 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.error, strokeWidth: 2))
                : const Text('Withdraw Submission', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          ),
    );
  }
}

