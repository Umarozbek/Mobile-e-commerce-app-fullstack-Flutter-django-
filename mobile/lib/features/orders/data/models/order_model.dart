import 'package:easy_localization/easy_localization.dart';
import 'package:equatable/equatable.dart';

import '../../../locations/data/models/location_model.dart';
import '../../domain/entities/order_status.dart';
import 'order_timeline_model.dart';

class OrderModel extends Equatable {
  final int? id;
  final String? orderNumber;
  final String? status;
  final String? statusDisplay;
  final String? customerName;
  final String? address;
  final double? totalAmount;
  final double? deliveryFee;
  final double? bonusAmount;
  final double? loyaltyPayment; // Amount paid with loyalty points
  final String? formattedCardNumber; // Card number for payment
  final String? comment;
  final List<OrderItem>? items;
  final DateTime? createdAt;
  final OrderTimeline? timeline; // Order status timeline
  // Kept for compatibility if used elsewhere, but not in JSON list
  final String? paymentMethod;
  final String? checkImagePath; 
  final String? paymentCardInfo;
  final DateTime? paidAt;
  final DateTime? confirmedAt;
  final LocationModel? deliveryAddressModel;

  const OrderModel({
    this.id,
    this.orderNumber,
    this.status,
    this.statusDisplay,
    this.customerName,
    this.address,
    this.totalAmount,
    this.deliveryFee,
    this.bonusAmount,
    this.loyaltyPayment,
    this.formattedCardNumber,
    this.comment,
    this.items,
    this.createdAt,
    this.timeline,
    this.paymentMethod,
    this.checkImagePath,
    this.paymentCardInfo,
    this.paidAt,
    this.confirmedAt,
    this.deliveryAddressModel,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'],
      orderNumber: json['order_number'],
      status: json['status'],
      statusDisplay: json['status_display'],
      customerName: json['customer_name'],
      address: json['location_address'] ?? json['address'],
      totalAmount: double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0.0,
      deliveryFee: double.tryParse(json['delivery_fee']?.toString() ?? '0') ?? 0.0,
      bonusAmount: double.tryParse(json['bonus_amount']?.toString() ?? '0') ?? 0.0,
      loyaltyPayment: json['loyalty_payment'] != null
          ? double.tryParse(json['loyalty_payment'].toString())
          : null,
      formattedCardNumber: json['formatted_card_number'],
      comment: json['comment'],
      items: (json['items'] as List?)?.map((e) => OrderItem.fromJson(e)).toList() ??
          (json['products_details'] as List?)?.map((e) => OrderItem.fromJson(e)).toList() ??
          [],
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      timeline: json['timeline'] != null ? OrderTimeline.fromJson(json['timeline']) : null,
      paymentMethod: json['payment_receipt'] != null ? 'receipt' : null,
      checkImagePath: json['payment_receipt'],
      paymentCardInfo: json['formatted_card_number'],
      // Real payment/approval timestamps if backend sends them
      paidAt: DateTime.tryParse(json['paid_at']?.toString() ?? ''),
      confirmedAt: DateTime.tryParse(json['confirmed_at']?.toString() ?? ''),
      deliveryAddressModel: null,
    );
  }

  // Helper for UI to get displayable status (always use our translations for known statuses)
  String get statusText {
    final orderStatus = OrderStatus.maybeFrom(status);
    if (orderStatus != null) {
      return orderStatus.translationKey.tr();
    }
    if (statusDisplay != null && statusDisplay!.isNotEmpty) {
      return statusDisplay!;
    }
    return status ?? '';
  }

  static String getStatusDisplayText(String status) {
    final orderStatus = OrderStatus.maybeFrom(status);
    if (orderStatus != null) return orderStatus.translationKey.tr();
    if (status.trim().isEmpty) return status;
    return status;
  }

  @override
  List<Object?> get props => [
        id,
        orderNumber,
        status,
        statusDisplay,
        customerName,
        address,
        totalAmount,
        deliveryFee,
        bonusAmount,
        loyaltyPayment,
        formattedCardNumber,
        comment,
        items,
        createdAt,
        timeline,
      ];
      
  OrderModel copyWith({
    int? id,
    String? orderNumber,
    String? status,
    String? statusDisplay,
    String? customerName,
    String? address,
    double? totalAmount,
    double? deliveryFee,
    double? bonusAmount,
    double? loyaltyPayment,
    String? formattedCardNumber,
    String? comment,
    List<OrderItem>? items,
    DateTime? createdAt,
    OrderTimeline? timeline,
    String? paymentMethod,
    String? checkImagePath,
    String? paymentCardInfo,
    DateTime? paidAt,
    DateTime? confirmedAt,
    LocationModel? deliveryAddressModel,
  }) {
    return OrderModel(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      status: status ?? this.status,
      statusDisplay: statusDisplay ?? this.statusDisplay,
      customerName: customerName ?? this.customerName,
      address: address ?? this.address,
      totalAmount: totalAmount ?? this.totalAmount,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      bonusAmount: bonusAmount ?? this.bonusAmount,
      loyaltyPayment: loyaltyPayment ?? this.loyaltyPayment,
      formattedCardNumber: formattedCardNumber ?? this.formattedCardNumber,
      comment: comment ?? this.comment,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      timeline: timeline ?? this.timeline,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      checkImagePath: checkImagePath ?? this.checkImagePath,
      paymentCardInfo: paymentCardInfo ?? this.paymentCardInfo,
      paidAt: paidAt ?? this.paidAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      deliveryAddressModel: deliveryAddressModel ?? this.deliveryAddressModel,
    );
  }
}

