import 'package:sixam_mart/features/mashwar/domain/models/mashwar_price_model.dart';

class MashwarAreaModel {
  int? id;
  String? name;
  MashwarPriceModel? price;

  MashwarAreaModel({this.id, this.name, this.price});

  MashwarAreaModel.fromJson(Map<String, dynamic> json) {
    id = json['id'] != null ? int.tryParse(json['id'].toString()) : null;
    name = json['name']?.toString();
    if (json['price'] != null) {
      price = MashwarPriceModel.fromJson(
        Map<String, dynamic>.from(json['price']),
      );
    }
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MashwarAreaModel && id != null && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
