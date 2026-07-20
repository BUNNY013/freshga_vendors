class DeliveryAreaModel {
  final String areaId; // 'area_mystate', 'area_selected', 'area_remaining'
  final String areaType; // 'My State', 'Selected States', 'Remaining India'
  final List<String> states; // List of state names included in this area
  final String ruleType; // 'free', 'flat', 'flat_plus_free_above'
  final double deliveryCharge;
  final double? freeShippingThreshold;

  DeliveryAreaModel({
    required this.areaId,
    required this.areaType,
    required this.states,
    required this.ruleType,
    this.deliveryCharge = 0.0,
    this.freeShippingThreshold,
  });

  factory DeliveryAreaModel.fromJson(Map<String, dynamic> json) {
    return DeliveryAreaModel(
      areaId: json['areaId'] ?? '',
      areaType: json['areaType'] ?? '',
      states: List<String>.from(json['states'] ?? []),
      ruleType: json['ruleType'] ?? 'free',
      deliveryCharge: (json['deliveryCharge'] ?? 0.0).toDouble(),
      freeShippingThreshold: json['freeShippingThreshold'] != null 
          ? (json['freeShippingThreshold']).toDouble() 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'areaId': areaId,
      'areaType': areaType,
      'states': states,
      'ruleType': ruleType,
      'deliveryCharge': deliveryCharge,
      'freeShippingThreshold': freeShippingThreshold,
    };
  }

  // Helper method to create default areas
  static List<DeliveryAreaModel> createDefaultAreas(String vendorState, bool canSellPanIndia) {
    List<DeliveryAreaModel> areas = [
      DeliveryAreaModel(
        areaId: 'area_mystate',
        areaType: 'My State',
        states: [vendorState],
        ruleType: 'free',
        deliveryCharge: 0.0,
      )
    ];

    if (canSellPanIndia) {
      areas.add(
        DeliveryAreaModel(
          areaId: 'area_remaining',
          areaType: 'Remaining India',
          states: ['*'], // Represents all states not explicitly covered
          ruleType: 'free',
          deliveryCharge: 0.0,
        )
      );
    }

    return areas;
  }
}
