import 'package:manassa_e_commerce/db/db.dart';
import 'package:manassa_e_commerce/models/item.dart';
import 'package:manassa_e_commerce/models/invoice_item.dart';
import 'package:manassa_e_commerce/ui/cart_notifier.dart';
import 'package:manassa_e_commerce/ui/invoice_viewer.dart';
import 'package:manassa_e_commerce/ui/widgets/item_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final resetSizeProvider = StateProvider((ref) => 0);

class ItemCard extends StatelessWidget {
  final Item item;
  final bool editable;

  final sizeProvider = StateProvider<String?>((ref) {
    ref.watch(resetSizeProvider);
    return null;
  });

  ItemCard({super.key, required this.item, this.editable = false});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      child: InkWell(
        onLongPress: () => Navigator.pushNamed(context, '/item/${item.id}', arguments: item),
        // onDoubleTap: () => Navigator.pushNamed(context, '/item/${item.id}', arguments: item),
        child: ItemView(item: item, editable: editable, cardView: true),
      ),
    );
  }

  Widget footer() {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: PriceWidget(price: item.price, discount: item.discount),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Consumer(
            builder: (context, ref, child) {
              return GestureDetector(
                onDoubleTap: (!editable && ref.watch(sizeProvider) != null)
                    ? () {
                        onAddItemToCartTapped(ref);
                        onAddItemToCartTapped(ref);
                      }
                    : null,
                child: ElevatedButton(
                  onPressed: (!editable && ref.watch(sizeProvider) != null) ? () => onAddItemToCartTapped(ref) : null,
                  child: const Text('إضافة للسلة'),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void onAddItemToCartTapped(WidgetRef ref) {
    ref.read(CartNotifier.itemsProvider.notifier).addItem(
          InvoiceItem(
            item: item,
            size: ref.read(sizeProvider)!,
            quantity: 1,
          ),
        );
  }

  void deleteItemConfirmationDialog(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('هل أنت متأكد من أنك تريد حذف هذا العنصر؟'),
          content: Text(item.name),
          actions: [
            ElevatedButton(
              onPressed: () {
                Database.deleteItem(item);
                // TODO: remove from current data
                Navigator.pop(context);
              },
              child: const Text('نعم'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('لا'),
            ),
          ],
        );
      },
    );
  }
}
