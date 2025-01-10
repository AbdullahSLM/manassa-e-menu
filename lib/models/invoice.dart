import 'package:manassa_e_commerce/models/invoice_item.dart';
import 'package:manassa_e_commerce/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus { pending, inProgress, delivered, canceled }

enum PaymentStatus { unpaid, partiallyPaid, fullyPaid }

T enumFromString<T>(String value, List<T> enumValues) {
  return enumValues.firstWhere(
    (e) => e.toString().split('.').last == value,
    orElse: () => enumValues.first,
  );
}

class Invoice {
  final String? id;
  final String recipientName;
  final String recipientPhone;
  final String recipientAddress;
  final double latitude;
  final double longitude;
  final Iterable<InvoiceItem> invoiceItems;
  final String? note;
  final String? internalNote;
  final OrderStatus orderStatus;
  final PaymentStatus paymentStatus;
  final Timestamp? createAt;

  const Invoice({
    this.id,
    required this.recipientName,
    required this.recipientPhone,
    required this.recipientAddress,
    required this.latitude,
    required this.longitude,
    required this.invoiceItems,
    this.note,
    this.internalNote,
    this.orderStatus = OrderStatus.pending,
    this.paymentStatus = PaymentStatus.unpaid,
    this.createAt,
  });

  double get original {
    var original = 0.0;
    for (final cartItem in invoiceItems) {
      original += cartItem.originalPrice;
    }
    return original;
  }

  double get total {
    var total = 0.0;
    for (final cartItem in invoiceItems) {
      total += cartItem.totalPrice;
    }
    return total;
  }

  double get savings => original - total;

  Invoice copyWith({
    String? id,
    String? recipientName,
    String? recipientPhone,
    String? recipientAddress,
    double? latitude,
    double? longitude,
    Iterable<InvoiceItem>? invoiceItems,
    String? note,
    String? internalNote,
    OrderStatus? orderStatus,
    PaymentStatus? paymentStatus,
  }) {
    return Invoice(
      id: id ?? this.id,
      recipientName: recipientName ?? this.recipientName,
      recipientPhone: recipientPhone ?? this.recipientPhone,
      recipientAddress: recipientAddress ?? this.recipientAddress,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      invoiceItems: invoiceItems ?? this.invoiceItems,
      note: note ?? this.note,
      internalNote: internalNote ?? this.internalNote,
      orderStatus: orderStatus ?? this.orderStatus,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      createAt: createAt,
    );
  }

  JsonMap toJson() {
    return {
      'id': id,
      'recipientName': recipientName,
      'recipientPhone': recipientPhone,
      'recipientAddress': recipientAddress,
      'latitude': latitude,
      'longitude': longitude,
      'invoiceItems': invoiceItems.map((item) => item.toJson()).toList(),
      'note': note,
      'internalNote': internalNote,
      'orderStatus': orderStatus.toString().split('.').last,
      'paymentStatus': paymentStatus.toString().split('.').last,
      'createAt': FieldValue.serverTimestamp(),
    };
  }

  static Invoice fromJson(Map<String, dynamic> data) {
    final invoiceItems = List<InvoiceItem>.from(
      data['invoiceItems'].map((item) => InvoiceItem.fromJson(item)),
    );

    return Invoice(
      id: data['id'],
      recipientName: data['recipientName'],
      recipientPhone: data['recipientPhone'],
      recipientAddress: data['recipientAddress'],
      latitude: data['latitude'],
      longitude: data['longitude'],
      invoiceItems: invoiceItems,
      note: data['note'],
      internalNote: data['internalNote'],
      // orderStatus: OrderStatus.values.firstWhere(
      //   (e) => e.toString() == 'DeliveryStatus.${data['orderStatus']}',
      //   orElse: () => OrderStatus.pending,
      // ),
      orderStatus: enumFromString<OrderStatus>(data['orderStatus'].toString(), OrderStatus.values.toList()),
      // paymentStatus: PaymentStatus.values.firstWhere(
      //   (e) => e.toString() == 'PaymentStatus.${data['paymentStatus']}',
      //   orElse: () => PaymentStatus.unpaid,
      // ),
      paymentStatus: enumFromString<PaymentStatus>(data['paymentStatus'].toString(), PaymentStatus.values.toList()),
      createAt: data['createAt'],
    );
  }
}
