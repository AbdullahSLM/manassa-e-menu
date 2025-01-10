import 'package:manassa_e_commerce/models/item.dart';
import 'package:manassa_e_commerce/ui/widgets/item_card.dart';
import 'package:flutter/material.dart';

class ItemsGridView extends StatelessWidget {
  final Iterable<Item> items;
  final bool editable;

  const ItemsGridView({super.key, required this.items, this.editable = false});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      // TODO: Implement infinite pagination scroll here

      builder: (context, constraints) {
        int crossAxisCount(BoxConstraints constraints) {
          return (constraints.maxWidth / 500).ceil();
        }

        double aspectRatio(BoxConstraints constraints) {
          final width = constraints.maxWidth / crossAxisCount(constraints);

          /*
           image carousel:
           carousel indicators: 36
           name: 64
           description: 128
           sizes: 64
           footer: 64
           */
          // image carousel + carousel indicators + name and footer
          // final height = width / (16 / 9) + 36 + 128 + 118;
          final height = width / (16 / 9) + 36 + 128 + 128;
          return width / height;
        }

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount(constraints),
            childAspectRatio: aspectRatio(constraints),
          ),
          shrinkWrap: true,
          physics: const ClampingScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (BuildContext context, int index) {
            return ItemCard(item: items.elementAt(index), editable: editable);
          },
        );
      },
    );
  }
}
