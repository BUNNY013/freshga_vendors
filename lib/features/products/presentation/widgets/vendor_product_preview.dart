import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/product_variant_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../data/models/user_model.dart';
import '../../../store/domain/models/store_model.dart';

class VendorProductPreview extends StatefulWidget {
  final String name;
  final String shortDescription;
  final String description;
  final double price;
  final double originalPrice;
  final String weight;
  final String shelfLife;
  final String dispatchTime;
  final List<ProductVariantModel> variants;
  final List<String> ingredients;
  final List<String> tags;
  final List<File> images;

  const VendorProductPreview({
    super.key,
    required this.name,
    required this.shortDescription,
    required this.description,
    required this.price,
    required this.originalPrice,
    required this.weight,
    required this.shelfLife,
    required this.dispatchTime,
    required this.variants,
    required this.ingredients,
    required this.tags,
    required this.images,
  });

  @override
  State<VendorProductPreview> createState() => _VendorProductPreviewState();
}

class _VendorProductPreviewState extends State<VendorProductPreview> {
  int _currentImageIndex = 0;
  int _selectedVariantIndex = 0;
  @override
  Widget build(BuildContext context) {
    final bgColor = const Color(0xFFFFF9F2);
    
    ProductVariantModel? selectedVariant;
    double currentPrice = widget.price;
    double currentOriginalPrice = widget.originalPrice;
    
    if (widget.variants.isNotEmpty && _selectedVariantIndex < widget.variants.length) {
      selectedVariant = widget.variants[_selectedVariantIndex];
      currentPrice = selectedVariant.discountPrice > 0 ? selectedVariant.discountPrice : selectedVariant.price;
      currentOriginalPrice = selectedVariant.discountPrice > 0 ? selectedVariant.price : currentPrice;
    }

    final discount = currentOriginalPrice > currentPrice && currentOriginalPrice > 0 
        ? ((currentOriginalPrice - currentPrice) / currentOriginalPrice * 100).round() 
        : 0;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const ClampingScrollPhysics(),
            slivers: [
              _buildImageCarousel(),
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitleAndPricing(currentPrice, currentOriginalPrice, discount),
                      if (widget.variants.isNotEmpty) _buildVariantSelector(),
                      const Divider(height: 32, color: Color(0xFFF1F5F9)),
                      _buildProductHighlights(),
                      if (widget.ingredients.isNotEmpty) ...[
                        const Divider(height: 32, color: Color(0xFFF1F5F9)),
                        _buildIngredientsSection(),
                      ],
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
                  child: _buildStoreProfileCard(),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16.0),
                  margin: const EdgeInsets.only(bottom: 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Product Description",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.description.isEmpty ? "No description provided." : widget.description,
                        style: const TextStyle(fontSize: 14, color: AppColors.grey600, height: 1.6),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          // Sticky Add to Cart Bar
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: _buildStickyBottomBar(currentPrice),
          ),
          
          // Top left back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            child: _buildGlassButton(
              icon: Icons.arrow_back,
              onTap: () => Navigator.pop(context),
            ),
          ),
          // Top right actions (mock)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: Row(
              children: [
                _buildGlassButton(
                  icon: Icons.share_outlined, 
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Save the product first to share it with customers!')),
                    );
                  }
                ),
                const SizedBox(width: 12),
                _buildGlassButton(icon: Icons.favorite_border, onTap: () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCarousel() {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: MediaQuery.of(context).size.width,
        width: double.infinity,
        child: Stack(
          children: [
            if (widget.images.isNotEmpty)
              PageView.builder(
                itemCount: widget.images.length,
                onPageChanged: (index) => setState(() => _currentImageIndex = index),
                itemBuilder: (context, index) {
                  return Image.file(
                    widget.images[index],
                    fit: BoxFit.cover,
                  );
                },
              )
            else
              Container(
                color: AppColors.grey200,
                child: const Center(
                  child: Icon(Icons.image_outlined, size: 64, color: AppColors.grey400),
                ),
              ),
            
            if (widget.images.length > 1)
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    widget.images.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentImageIndex == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentImageIndex == index ? AppColors.primary : Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleAndPricing(double price, double originalPrice, int discount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                widget.name.isEmpty ? "Product Name" : widget.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  height: 1.3,
                ),
              ),
            ),
            const SizedBox(width: 16),
            if (widget.tags.contains('veg'))
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(border: Border.all(color: Colors.green), borderRadius: BorderRadius.circular(4)),
                child: const Icon(Icons.circle, color: Colors.green, size: 12),
              )
            else if (widget.tags.contains('non_veg'))
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(border: Border.all(color: Colors.red), borderRadius: BorderRadius.circular(4)),
                child: const Icon(Icons.change_history, color: Colors.red, size: 12),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
            const SizedBox(width: 4),
            const Text(
              "4.8",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(width: 4),
            const Text(
              "(124 reviews)",
              style: TextStyle(color: AppColors.grey500, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "₹${price.toStringAsFixed(0)}",
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            if (originalPrice > price) ...[
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  "₹${originalPrice.toStringAsFixed(0)}",
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.grey400,
                    decoration: TextDecoration.lineThrough,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    "$discount% OFF",
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        const Text("Inclusive of all taxes", style: TextStyle(color: AppColors.grey500, fontSize: 12)),
      ],
    );
  }

  Widget _buildVariantSelector() {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Select Quantity",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: widget.variants.asMap().entries.map((entry) {
                int idx = entry.key;
                ProductVariantModel variant = entry.value;
                bool isSelected = _selectedVariantIndex == idx;
                
                return GestureDetector(
                  onTap: () => setState(() => _selectedVariantIndex = idx),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF16A34A) : const Color(0xFFE2E8F0),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          variant.label,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            color: isSelected ? const Color(0xFF16A34A) : AppColors.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "₹${(variant.discountPrice > 0 ? variant.discountPrice : variant.price).toStringAsFixed(0)}",
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? const Color(0xFF16A34A) : AppColors.grey600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductHighlights() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Product Highlights",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildHighlightCard(
                icon: Icons.timer_outlined,
                title: "Shelf Life",
                value: widget.shelfLife.isEmpty ? "3 Months" : widget.shelfLife,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildHighlightCard(
                icon: Icons.local_shipping_outlined,
                title: "Dispatch In",
                value: widget.dispatchTime.isEmpty ? "2 Days" : widget.dispatchTime,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHighlightCard({required IconData icon, required String title, required String value}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, color: AppColors.grey500)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Ingredients",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.ingredients.map((i) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              i,
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
            ),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildStoreProfileCard() {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).get(),
      builder: (context, userSnap) {
        if (!userSnap.hasData) return const SizedBox.shrink();
        final userData = userSnap.data?.data() as Map<String, dynamic>?;
        if (userData == null) return const SizedBox.shrink();
        final storeId = UserModel.fromJson(userData).storeId;

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('stores').doc(storeId).get(),
          builder: (context, storeSnap) {
            if (!storeSnap.hasData) return const SizedBox.shrink();
            final storeData = storeSnap.data?.data() as Map<String, dynamic>?;
            if (storeData == null) return const SizedBox.shrink();
            final store = StoreModel.fromJson(storeData);

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        store.storeName.isNotEmpty ? store.storeName[0].toUpperCase() : "F",
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              store.storeName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                              child: const Icon(Icons.check, color: Colors.white, size: 10),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(store.totalReviews < 5 ? "New" : store.rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            if (store.totalReviews >= 5) ...[
                              const SizedBox(width: 4),
                              Text("(${store.totalReviews})", style: const TextStyle(color: AppColors.grey500, fontSize: 13)),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, color: AppColors.grey500, size: 14),
                            const SizedBox(width: 4),
                            Text("${store.city}, ${store.state}", style: const TextStyle(color: AppColors.grey500, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.grey400),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStickyBottomBar(double currentPrice) {
    return Container(
      padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Total Price", style: TextStyle(color: AppColors.grey500, fontSize: 12)),
                const SizedBox(height: 2),
                Text(
                  "₹${currentPrice.toStringAsFixed(0)}",
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('This is a preview. Cart disabled.')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                "Add to Cart",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 22),
      ),
    );
  }
}
