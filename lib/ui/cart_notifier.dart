import 'package:manassa_e_commerce/models/invoice_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CartNotifier extends StateNotifier<List<InvoiceItem>> {
  CartNotifier() : super([]);

  static final itemsProvider =
      StateNotifierProvider<CartNotifier, List<InvoiceItem>>(
    (ref) => CartNotifier(),
  );

  static final groupedItemsProvider = StateProvider<List<InvoiceItem>>(
    (ref) {
      final items = ref.watch(CartNotifier.itemsProvider);

      final invoiceItems = <InvoiceItem>[];
      for (int index = items.length - 1; index >= 0; index--) {
        final item = items[index];
        var cartItem = item.copyWith();
        for (InvoiceItem cartItem0 in invoiceItems) {
          if (cartItem0 == item) {
            cartItem = cartItem0.increase(1);

            invoiceItems.remove(cartItem0);
            break;
          }
        }
        invoiceItems.add(cartItem);
      }
      return invoiceItems;
    },
  );

  void addItem(InvoiceItem cartItem) {
    final index = state.indexWhere(
      (cartItem0) =>
          cartItem.item == cartItem0.item && cartItem.size == cartItem0.size,
    );

    if (index == -1) {
      state = [...state, cartItem.copyWith()];
    } else {
      final currentItem = state[index].increase(cartItem.quantity);
      final items = List<InvoiceItem>.from(state);
      items.replaceRange(index, index + 1, [currentItem]);
      state = items;
    }
  }
  
  void removeItem(InvoiceItem cartItem) {
    final index = state.indexWhere(
          (cartItem0) =>
      cartItem.item == cartItem0.item && cartItem.size == cartItem0.size,
    );

    if(index != -1) {
      final currentItem = state[index].decrease(cartItem.quantity);
      final items = List<InvoiceItem>.from(state);
      if(currentItem.quantity > 0) {
        items.replaceRange(index, index + 1, [currentItem]);
      } else {
        items.removeAt(index);
      }
      state = items;
    }
  }

  void setQuantity(InvoiceItem item, int quantity) {}

  void empty() {
    state = [];
  }
}
