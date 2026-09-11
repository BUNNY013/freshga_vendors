import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../data/models/store_model.dart';
import '../../../../../data/models/product_model.dart';
import '../../../../products/presentation/providers/product_provider.dart';
import '../../widgets/vendor_about_store_section.dart';
import '../../widgets/vendor_dynamic_category_chips.dart';
import '../../widgets/vendor_store_product_list_item.dart';

class StorePreviewScreen extends StatefulWidget {
  final StoreModel store;

  const StorePreviewScreen({super.key, required this.store});

  @override
  State<StorePreviewScreen> createState() => _StorePreviewScreenState();
}

class _StorePreviewScreenState extends State<StorePreviewScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Set<String> _collapsedSections = {};
  String _selectedCategory = "All";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final productProvider = context.read<ProductProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 220.0,
              pinned: false,
              stretch: true,
              backgroundColor: Colors.white,
              elevation: 0,
              leading: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                stretchModes: const [
                  StretchMode.zoomBackground,
                  StretchMode.blurBackground,
                ],
                collapseMode: CollapseMode.parallax,
                background: Stack(
                  fit: StackFit.expand,
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      bottom: 50,
                      child: CachedNetworkImage(
                        imageUrl: store.banner,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(color: Colors.grey.shade200),
                        errorWidget: (context, url, error) => Container(color: Colors.grey.shade200, child: const Icon(Icons.image_not_supported)),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      bottom: 50,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.4),
                              Colors.transparent,
                              Colors.black.withOpacity(0.1),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 50,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Center(
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 15,
                                spreadRadius: 2,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: store.logo.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: store.logo,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    color: Colors.grey.shade200,
                                    child: Icon(Icons.store, size: 40, color: Colors.grey.shade400),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (!store.isActive || store.isSuspended)
              SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  color: const Color(0xFFFEF2F2),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Color(0xFFDC2626), size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          store.isSuspended
                              ? "${store.storeName} is temporarily offline."
                              : "${store.storeName} is currently on a break and not accepting orders.",
                          style: const TextStyle(
                            color: Color(0xFF991B1B),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 12),
                    Text(
                      store.storeName,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                        fontFamily: 'serif',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "@${store.storeSlug}",
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            "${store.city}, ${store.state}",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text("•", style: TextStyle(color: Colors.grey.shade400)),
                        const SizedBox(width: 8),
                        Text(
                          "${_formatNumber(store.followers)} Followers",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (store.taxNumber.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              store.taxRegistrationType == 'GSTIN' ? Icons.receipt_long : Icons.verified_user_outlined, 
                              size: 14, 
                              color: Colors.grey.shade700
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "${store.taxRegistrationType == 'GSTIN' ? 'GST' : 'Enrolled ID'}: ${store.taxNumber}",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(
              delegate: _PreviewTabBarDelegate(
                TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 3,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: Colors.grey.shade600,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  tabs: const [
                    Tab(text: "Shop"),
                    Tab(text: "About"),
                  ],
                ),
              ),
              pinned: true,
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            // Shop Tab
            StreamBuilder<List<ProductModel>>(
              stream: productProvider.streamProducts(store.storeId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final allProducts = snapshot.data ?? [];
                
                final productCategories = allProducts
                    .map((p) => p.categoryName)
                    .where((c) => c.isNotEmpty)
                    .toSet()
                    .toList();
                
                // Group products
                Map<String, List<ProductModel>> groupedProducts = {};
                
                // Virtual Categories
                if (_selectedCategory == "All") {
                  final bestSellers = allProducts.where((p) => p.tags.contains('Bestseller')).toList();
                  if (bestSellers.isNotEmpty) {
                    groupedProducts["Bestsellers"] = bestSellers.take(5).toList();
                  }

                  final offers = allProducts.where((p) => p.originalPrice > p.price).toList();
                  if (offers.isNotEmpty) {
                    groupedProducts["Discounts"] = offers.toList();
                  }
                }

                // Filter by selected category and group by subcategory
                for (var product in allProducts) {
                  if (_selectedCategory != "All" && product.categoryName != _selectedCategory) {
                    continue;
                  }
                  final subName = product.subCategoryIds.isNotEmpty ? product.subCategoryIds.first : "Other Delights";
                  groupedProducts.putIfAbsent(subName, () => []).add(product);
                }

                // Sort sections
                int getRank(String key) {
                  if (key == "Bestsellers") return 0;
                  if (key == "Discounts") return 1;
                  if (key == "Other Delights") return 999;
                  return 2;
                }

                final sortedKeys = groupedProducts.keys.toList()
                  ..sort((a, b) {
                    final rankA = getRank(a);
                    final rankB = getRank(b);
                    if (rankA != rankB) return rankA.compareTo(rankB);
                    return a.compareTo(b);
                  });

                return CustomScrollView(
                  slivers: [
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _StickyCategoryDelegate(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            VendorDynamicCategoryChips(
                              categories: productCategories,
                              selectedCategory: _selectedCategory,
                              onCategorySelected: (cat) {
                                setState(() {
                                  _selectedCategory = cat;
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                    if (groupedProducts.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.dining_outlined,
                                size: 64,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                "No items match your cravings.",
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...sortedKeys.expand((sectionName) {
                        final sectionProducts = groupedProducts[sectionName]!;
                        final isCollapsed = _collapsedSections.contains(sectionName);

                        return [
                          SliverToBoxAdapter(
                            child: SizedBox(
                              height: 56.0,
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      if (isCollapsed) {
                                        _collapsedSections.remove(sectionName);
                                      } else {
                                        _collapsedSections.add(sectionName);
                                      }
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "$sectionName (${sectionProducts.length})",
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF0F172A),
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        AnimatedRotation(
                                          turns: isCollapsed ? 0.5 : 0.0,
                                          duration: const Duration(milliseconds: 200),
                                          child: const Icon(
                                            Icons.keyboard_arrow_up,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (!isCollapsed)
                            SliverFixedExtentList(
                              itemExtent: 224.0,
                              delegate: SliverChildBuilderDelegate((context, index) {
                                return VendorStoreProductListItem(
                                  product: sectionProducts[index],
                                  store: store,
                                );
                              }, childCount: sectionProducts.length),
                            ),
                        ];
                      }),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          top: 40,
                          bottom: 120,
                        ), 
                        child: Column(
                          children: [
                            Icon(
                              Icons.volunteer_activism_outlined,
                              color: Colors.grey.shade300,
                              size: 36,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "HAPPY TO SERVE YOU",
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2.0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "From our kitchen to your table 🍲",
                              style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            // About Tab
            VendorAboutStoreSection(store: store),
          ],
        ),
      ),
    );
  }
}

class _PreviewTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _PreviewTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_PreviewTabBarDelegate oldDelegate) {
    return false;
  }
}

class _StickyCategoryDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickyCategoryDelegate({required this.child});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Colors.white,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: shrinkOffset > 0 || overlapsContent
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: child,
      ),
    );
  }

  @override
  double get maxExtent => 140.0;

  @override
  double get minExtent => 140.0;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}
