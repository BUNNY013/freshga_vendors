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
  String _selectedFilter = 'Live';
  String? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late Future<DocumentSnapshot> _userFuture;
  Stream<List<ProductModel>>? _productsStream;
  String? _storeId;

  bool _isProductInReview(ProductModel p) {
    return p.status == 'Under Review' ||
        p.status == 'Update Under Review' ||
        p.status == 'Submitted' ||
        p.status == 'Live + Update Pending' ||
        p.pendingUpdate != null ||
        p.pendingReviewVersion != null;
  }

  bool _isProductLive(ProductModel p) {
    return p.status.startsWith('Live') ||
        p.status == 'Approved' ||
        (p.lastApprovedAt != null &&
            (p.status == 'Changes Required' ||
                p.status == 'Under Review' ||
                p.status == 'Update Under Review' ||
                p.status == 'Submitted' ||
                p.status == 'Live + Update Pending'));
  }

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? '';
    _userFuture = FirebaseFirestore.instance.collection('users').doc(userId).get();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ProductProvider>().loadCategories();
      }
    });
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
            return CustomScrollView(
              slivers: [
                _buildSliverAppBar(),
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                ),
              ],
            );
          }

          final userModel =
              UserModel.fromJson(userSnap.data!.data() as Map<String, dynamic>);
          final storeId = userModel.storeId;

          if (storeId.isEmpty) {
            return CustomScrollView(
              slivers: [
                _buildSliverAppBar(),
                SliverFillRemaining(
                  child: Center(
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
                  ),
                ),
              ],
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
                return CustomScrollView(
                  slivers: [
                    _buildSliverAppBar(),
                    const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                    ),
                  ],
                );
              }

              if (snapshot.hasError) {
                return CustomScrollView(
                  slivers: [
                    _buildSliverAppBar(),
                    SliverFillRemaining(
                      child: Center(
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
                      ),
                    ),
                  ],
                );
              }

              final allProducts = snapshot.data ?? [];

              if (allProducts.isEmpty) {
                return CustomScrollView(
                  slivers: [
                    _buildSliverAppBar(),
                    SliverFillRemaining(
                      child: Center(
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
                      ),
                    ),
                  ],
                );
              }

              final allCount = allProducts.length;
              final liveCount = allProducts.where((p) => _isProductLive(p)).length;
              final reviewCount = allProducts.where((p) => _isProductInReview(p)).length;
              final changesCount = allProducts.where((p) => p.status == 'Changes Required').length;
              final draftCount = allProducts.where((p) => p.status == 'Draft').length;
              final unavailableCount = allProducts.where((p) => p.status == 'Unavailable' || p.status == 'Disabled by Admin' || p.status == 'Hidden').length;

              // Apply status filter
              var statusProducts = List<ProductModel>.from(allProducts);
              if (_selectedFilter == 'Live') {
                statusProducts = statusProducts.where((p) => _isProductLive(p)).toList();
              } else if (_selectedFilter == 'Under Review') {
                statusProducts = statusProducts.where((p) => _isProductInReview(p)).toList();
              } else if (_selectedFilter == 'Draft') {
                statusProducts = statusProducts.where((p) => p.status == 'Draft').toList();
              } else if (_selectedFilter == 'Unavailable') {
                statusProducts = statusProducts.where((p) => p.status == 'Unavailable' || p.status == 'Disabled by Admin' || p.status == 'Hidden').toList();
              } else {
                statusProducts = statusProducts.where((p) => p.status == _selectedFilter).toList();
              }

              // Extract unique categories from statusProducts
              final Set<String> availableCategories = {};
              for (var p in statusProducts) {
                if (p.categoryName.isNotEmpty) {
                  availableCategories.add(p.categoryName);
                }
              }
              // If selected category is no longer available, reset
              if (_selectedCategory != null && !availableCategories.contains(_selectedCategory)) {
                _selectedCategory = null;
              }

              // Apply category and search filters
              var finalProducts = List<ProductModel>.from(statusProducts);
              if (_searchQuery.isNotEmpty) {
                finalProducts = finalProducts
                    .where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase()))
                    .toList();
              }
              if (_selectedCategory != null) {
                finalProducts = finalProducts.where((p) => p.categoryName == _selectedCategory).toList();
              }

              final providerCategories = context.watch<ProductProvider>().categories;

              return CustomScrollView(
                slivers: [
                  _buildSliverAppBar(),
                  
                  // Status Chips (Wrap instead of horizontal list)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 10,
                        children: [
                          _buildFilterChip("Live", liveCount),
                          _buildFilterChip("Under Review", reviewCount),
                          _buildFilterChip("Changes Required", changesCount),
                          _buildFilterChip("Draft", draftCount),
                          _buildFilterChip("Unavailable", unavailableCount),
                        ],
                      ),
                    ),
                  ),

                  // Horizontal Category Bubbles (Sticky)
                  if (availableCategories.isNotEmpty)
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _CategoryHeaderDelegate(
                        child: Container(
                          color: Colors.white,
                          padding: const EdgeInsets.only(top: 16, bottom: 8),
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: availableCategories.length,
                            itemBuilder: (context, index) {
                              final catName = availableCategories.elementAt(index);
                              String? imageUrl;
                              try {
                                imageUrl = providerCategories.firstWhere((c) => c.name == catName).imageUrl;
                              } catch (_) {}
                              return _buildCategoryBubble(catName, imageUrl);
                            },
                          ),
                        ),
                      ),
                    ),


                  // Products List
                  if (finalProducts.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: _buildFilteredEmptyState(),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.only(bottom: 100, top: 4),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return _buildProductCard(finalProducts[index]);
                          },
                          childCount: finalProducts.length,
                        ),
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
          subtitle: "Your active products that customers can buy will appear here.",
          color: AppColors.primary,
        );
      case 'Under Review':
        return _buildEmptyState(
          icon: Icons.hourglass_empty_rounded,
          title: "Nothing Under Review",
          subtitle: "Products pending approval from the FreshGa team will show up here.",
          color: const Color(0xFFF57C00), // Orange
        );
      case 'Changes Required':
        return _buildEmptyState(
          icon: Icons.check_circle_outline_rounded,
          title: "All Clear!",
          subtitle: "None of your products require changes. Great job!",
          color: const Color(0xFF198754), // Green
        );
      case 'Draft':
        return _buildEmptyState(
          icon: Icons.edit_document,
          title: "No Drafts",
          subtitle: "You don't have any unfinished products.",
          color: AppColors.primary,
        );
      case 'Unavailable':
        return _buildEmptyState(
          icon: Icons.inventory_2_outlined,
          title: "Everything is Available",
          subtitle: "None of your products are paused or out of stock.",
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
      isLiveSection: _selectedFilter == 'Live',
      onTap: () {
        if (_selectedFilter == 'Live') {
          context.push('/edit-product', extra: product);
          return;
        }
        if (product.status == 'Changes Required') {
          context.push('/changes-required-details', extra: product);
          return;
        }
        if (product.status == 'Draft') {
          context.push('/add-product', extra: product);
        } else if (_isProductInReview(product)) {
          context.push('/under-review-details', extra: product);
        } else {
          context.push('/edit-product', extra: product);
        }
      },
      onLongPress: () => _showActions(product),
      onEdit: () => _handleEditProduct(product),
      onPreview: () => ProductPreviewSheet.show(context, product),
      onToggleVisibility: (val) async {
        final provider = context.read<ProductProvider>();
        await provider.updateProductStatus(product.productId, val ? 'Live' : 'Unavailable');
      },
    );
  }

  void _handleEditProduct(ProductModel product) {
    if (_selectedFilter == 'Live') {
      context.push('/edit-product', extra: product);
      return;
    }
    if (product.status == 'Changes Required') {
      context.push('/changes-required-details', extra: product);
      return;
    }
    if (_isProductInReview(product)) {
      _showPendingUpdateCancellationDialog(context, product);
    } else if (product.status == 'Draft') {
      context.push('/add-product', extra: product);
    } else {
      context.push('/edit-product', extra: product);
    }
  }

  void _showPendingUpdateCancellationDialog(BuildContext context, ProductModel product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFF57C00), size: 24),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Update Under Review',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: const Text(
          'You already have an update pending review for this Live product. To make new edits, you must first withdraw your pending update.',
          style: TextStyle(color: AppColors.grey700, height: 1.4, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep Waiting', style: TextStyle(color: AppColors.grey600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final provider = context.read<ProductProvider>();
              final success = await provider.cancelPendingUpdate(product.productId);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Pending update withdrawn. Ready to edit!'),
                    backgroundColor: Color(0xFF4CAF50),
                  ),
                );
                context.push('/edit-product', extra: product.copyWith(status: 'Live'));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Withdraw & Edit', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showActions(ProductModel product) {
    final provider = context.read<ProductProvider>();
    ProductActionsSheet.show(
      context,
      product: product,
      onEdit: () => _handleEditProduct(product),
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
      onToggleAvailability: () async {
        final newStatus = product.status == 'Unavailable' ? 'Live' : 'Unavailable';
        await provider.updateProductStatus(product.productId, newStatus);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(newStatus == 'Live' ? 'Product is now Available. Followers notified!' : 'Product is now Unavailable'),
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

  Widget _buildCategoryBubble(String catName, String? imageUrl) {
    final isSelected = _selectedCategory == catName;

    return GestureDetector(
      onTap: () {
        setState(() {
          if (_selectedCategory == catName) {
            _selectedCategory = null; // Toggle off
          } else {
            _selectedCategory = catName;
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        width: 72,
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? const Color(0xFFE8F5E9) : Colors.white,
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.grey.shade200,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: ClipOval(
                child: (imageUrl != null && imageUrl.isNotEmpty)
                    ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.category, color: Colors.grey))
                    : const Icon(Icons.category, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              catName,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, int count) {
    final isSelected = _selectedFilter == label;
    final displayLabel = label == 'Changes Required' ? 'Changes Req.' : (label == 'Under Review' ? 'Review' : label);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
          _selectedCategory = null; // reset category
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              displayLabel,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.2) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _CategoryHeaderDelegate({required this.child});

  @override
  double get minExtent => 112.0; 
  
  @override
  double get maxExtent => 112.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox(
      height: 112.0,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return true; // Rebuild when state changes to update selected category
  }
}

  SliverAppBar _buildSliverAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      pinned: false,
      floating: true,
      centerTitle: false,
      toolbarHeight: 72,
      title: const Padding(
        padding: EdgeInsets.only(top: 8.0),
        child: Column(
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
    );
  }

