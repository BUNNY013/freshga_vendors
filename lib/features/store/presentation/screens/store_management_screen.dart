import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/models/store_model.dart';
import '../../../../data/models/product_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/store_banner_header.dart';
import '../widgets/store_stat_chips.dart';
import '../widgets/store_actions_row.dart';
import '../widgets/store_collections_section.dart';
import '../widgets/store_product_grid.dart';
import '../widgets/store_social_links.dart';

class StoreManagementScreen extends StatefulWidget {
  const StoreManagementScreen({super.key});

  @override
  State<StoreManagementScreen> createState() => _StoreManagementScreenState();
}

class _StoreManagementScreenState extends State<StoreManagementScreen> {
  final _scrollController = ScrollController();
  bool _isHeaderCollapsed = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final isCollapsed = _scrollController.offset > 160;
    if (isCollapsed != _isHeaderCollapsed) {
      setState(() => _isHeaderCollapsed = isCollapsed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Not authenticated')),
      );
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, userSnap) {
        if (!userSnap.hasData) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }

        final userModel = UserModel.fromJson(userSnap.data!.data() as Map<String, dynamic>);
        final storeId = userModel.storeId;

        if (storeId.isEmpty) {
          return _buildNoStoreState(context);
        }

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('stores').doc(storeId).snapshots(),
          builder: (context, storeSnap) {
            if (!storeSnap.hasData || !storeSnap.data!.exists) {
              return const Scaffold(
                backgroundColor: AppColors.background,
                body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
              );
            }

            final store = StoreModel.fromJson(storeSnap.data!.data() as Map<String, dynamic>);

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('products')
                  .where('storeId', isEqualTo: storeId)
                  .orderBy('createdAt', descending: true)
                  .limit(20)
                  .snapshots(),
              builder: (context, productsSnap) {
                final products = productsSnap.hasData
                    ? productsSnap.data!.docs
                        .map((d) => ProductModel.fromJson(d.data() as Map<String, dynamic>))
                        .toList()
                    : <ProductModel>[];

                return _buildStoreScreen(context, store, products);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildStoreScreen(
    BuildContext context,
    StoreModel store,
    List<ProductModel> products,
  ) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Sticky App Bar
          SliverAppBar(
            pinned: true,
            floating: false,
            expandedHeight: 0,
            backgroundColor: Colors.white,
            elevation: _isHeaderCollapsed ? 1 : 0,
            title: _isHeaderCollapsed
                ? Row(
                    children: [
                      if (store.logo.isNotEmpty)
                        CircleAvatar(
                          radius: 16,
                          backgroundImage: NetworkImage(store.logo),
                        )
                      else
                        const CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.primaryLight,
                          child: Icon(Icons.fastfood, size: 16, color: AppColors.primary),
                        ),
                      const SizedBox(width: 10),
                      Text(
                        store.storeName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (store.verified) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.verified, color: Color(0xFF1DA1F2), size: 16),
                      ],
                    ],
                  )
                : const Text(
                    'Store',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
          ),

          // Body content
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── 1. Banner Header ───────────────────────────────
                StoreBannerHeader(
                  store: store,
                ),
                const SizedBox(height: 8),

                // ─── 2. Stats ───────────────────────────────────────
                StoreStatChips(
                  store: store,
                  productCount: store.productsCount,
                ),
                const SizedBox(height: 16),

                // ─── 3. Social Links ────────────────────────────────
                StoreSocialLinks(
                  instagramLink: store.instagramLink,
                  youtubeLink: store.youtubeLink,
                  facebookLink: store.facebookLink,
                ),
                if (store.instagramLink.isNotEmpty ||
                    store.youtubeLink.isNotEmpty ||
                    store.facebookLink.isNotEmpty)
                  const SizedBox(height: 16),

                // ─── 4. Action Buttons ──────────────────────────────
                StoreActionsRow(
                  storeSlug: store.storeSlug,
                  storeName: store.storeName,
                  onEditStore: () => context.push('/edit-store'),
                  onPreviewStore: () => _showPreviewBottomSheet(context, store),
                ),
                const SizedBox(height: 32),

                // ─── 5. Collections ─────────────────────────────────
                StoreCollectionsSection(categories: store.categories),
                const SizedBox(height: 32),

                // ─── 6. Products Grid ───────────────────────────────
                StoreProductGrid(
                  products: products,
                  onAddProduct: () => context.push('/add-product'),
                  onProductTap: (product) => context.push('/add-product', extra: product),
                ),
                const SizedBox(height: 40),

                // ─── 7. Footer / No followers nudge ─────────────────
                if (store.followers == 0)
                  _buildGrowFollowersNudge(context, store.storeSlug),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),

