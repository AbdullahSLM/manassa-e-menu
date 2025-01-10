import 'package:manassa_e_commerce/models/item.dart';
import 'package:manassa_e_commerce/utils.dart';
import 'package:equatable/equatable.dart';

class InvoiceItem extends Equatable {
  final Item item;
  final String? size;
  final int quantity;

  const InvoiceItem({
    required this.item,
    this.size,
    required this.quantity,
  });

  InvoiceItem.copyWith(
    InvoiceItem cartItem, {
    Item? item,
    String? size,
    int? quantity,
  })  : item = item ?? cartItem.item,
        size = size ?? cartItem.size,
        quantity = quantity ?? cartItem.quantity;

  InvoiceItem copyWith({
    Item? item,
    String? size,
    int? quantity,
  }) {
    return InvoiceItem.copyWith(
      this,
      item: item,
      size: size,
      quantity: quantity,
    );
  }

  InvoiceItem increase(int quantity) {
    return InvoiceItem.copyWith(
      this,
      quantity: this.quantity + quantity,
    );
  }

  InvoiceItem decrease(int quantity) {
    return InvoiceItem.copyWith(
      this,
      quantity: this.quantity - quantity,
    );
  }

  double get originalPrice => item.price * quantity;

  double get totalPrice => item.discountedPrice * quantity;

  double get totalDiscount => (item.discount ?? 0) * quantity;

  @override
  List<Object?> get props => [
        item,
        size,
        quantity,
        totalPrice,
      ];


  JsonMap toJson() {
    return {
      'item': item.toJson(),
      'size': size,
      'quantity': quantity,
    };
  }

  static InvoiceItem fromJson(Map<String, dynamic> item) {
    return InvoiceItem(
      item: Item.fromJson(item['item']),
      size: item['size'],
      quantity: item['quantity'],
    );
  }
}
