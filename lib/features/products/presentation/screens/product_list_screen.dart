import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../providers/product_provider.dart';
import '../../../../data/models/product_model.dart';
import '../../../../data/models/user_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../widgets/product_card.dart';
import '../widgets/product_actions_sheet.dart';
import '../widgets/product_preview_sheet.dart';

class ProductListScreen extends StatelessWidget {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProductProvider(),
      child: const _ProductListContent(),
    );
  }
}

class _ProductListContent extends StatefulWidget {
  const _ProductListContent();

  @override
  State<_ProductListContent> createState() => _ProductListContentState();
}

class _ProductListContentState extends State<_ProductListContent> {
  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late Future<DocumentSnapshot> _userFuture;
  Stream<List<ProductModel>>? _productsStream;
  String? _storeId;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? '';
    _userFuture = FirebaseFirestore.instance.collection('users').doc(userId).get();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 80,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Products',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 26,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              'Manage your products',
              style: TextStyle(
                color: AppColors.grey500,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-product'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Product',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
        ),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _userFuture,
        builder: (context, userSnap) {
          if (!userSnap.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final userModel =
              UserModel.fromJson(userSnap.data!.data() as Map<String, dynamic>);
          final storeId = userModel.storeId;

          if (storeId.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: _buildEmptyState(
                  icon: Icons.store_outlined,
                  title: "Set up your store first",
                  subtitle: "You need to create your store before adding products.",
                  buttonText: "Go to Store",
                  onAction: () => context.push('/store'),
                ),
              ),
            );
          }

          if (_storeId != storeId) {
            _storeId = storeId;
            _productsStream = context.read<ProductProvider>().streamProducts(storeId);
          }

