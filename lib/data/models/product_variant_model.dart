class ProductVariantModel {
  final String variantId;
  final String label;
  final double price;
  final double discountPrice;
  final int stock;
  final bool isAvailable;
  final bool isArchived;
  final bool manageStock;
  final int weightGrams;
  final double lengthCm;
  final double widthCm;
  final double heightCm;
  final String unitType; // 'weight', 'volume', 'pack', 'custom'
  final String unit;     // 'g', 'kg', 'ml', 'L', 'Pack', etc.
  final bool isDefault;

  ProductVariantModel({
    required this.variantId,
    required this.label,
    required this.price,
    required this.discountPrice,
    required this.stock,
    required this.isAvailable,
    this.isArchived = false,
    this.manageStock = false,
    this.weightGrams = 0,
    this.lengthCm = 0.0,
    this.widthCm = 0.0,
    this.heightCm = 0.0,
    this.unitType = 'weight',
    this.unit = 'g',
    this.isDefault = false,
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
      manageStock: json['manageStock'] ?? false,
      weightGrams: json['weightGrams'] ?? 0,
      lengthCm: (json['lengthCm'] ?? 0.0).toDouble(),
      widthCm: (json['widthCm'] ?? 0.0).toDouble(),
      heightCm: (json['heightCm'] ?? 0.0).toDouble(),
      unitType: json['unitType']?.toString() ?? 'weight',
      unit: json['unit']?.toString() ?? 'g',
      isDefault: json['isDefault'] ?? false,
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
      'manageStock': manageStock,
      'weightGrams': weightGrams,
      'lengthCm': lengthCm,
      'widthCm': widthCm,
      'heightCm': heightCm,
      'unitType': unitType,
      'unit': unit,
      'isDefault': isDefault,
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
    bool? manageStock,
    int? weightGrams,
    double? lengthCm,
    double? widthCm,
    double? heightCm,
    String? unitType,
    String? unit,
    bool? isDefault,
  }) {
    return ProductVariantModel(
      variantId: variantId ?? this.variantId,
      label: label ?? this.label,
      price: price ?? this.price,
      discountPrice: discountPrice ?? this.discountPrice,
      stock: stock ?? this.stock,
      isAvailable: isAvailable ?? this.isAvailable,
      isArchived: isArchived ?? this.isArchived,
      manageStock: manageStock ?? this.manageStock,
      weightGrams: weightGrams ?? this.weightGrams,
      lengthCm: lengthCm ?? this.lengthCm,
      widthCm: widthCm ?? this.widthCm,
      heightCm: heightCm ?? this.heightCm,
      unitType: unitType ?? this.unitType,
      unit: unit ?? this.unit,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}

