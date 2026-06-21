class ProductVariantModel {
  final String variantId;
  final String label;
  final double price;
  final double discountPrice;
  final int stock;
  final bool isAvailable;
  final bool isArchived;

  ProductVariantModel({
    required this.variantId,
    required this.label,
    required this.price,
    required this.discountPrice,
    required this.stock,
    required this.isAvailable,
    this.isArchived = false,
  });

  factory ProductVariantModel.fromJson(Map<String, dynamic> json) {
    return ProductVariantModel(
      variantId: json['variantId'] ?? '',
      label: json['label'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      discountPrice: (json['discountPrice'] ?? 0.0).toDouble(),
      stock: json['stock'] ?? 0,
      isAvailable: json['isAvailable'] ?? true,
      isArchived: json['isArchived'] ?? false,
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
      'isArchived': isArchived,
    };
  }

  ProductVariantModel copyWith({
    String? variantId,
    String? label,
    double? price,
    double? discountPrice,
    int? stock,
    bool? isAvailable,
    bool? isArchived,
  }) {
    return ProductVariantModel(
      variantId: variantId ?? this.variantId,
      label: label ?? this.label,
      price: price ?? this.price,
      discountPrice: discountPrice ?? this.discountPrice,
      stock: stock ?? this.stock,
      isAvailable: isAvailable ?? this.isAvailable,
      isArchived: isArchived ?? this.isArchived,
    );
  }
}