class OrderItem extends Equatable {
  final int id;
  final String name;
  final Map<String, String>? names; // Multilingual names
  final int quantity;
  final double price;
  final double totalPrice;
  final String measure;
  final List<String> images;
  final String description;
  final Map<String, String>? descriptions; // Multilingual descriptions

  const OrderItem({
    required this.id,
    required this.name,
    this.names,
    required this.quantity,
    required this.price,
    required this.totalPrice,
    required this.measure,
    required this.images,
    required this.description,
    this.descriptions,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    // Parse multilingual names
    Map<String, String>? namesMap;
    if (json['names'] != null && json['names'] is Map) {
      namesMap = (json['names'] as Map).map((key, value) => MapEntry(
        key.toString(), 
        value?.toString() ?? '',
      ));
    }

    // Parse multilingual descriptions
    Map<String, String>? descriptionsMap;
    if (json['descriptions'] != null && json['descriptions'] is Map) {
      descriptionsMap = (json['descriptions'] as Map).map((key, value) => MapEntry(
        key.toString(), 
        value?.toString() ?? '',
      ));
    }

    // Get default name
    String defaultName = '';
    if (json['name'] != null && json['name'].toString().isNotEmpty) {
      defaultName = json['name'];
    } else if (namesMap != null && namesMap.isNotEmpty) {
      // Priority: uz, ru, en, kr. If all null, use the first available non-empty value
      defaultName = namesMap['uz'] ?? namesMap['ru'] ?? namesMap['en'] ?? namesMap['kr'] ?? '';
      if (defaultName.isEmpty) {
        for (final val in namesMap.values) {
          if (val.isNotEmpty) {
            defaultName = val;
            break;
          }
        }
      }
    }

    // Get default description
    String defaultDescription = '';
    if (json['description'] != null && json['description'].toString().isNotEmpty) {
      defaultDescription = json['description'];
    } else if (descriptionsMap != null && descriptionsMap.isNotEmpty) {
      defaultDescription = descriptionsMap['uz'] ?? descriptionsMap['ru'] ?? descriptionsMap['en'] ?? descriptionsMap['kr'] ?? '';
      if (defaultDescription.isEmpty) {
        for (final val in descriptionsMap.values) {
          if (val.isNotEmpty) {
            defaultDescription = val;
            break;
          }
        }
      }
    }

    return OrderItem(
      id: json['product_id'] ?? json['id'] ?? 0,
      name: defaultName,
      names: namesMap,
      quantity: json['quantity'] ?? 0,
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      totalPrice: double.tryParse(json['total_item_price']?.toString() ?? json['total_price']?.toString() ?? '0') ?? 0.0,
      measure: json['measure']?.toString() ?? '',
      images: (json['images'] as List?)?.map((e) => e.toString()).toList() ?? [],
      description: defaultDescription,
      descriptions: descriptionsMap,
    );
  }
  
  /// Helper function to get the localized string or fallback
  String _getLocalizedText(Map<String, String>? map, String fallback) {
    if (map == null || map.isEmpty) return fallback;
    
    // First try the current locale
    // We assume 'uz' is the default if not using context, but in UI usually 
    // it's better to pass context. Here we use 'uz' as default preference.
    // However, if the value is null or empty, we must fallback.
    if (map.containsKey('uz') && map['uz'] != null && map['uz']!.isNotEmpty) {
      return map['uz']!;
    }
    
    // Fallback to any other language that has a non-null, non-empty value
    for (final value in map.values) {
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    
    return fallback;
  }

  /// Get product name in Uzbek (prioritized) or fallback
  String get displayName {
    return _getLocalizedText(names, name.isNotEmpty ? name : 'mahsulot'.tr());
  }

  /// Get description in Uzbek (prioritized) or fallback
  String get displayDescription {
    return _getLocalizedText(descriptions, description);
  }

  // Compatibility getters if used in UI
  int get productId => id;
  String get productName => name;
  String get productImage => images.isNotEmpty ? images.first : '';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'names': names,
      'quantity': quantity,
      'price': price,
      'total_price': totalPrice,
      'measure': measure,
      'images': images,
      'description': description,
      'descriptions': descriptions,
    };
  }

  @override
  List<Object?> get props => [id, name, names, quantity, price, totalPrice, measure, images, descriptions];
}

/// Paginated order list response (count, next, previous, results).
class OrderListResponse {
  final int? count;
  final String? next;
  final String? previous;
  final List<OrderModel> results;

  OrderListResponse({
    this.count,
    this.next,
    this.previous,
    this.results = const [],
  });

  factory OrderListResponse.fromJson(Map<String, dynamic> json) {
    List<dynamic> resultsList = json['results'] as List<dynamic>? ?? [];
    return OrderListResponse(
      count: json['count'] is int ? json['count'] as int : null,
      next: json['next']?.toString(),
      previous: json['previous']?.toString(),
      results: resultsList
          .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
