import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/product_variant_model.dart';

class VendorProductPreview extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final discount = originalPrice > price && originalPrice > 0 
        ? ((originalPrice - price) / originalPrice * 100).round() 
        : 0;

    final bgColor = const Color(0xFFFDF8F2); // The off-white background from screenshot

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          // Image Section
          SliverToBoxAdapter(
            child: SizedBox(
              height: 350,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (images.isNotEmpty)
                    Image.file(images.first, fit: BoxFit.cover)
                  else
                    Container(
                      color: AppColors.grey200,
                      child: const Center(
                        child: Icon(Icons.image_outlined, size: 64, color: AppColors.grey400),
                      ),
                    ),
                  
                  // Top left back button
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 16,
                    left: 16,
                    child: _buildGlassButton(
                      icon: Icons.arrow_back,
                      onTap: () => Navigator.pop(context),
                    ),
                  ),
                  
                ],
              ),
            ),
          ),
          
          // Content Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    name.isEmpty ? "Product Name" : name,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2C3E50), // Dark blue/grey text
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Price Area
                  const Text("CURRENT PRICE", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF5E6C84), letterSpacing: 1.2)),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "₹${price.toStringAsFixed(0)}",
                        style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Color(0xFF1B5E20)), // Dark green
                      ),
                      if (originalPrice > price) ...[
                        const SizedBox(width: 12),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            "₹${originalPrice.toStringAsFixed(0)}",
                            style: const TextStyle(
                              fontSize: 20,
                              color: Colors.grey,
                              decoration: TextDecoration.lineThrough,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.red.shade100),
                            ),
                            child: Text(
                              "$discount% OFF",
                              style: TextStyle(color: Colors.red.shade300, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  
                  const SizedBox(height: 32),

                  // Variant Selector (Select Weight)
                  if (variants.isNotEmpty) ...[
                    const Text("SELECT WEIGHT", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF5E6C84), letterSpacing: 1.2)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: variants.asMap().entries.map((entry) {
                        int idx = entry.key;
                        ProductVariantModel v = entry.value;
                        bool isSelected = idx == 0; // Select first by default
                        
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFF1F8E9) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF2E7D32) : Colors.grey.shade300,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Text(
                            v.label.isEmpty ? 'Weight' : v.label,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? const Color(0xFF2E7D32) : const Color(0xFF5E6C84),
                              fontSize: 14,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),
                  ],

                  // About the product
                  const Text("About the product", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF2C3E50))),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      shortDescription.isEmpty ? "Detailed description of the product goes here." : shortDescription,
                      style: const TextStyle(fontSize: 15, color: Color(0xFF4A5568), height: 1.6),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Ingredients Card
                  if (ingredients.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFE9DE), // Beige card background
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("INGREDIENTS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF5E6C84), letterSpacing: 1.2)),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: ingredients.map((i) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24), // Pill shape
                              ),
                              child: Text(i, style: const TextStyle(fontSize: 13, color: Color(0xFF2C3E50), fontWeight: FontWeight.w600)),
                            )).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Info Cards (Shelf Life & Dispatch Time)
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.calendar_today_outlined, color: Color(0xFF2E7D32), size: 28),
                              const SizedBox(height: 12),
                              const Text("Shelf Life", style: TextStyle(color: Color(0xFF5E6C84), fontSize: 13)),
                              const SizedBox(height: 4),
                              Text(shelfLife.isEmpty ? "3 Months" : shelfLife, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2C3E50))),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.eco_outlined, color: Color(0xFF2E7D32), size: 28),
                              const SizedBox(height: 12),
                              const Text("Dispatch Time", style: TextStyle(color: Color(0xFF5E6C84), fontSize: 13)),
                              const SizedBox(height: 4),
                              Text(dispatchTime.isEmpty ? "3 Days" : dispatchTime, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2C3E50))),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // Bottom padding
                  const SizedBox(height: 60),
                ],
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
        ),
        child: Icon(icon, color: const Color(0xFF2C3E50), size: 22),
      ),
    );
  }
}
