class MashwarPriceModel {
  double? amount;
  String? formatted;

  MashwarPriceModel({this.amount, this.formatted});

  MashwarPriceModel.fromJson(Map<String, dynamic> json) {
    amount = json['amount'] != null
        ? double.tryParse(json['amount'].toString())
        : null;
    formatted = json['formatted'];
  }
}
