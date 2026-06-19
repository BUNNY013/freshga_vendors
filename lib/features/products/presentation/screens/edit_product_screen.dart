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
    _product = widget.product;
  }

  void _showNotImplemented(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Navigation to $title coming in next phase!')),
    );
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

  Future<void> _toggleAvailability(bool value) async {
    final provider = context.read<ProductProvider>();
    final newStatus = value ? 'Live' : 'Unavailable';
    await provider.updateProductStatus(_product.productId, newStatus);
    
    // For immediate UI update without copyWith, we'll just wait for the stream 
    // or pop, but let's assume we want to stay on the screen.
    // In a real app we'd use a copyWith method here.
  }

  @override
  Widget build(BuildContext context) {
    final isLive = _product.status == 'Live';
    final isReviewing = _product.status == 'Under Review' || _product.status == 'Update Under Review';
    final isDraft = _product.status == 'Draft';
    final isChangesRequired = _product.status == 'Changes Required';
    
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
            Text(
              'Edit Product',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
            Text(
              'Manage your product details',
              style: TextStyle(
                color: AppColors.grey500,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.visibility_outlined, color: AppColors.textPrimary),
            onPressed: () {
              ProductPreviewSheet.show(context, _product);
            },
            tooltip: 'Customer View',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Top Profile Card
            _buildProductProfileCard(),
            const SizedBox(height: 16),

            // 2. Menu Sections

            // 3. Menu Sections
            _buildMenuSection(),
            const SizedBox(height: 24),

            // 4. Advanced Actions
            const Text(
              'Advanced Actions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _buildAdvancedActionsSection(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProductProfileCard() {
    final isLive = _product.status == 'Live';
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: Stack(
                    children: [
                      _product.images.isNotEmpty
                          ? Image.network(_product.images.first, fit: BoxFit.cover, width: 100, height: 100)
                          : Container(color: Colors.grey.shade200),
                      Positioned(
                        top: 6, left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(4)),
                          child: Text(_product.status, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _product.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary, height: 1.2),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          width: 8, height: 8,
                          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Text('${_product.status} Product', style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: Color(0xFFF0F0F0)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(Icons.favorite, Colors.red, '${_product.likes}', 'Likes'),
              Container(width: 1, height: 30, color: const Color(0xFFF0F0F0)),
              _buildStatItem(Icons.inventory_2_outlined, Colors.brown, '${_product.totalOrders}', 'Orders'),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, Color iconColor, String value, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            Text(label, style: const TextStyle(color: AppColors.grey500, fontSize: 12)),
          ],
        )
      ],
    );
  }

  Widget _buildMenuSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.image_outlined,
            title: 'Product Photos',
            subtitle: '${_product.images.length} photos uploaded',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(100)),
              child: Text('${_product.images.length}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.grey600)),
            ),
            onTap: () => context.push('/edit-photos', extra: _product),
          ),
          const Divider(height: 1, color: Color(0xFFF0F0F0), indent: 56),
          _buildMenuItem(
            icon: Icons.article_outlined,
            title: 'Product Information',
            subtitle: 'Name, description & more',
            onTap: () => context.push('/edit-product-info', extra: _product),
          ),
          const Divider(height: 1, color: Color(0xFFF0F0F0), indent: 56),
          _buildMenuItem(
            icon: Icons.local_offer_outlined,
            title: 'Collections & Categories',
            subtitle: '${_product.categoryName} • ${_product.subCategoryIds.length} subcategories',
            onTap: () => context.push('/edit-collections', extra: _product),
          ),
          const Divider(height: 1, color: Color(0xFFF0F0F0), indent: 56),
          _buildMenuItem(
            icon: Icons.inventory_2_outlined,
            title: 'Pack Sizes & Pricing',
            subtitle: '${_product.variants.length} pack sizes',
            onTap: () => context.push('/edit-pricing', extra: _product),
          ),
          const Divider(height: 1, color: Color(0xFFF0F0F0), indent: 56),
          _buildMenuItem(
            icon: Icons.settings_outlined,
            title: 'Others',
            subtitle: 'Ingredients, shelf life, storage & more',
            onTap: () => context.push('/edit-optional-details', extra: _product),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    required VoidCallback onTap,
    Color? iconColor,
    Color? bgColor,
    Color? textColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: bgColor ?? const Color(0xFFF4FAF5), shape: BoxShape.circle),
              child: Icon(icon, color: iconColor ?? AppColors.primary, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor ?? AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(color: textColor?.withOpacity(0.7) ?? AppColors.grey500, fontSize: 13)),
                ],
              ),
            ),
            if (trailing != null) ...[
              trailing,
              const SizedBox(width: 8),
            ],
            const Icon(Icons.chevron_right, color: AppColors.grey400),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedActionsSection() {
    final isLive = _product.status == 'Live';
    
    // A product is considered "New" if it's a Draft, Under Review, or a Changes Required without any pending updates.
    // If it's an existing live product that got an update rejected, it will have pendingUpdate.
    final isNewProduct = _product.status == 'Draft' || 
                         _product.status == 'Under Review' || 
                         _product.status == 'Submitted' ||
                         (_product.status == 'Changes Required' && (_product.pendingUpdate == null || _product.pendingUpdate!.isEmpty));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          if (!isNewProduct) ...[
            // Availability Toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(color: Color(0xFFF4FAF5), shape: BoxShape.circle),
                    child: const Icon(Icons.power_settings_new, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Availability', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
                        SizedBox(height: 2),
                        Text('Show product to customers', style: TextStyle(color: AppColors.grey500, fontSize: 13)),
                      ],
                    ),
                  ),
                  CupertinoSwitch(
                    value: isLive,
                    activeColor: AppColors.primary,
                    onChanged: _toggleAvailability,
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF0F0F0), indent: 56),
            
            // Save as Draft
            _buildMenuItem(
              icon: Icons.insert_drive_file_outlined,
              title: 'Save as Draft',
              subtitle: 'Unpublish and save to drafts',
              onTap: () => _showNotImplemented('Save as Draft'),
            ),
            const Divider(height: 1, color: Color(0xFFF0F0F0), indent: 56),
          ],
          
          // Delete
          _buildMenuItem(
            icon: Icons.delete_outline,
            iconColor: const Color(0xFFD32F2F),
            bgColor: const Color(0xFFFFF5F5),
            textColor: const Color(0xFFD32F2F),
            title: 'Delete Product',
            subtitle: 'This action cannot be undone',
            onTap: _isSaving ? () {} : _handleDelete,
            trailing: _isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : null,
          ),
        ],
      ),
    );
  }
}