          return StreamBuilder<List<ProductModel>>(
            stream: _productsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: AppColors.error),
                        const SizedBox(height: 16),
                        Text(
                          'Something went wrong',
                          style: AppTextStyles.h3,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: AppColors.grey600, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final allProducts = snapshot.data ?? [];

              if (allProducts.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: _buildEmptyState(
                      icon: Icons.fastfood_rounded,
                      title: "Your food journey starts here 🚀",
                      subtitle:
                          "Add your first homemade product and start building your brand.",
                      buttonText: "Add First Product",
                      onAction: () => context.push('/add-product'),
                    ),
                  ),
                );
              }

              // Compute counts for filters
              final allCount = allProducts.length;
              final liveCount = allProducts.where((p) => p.status == 'Live').length;
              final reviewCount = allProducts.where((p) => p.status == 'Under Review').length;
              final changesCount = allProducts.where((p) => p.status == 'Changes Required').length;
              final draftCount = allProducts.where((p) => p.status == 'Draft').length;
              final unavailableCount = allProducts.where((p) => p.status == 'Unavailable').length;

              // Apply filters
              var products = List<ProductModel>.from(allProducts);

              if (_searchQuery.isNotEmpty) {
                products = products
                    .where((p) => p.name
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase()))
                    .toList();
              }

              if (_selectedFilter != 'All') {
                products = products.where((p) => p.status == _selectedFilter).toList();
              }

              // Group by category
              final Map<String, List<ProductModel>> groupedProducts = {};
              for (var p in products) {
                final cat = p.categoryName.isEmpty ? 'Other' : p.categoryName;
                if (!groupedProducts.containsKey(cat)) {
                  groupedProducts[cat] = [];
                }
                groupedProducts[cat]!.add(p);
              }
              
              final sortedCategories = groupedProducts.keys.toList()..sort();

              return Column(
                children: [


                  // Horizontal Filter Chips Scroll
                  SizedBox(
                    height: 44,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _buildFilterChip("All", allCount),
                        _buildFilterChip("Live", liveCount),
                        _buildFilterChip("Under Review", reviewCount),
                        _buildFilterChip("Changes Required", changesCount),
                        _buildFilterChip("Draft", draftCount),
                        _buildFilterChip("Unavailable", unavailableCount),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Warning Card for Changes Required
                  if (_selectedFilter == 'Changes Required' && products.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildWarningCard(),
                    ),

                  // Products List
                  Expanded(
                    child: products.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: _buildFilteredEmptyState(),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 100, top: 4),
                            itemCount: sortedCategories.length,
                            itemBuilder: (context, index) {
                              final category = sortedCategories[index];
                              final categoryProducts = groupedProducts[category]!;
                              
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8, bottom: 16),
                                    child: Text(
                                      category,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  ...categoryProducts.map((p) => _buildProductCard(p)),
                                  const SizedBox(height: 16),
                                ],
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildWarningCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3F3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFCDCD)),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Color(0xFFD32F2F), size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '⚠ Some products need changes',
                  style: TextStyle(color: Color(0xFFD32F2F), fontWeight: FontWeight.bold, fontSize: 14),
                ),
                SizedBox(height: 2),
                Text(
                  'Review feedback and resubmit.',
                  style: TextStyle(color: Color(0xFFC62828), fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilteredEmptyState() {
    if (_searchQuery.isNotEmpty) {
      return _buildEmptyState(
        icon: Icons.search_off_rounded,
        title: "No matches found",
        subtitle: "We couldn't find any products matching '$_searchQuery'.",
        buttonText: "Clear Search",
        onAction: () {
          _searchController.clear();
          setState(() {
            _searchQuery = '';
          });
        },
      );
    }

    switch (_selectedFilter) {
      case 'Live':
        return _buildEmptyState(
          icon: Icons.storefront_outlined,
          title: "No Live Products",
          subtitle: "Products that have been approved and are visible to your customers will appear here.",
          color: const Color(0xFF198754), // Success Green
        );
      case 'Under Review':
        return _buildEmptyState(
          icon: Icons.hourglass_empty_rounded,
          title: "Nothing Under Review",
          subtitle: "You have no products currently pending approval. Submit a draft to see it here.",
          color: const Color(0xFFF57C00), // Orange
        );
      case 'Changes Required':
        return _buildEmptyState(
          icon: Icons.check_circle_outline_rounded,
          title: "All Clear!",
          subtitle: "None of your products require changes. Great job maintaining high quality!",
          color: const Color(0xFF198754), // Green
        );
      case 'Draft':
        return _buildEmptyState(
          icon: Icons.edit_document,
          title: "No Drafts Found",
          subtitle: "Drafts are incomplete products that haven't been submitted for review yet.",
          color: AppColors.primary,
        );
      case 'Unavailable':
        return _buildEmptyState(
          icon: Icons.inventory_2_outlined,
          title: "Everything is Available",
          subtitle: "None of your products are currently paused or out of stock.",
          color: const Color(0xFF198754), // Green
        );
      default:
        return _buildEmptyState(
          icon: Icons.inventory_2_outlined,
          title: "No products found",
          subtitle: "Try adjusting your search or filters.",
        );
    }
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    String? buttonText,
    VoidCallback? onAction,
    Color color = AppColors.primary,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 64, color: color),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.grey600,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            if (buttonText != null && onAction != null) ...[
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
                child: Text(
                  buttonText,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(ProductModel product) {
    return ProductCard(
      product: product,
      isListView: true,
      onTap: () {
        if (product.status == 'Draft') {
          context.push('/add-product', extra: product);
        } else if (product.status == 'Under Review' || product.status == 'Update Under Review' || product.status == 'Submitted') {
          context.push('/under-review-details', extra: product);
        } else if (product.status == 'Changes Required') {
          context.push('/changes-required-details', extra: product);
        } else {
          ProductPreviewSheet.show(context, product);
        }
      },
      onLongPress: () => _showActions(product),
      onEdit: () {
        if (product.status == 'Draft') {
          context.push('/add-product', extra: product);
        } else {
          context.push('/edit-product', extra: product);
        }
      },
      onPreview: () => ProductPreviewSheet.show(context, product),
      onToggleVisibility: (val) async {
        final provider = context.read<ProductProvider>();
        await provider.updateProductStatus(product.productId, val ? 'Live' : 'Hidden');
      },
    );
  }

  void _showActions(ProductModel product) {
    final provider = context.read<ProductProvider>();
    ProductActionsSheet.show(
      context,
      product: product,
      onEdit: () {
        context.push('/edit-product', extra: product);
      },
      onPreview: () => ProductPreviewSheet.show(context, product),
      onDuplicate: () async {
        final success = await provider.duplicateProduct(product);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success ? 'Product duplicated successfully' : 'Failed to duplicate product'),
              backgroundColor: success ? const Color(0xFF4CAF50) : AppColors.error,
            ),
          );
        }
      },
      onToggleVisibility: () async {
        final newStatus = product.status == 'Hidden' ? 'Live' : 'Hidden';
        await provider.updateProductStatus(product.productId, newStatus);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(newStatus == 'Live' ? 'Product is now Live' : 'Product is now Hidden'),
              backgroundColor: const Color(0xFF4CAF50),
            ),
          );
        }
      },
      onToggleAvailability: () async {
        final newStatus = product.status == 'Unavailable' ? 'Live' : 'Unavailable';
        await provider.updateProductStatus(product.productId, newStatus);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(newStatus == 'Live' ? 'Product is now Available' : 'Product is now Unavailable'),
              backgroundColor: const Color(0xFF4CAF50),
            ),
          );
        }
      },
      onDelete: () async {
        final success = await provider.deleteProduct(product.productId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success ? 'Product deleted successfully' : 'Failed to delete product'),
              backgroundColor: success ? const Color(0xFF4CAF50) : AppColors.error,
            ),
          );
        }
      },
    );
  }

  Widget _buildFilterChip(String label, int count) {
    final isSelected = _selectedFilter == label;
    final displayLabel = label == 'Changes Required' ? 'Changes Req.' : (label == 'Under Review' ? 'Review' : label);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Center(
        child: GestureDetector(
          onTap: () => setState(() => _selectedFilter = label),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayLabel,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white.withOpacity(0.2) : const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
