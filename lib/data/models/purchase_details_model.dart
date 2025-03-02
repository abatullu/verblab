// lib/data/models/purchase_details_model.dart
import 'package:in_app_purchase/in_app_purchase.dart';

class PurchaseDetailsModel {
  final PurchaseStatus? status;
  final String productId;
  final String? message;

  const PurchaseDetailsModel({
    this.status,
    required this.productId,
    this.message,
  });
}
