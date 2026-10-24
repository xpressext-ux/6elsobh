class DeliveryAreaModel {
  final int id;
  final String areaName;
  final double deliveryCharge;
  final int displayOrder;

  const DeliveryAreaModel({
    required this.id,
    required this.areaName,
    required this.deliveryCharge,
    required this.displayOrder,
  });

  factory DeliveryAreaModel.fromJson(Map<String, dynamic> json) {
    return DeliveryAreaModel(
      id: int.parse(json['id'].toString()),
      areaName: (json['area_name'] ?? json['name'])?.toString() ?? '',
      deliveryCharge: double.tryParse(json['delivery_charge'].toString()) ?? 0,
      displayOrder: int.tryParse((json['display_order'] ?? json['sort_order'] ?? 0).toString()) ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is DeliveryAreaModel && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
