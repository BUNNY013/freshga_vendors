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
import '../../../../core/widgets/empty_state_widget.dart';
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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All';
  bool _isGridView = true;

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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Products',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          // Grid / List Toggle
          IconButton(
            onPressed: () => setState(() => _isGridView = !_isGridView),
            icon: Icon(
              _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
              color: AppColors.grey600,
            ),
            tooltip: _isGridView ? 'List View' : 'Grid View',
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-product'),
        backgroundColor: AppColors.primary,
        elevation: 6,
        icon: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
        label: const Text(
          "Add Product",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
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
                child: EmptyStateWidget(
                  icon: Icons.store_outlined,
                  title: "Set up your store first",
                  message: "You need to create your store before adding products.",
                  buttonText: "Go to Store",
                  onAction: () => context.push('/store'),
                ),
              ),
            );
          }

          return StreamBuilder<List<ProductModel>>(
            stream: context.read<ProductProvider>().streamProducts(storeId),
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

              // If absolutely no products exist, show motivational empty state
              if (allProducts.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: EmptyStateWidget(
                      icon: Icons.fastfood_rounded,
                      title: "Your food journey starts here 🚀",
                      message:
                          "Add your first homemade product and start building your brand.",
                      buttonText: "Add First Product",
                      onAction: () => context.push('/add-product'),
                    ),
                  ),
                );
              }

              // Apply filters
              var products = List<ProductModel>.from(allProducts);

              // Search
              if (_searchQuery.isNotEmpty) {
                products = products
                    .where((p) => p.name
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase()))
                    .toList();
              }

              // Chip Filter
              if (_selectedFilter == 'Active') {
                products = products.where((p) => p.isActive).toList();
              } else if (_selectedFilter == 'Hidden') {
                products = products.where((p) => !p.isActive).toList();
              } else if (_selectedFilter == 'Out of Stock') {
                products = products
                    .where((p) => p.variants.every((v) => v.stock == 0))
                    .toList();
              }

              return Column(
                children: [
                  // Search Bar
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) =>
                          setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: "Search your products...",
                        hintStyle:
                            const TextStyle(color: AppColors.grey500, fontSize: 14),
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: AppColors.grey500),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded,
                                    color: AppColors.grey500, size: 20),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              const BorderSide(color: AppColors.grey200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              const BorderSide(color: AppColors.primary),
                        ),
                      ),
                    ),
                  ),

                  // Filter Chips
                  SizedBox(
                    height: 44,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _buildFilterChip("All"),
                        _buildFilterChip("Active"),
                        _buildFilterChip("Out of Stock"),
                        _buildFilterChip("Hidden"),
                      ],
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Products
                  Expanded(
                    child: products.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.search_off_rounded,
                                      size: 56,
                                      color: AppColors.grey400),
                                  const SizedBox(height: 16),
                                  const Text(
                                    "No products found",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    "Try adjusting your search or filters.",
                                    style: TextStyle(
                                        color: AppColors.grey600, fontSize: 13),
                                  ),
                                  const SizedBox(height: 20),
                                  TextButton(
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchQuery = '';
                                        _selectedFilter = 'All';
                                      });
                                    },
                                    child: const Text(
                                      'Clear Filters',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : _isGridView
                            ? _buildGridView(products)
                            : _buildListView(products),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // ==========================================
  // GRID VIEW
  // ==========================================
  Widget _buildGridView(List<ProductModel> products) {
    return GridView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 80, top: 4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.48,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) =>
          _buildProductCard(products[index], false),
    );
  }

  // ==========================================
  // LIST VIEW
  // ==========================================
  Widget _buildListView(List<ProductModel> products) {
    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 80, top: 4),
      itemCount: products.length,
      itemBuilder: (context, index) =>
          _buildProductCard(products[index], true),
    );
  }

  // ==========================================
  // PRODUCT CARD BUILDER
  // ==========================================
  Widget _buildProductCard(ProductModel product, bool isList) {
    final provider = context.read<ProductProvider>();
    return ProductCard(
      product: product,
      isListView: isList,
      onTap: () => ProductPreviewSheet.show(context, product),
      onLongPress: () => _showActions(product),
      onEdit: () {
        context.push('/add-product', extra: product);
      },
      onPreview: () => ProductPreviewSheet.show(context, product),
      onToggleVisibility: (val) =>
          provider.toggleProductVisibility(product.productId, val),
    );
  }

  // ==========================================
  // ACTIONS BOTTOM SHEET
  // ==========================================
  void _showActions(ProductModel product) {
    final provider = context.read<ProductProvider>();
    ProductActionsSheet.show(
      context,
      product: product,
      onEdit: () {
        context.push('/add-product', extra: product);
      },
      onPreview: () => ProductPreviewSheet.show(context, product),
      onToggleVisibility: () =>
          provider.toggleProductVisibility(product.productId, !product.isActive),
      onDelete: () async {
        final success = await provider.deleteProduct(product.productId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success
                  ? 'Product deleted successfully'
                  : 'Failed to delete product'),
              backgroundColor: success ? const Color(0xFF4CAF50) : AppColors.error,
            ),
          );
        }
      },
    );
  }

  // ==========================================
  // FILTER CHIP
  // ==========================================
  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _selectedFilter = label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.grey300,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
