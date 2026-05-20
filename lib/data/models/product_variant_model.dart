class ProductVariantModel {
  final String variantId;
  final String label;
  final double price;
  final double discountPrice;
  final int stock;
  final bool isAvailable;

  ProductVariantModel({
    required this.variantId,
    required this.label,
    required this.price,
    required this.discountPrice,
    required this.stock,
    required this.isAvailable,
  });

  factory ProductVariantModel.fromJson(Map<String, dynamic> json) {
    return ProductVariantModel(
      variantId: json['variantId'] ?? '',
      label: json['label'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      discountPrice: (json['discountPrice'] ?? 0.0).toDouble(),
      stock: json['stock'] ?? 0,
      isAvailable: json['isAvailable'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'variantId': variantId,
      'label': label,
      'price': price,
      'discountPrice': discountPrice,
      'stock': stock,
      'isAvailable': isAvailable,
    };
  }

  ProductVariantModel copyWith({
    String? variantId,
    String? label,
    double? price,
    double? discountPrice,
    int? stock,
    bool? isAvailable,
  }) {
    return ProductVariantModel(
      variantId: variantId ?? this.variantId,
      label: label ?? this.label,
      price: price ?? this.price,
      discountPrice: discountPrice ?? this.discountPrice,
      stock: stock ?? this.stock,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }
}