      // FAB — quick add product (Minimal Style)
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add-product'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
        elevation: 4,
      ),
    );
  }

  Widget _buildGrowFollowersNudge(BuildContext context, String storeSlug) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withOpacity(0.08),
              const Color(0xFF5B8DEF).withOpacity(0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            const Text('❤️', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Grow your followers',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Start sharing your store to grow followers ❤️',
                    style: TextStyle(fontSize: 12, color: AppColors.grey600, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Share',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPreviewBottomSheet(BuildContext context, StoreModel store) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _StorePreviewSheet(store: store),
    );
  }

  Widget _buildNoStoreState(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.store_outlined, size: 64, color: AppColors.grey400),
              const SizedBox(height: 16),
              const Text(
                'No store found',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Set up your store to start selling.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.grey600),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.push('/store-setup'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Set Up Store'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Store Preview Bottom Sheet ─────────────────────────────────────────────

class _StorePreviewSheet extends StatelessWidget {
  final StoreModel store;
  const _StorePreviewSheet({required this.store});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle + header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.grey300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Customer Preview',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'This is how customers see your store',
                          style: TextStyle(fontSize: 12, color: AppColors.grey500),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: AppColors.grey600),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 20),

          // Mock customer view
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Banner mock
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.bottomCenter,
                    children: [
                      Container(
                        height: 180,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.grey200,
                        ),
                        child: store.banner.isNotEmpty
                            ? Image.network(store.banner, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _bannerFallback())
                            : _bannerFallback(),
                      ),
                      Positioned(
                        bottom: -44,
                        child: Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(color: Colors.white, width: 4),
                            image: store.logo.isNotEmpty
                                ? DecorationImage(image: NetworkImage(store.logo), fit: BoxFit.cover)
                                : null,
                          ),
                          child: store.logo.isEmpty
                              ? const Icon(Icons.fastfood, size: 36, color: AppColors.grey400)
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 56),
                  // Store name
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              store.storeName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (store.verified) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.verified, color: Color(0xFF1DA1F2), size: 18),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '@${store.storeSlug}',
                          style: const TextStyle(color: AppColors.grey500, fontSize: 13),
                        ),
                        const SizedBox(height: 10),
                        if (store.description.isNotEmpty)
                          Text(
                            store.description,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        const SizedBox(height: 16),
                        // Follow + message buttons (customer view mock)
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          alignment: WrapAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Follow',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.grey300),
                              ),
                              child: const Text(
                                'Message',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Stats preview
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _previewStat('${store.followers}', 'Followers'),
                      _previewStat('${store.likesCount}', 'Likes'),
                      _previewStat('${store.productsCount}', 'Products'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Products',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Empty products placeholder
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.8,
                      children: List.generate(4, (i) => _previewProductTile()),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bannerFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFD66853), Color(0xFFE8896B)],
        ),
      ),
    );
  }

  Widget _previewStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.grey500),
        ),
      ],
    );
  }

  Widget _previewProductTile() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Icon(Icons.fastfood_outlined, color: AppColors.grey300, size: 32),
      ),
    );
  }
}
