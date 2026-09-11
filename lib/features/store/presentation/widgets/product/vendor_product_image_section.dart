import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../data/models/product_model.dart';

class VendorProductImageSection extends StatefulWidget {
  final ProductModel product;

  const VendorProductImageSection({super.key, required this.product});

  @override
  State<VendorProductImageSection> createState() => _VendorProductImageSectionState();
}

class _VendorProductImageSectionState extends State<VendorProductImageSection> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<String> displayImages = widget.product.images.isNotEmpty
        ? widget.product.images
        : [];

    return Stack(
      children: [
        // Immersive Image Slideshow
        AspectRatio(
          aspectRatio: 4 / 3, // Premium 4:3 ratio matching product cards
          child: displayImages.isEmpty 
          ? Container(
              color: Colors.grey.shade100,
              child: const Icon(Icons.image_outlined, size: 64, color: Colors.grey),
            )
          : PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: displayImages.length,
            itemBuilder: (context, index) {
              return Hero(
                tag: index == 0
                    ? 'product_image_${widget.product.productId}'
                    : 'product_image_${widget.product.productId}_$index',
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.zero,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: CachedNetworkImage(
                    imageUrl: displayImages[index],
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        Container(color: Colors.grey.shade50),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey.shade50,
                      child: const Icon(
                        Icons.broken_image,
                        size: 50,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Pagination Dots (Premium Style)
        if (displayImages.length > 1)
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                displayImages.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 6,
                  width: _currentIndex == index ? 24 : 6,
                  decoration: BoxDecoration(
                    color: _currentIndex == index
                        ? AppColors.primary
                        : Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      if (_currentIndex == index)
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      if (_currentIndex != index)
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
