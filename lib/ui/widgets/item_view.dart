import 'package:manassa_e_commerce/db/db.dart';
import 'package:manassa_e_commerce/models/invoice_item.dart';
import 'package:manassa_e_commerce/models/item.dart';
import 'package:manassa_e_commerce/ui/cart_notifier.dart';
import 'package:manassa_e_commerce/ui/widgets/custom_indicator.dart';
import 'package:manassa_e_commerce/ui/invoice_viewer.dart';
import 'package:manassa_e_commerce/ui/widgets/full_screen_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ItemView extends StatelessWidget {
  final Item item;
  final bool editable;
  final bool cardView;

  ItemView({super.key, required this.item, this.editable = false, this.cardView = false});

  final sizeProvider = StateProvider<String?>((ref) => null);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (!cardView && !editable)
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: IconButton(
                splashRadius: 18,
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.cancel_outlined),
              ),
            ),
          ),
        Row(
          mainAxisAlignment: editable ? MainAxisAlignment.spaceBetween : MainAxisAlignment.start,
          children: [
            if (cardView && !editable)
              IconButton(
                splashRadius: 18,
                onPressed: () => Navigator.pushNamed(context, '/item/${item.id}', arguments: item),
                icon: const Icon(Icons.info_outline),
              ),
            if (editable)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/edit-item', arguments: item),
                  child: const Text('تعديل'),
                ),
              ),
            if (editable)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextButton(
                  onPressed: () => deleteItemConfirmationDialog(context),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('حذف'),
                ),
              ),
          ],
        ),
        if (item.images.isNotEmpty) ImageCarousel(images: item.images),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Text(
            item.name,
            style: const TextStyle(fontSize: 18),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
            textAlign: TextAlign.center,
          ),
        ),
        if (!cardView && item.description?.isNotEmpty == true)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              item.description!,
              style: const TextStyle(fontSize: 15),
              textAlign: TextAlign.center,
            ),
          ),
        if (item.sizes.isNotEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text('الحجم', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: SizedBox(
            height: 36,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final size in item.sizes)
                    Consumer(
                      builder: (context, ref, widget) {
                        final selected = size == ref.watch(sizeProvider);
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: ActionChip(
                            label: Text(
                              size,
                              style: TextStyle(
                                color: selected ? Theme.of(context).colorScheme.onPrimary : null,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            backgroundColor: selected ? Theme.of(context).colorScheme.primary : null,
                            onPressed: () {
                              final oldSize = ref.read(sizeProvider);
                              ref.read(sizeProvider.notifier).state = oldSize == size ? null : size;
                            },
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
        if (cardView) const Spacer(),
        if (!cardView) const Divider(height: 32),
        footer(),
      ],
    );
  }

  Widget footer() {
    return Row(
      children: [
        const SizedBox(width: 8),
        PriceWidget(price: item.price, discount: item.discount),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Consumer(
            builder: (context, ref, child) {
              return ElevatedButton(
                onPressed: (ref.watch(sizeProvider) != null)
                    ? () => ref.read(CartNotifier.itemsProvider.notifier).addItem(
                          InvoiceItem(
                            item: item,
                            size: ref.read(sizeProvider)!,
                            quantity: 1,
                          ),
                        )
                    : item.sizes.isEmpty
                        ? () => ref.read(CartNotifier.itemsProvider.notifier).addItem(
                              InvoiceItem(
                                item: item,
                                quantity: 1,
                              ),
                            )
                        : null,
                child: const Text('إضافة للسلة'),
              );
            },
          ),
        ),
      ],
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

class ImageCarousel extends StatefulWidget {
  final List<Manassa_e_commerceImages> images;

  const ImageCarousel({super.key, required this.images});

  @override
  State<StatefulWidget> createState() {
    return _ImageCarouselState();
  }
}

class _ImageCarouselState extends State<ImageCarousel> {
  int _current = 0;

  final _controller = CarouselSliderController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CarouselSlider(
          items: [
            //fullHD are keys
            for (final image in widget.images)
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return FullScreenDialog(
                        images: widget.images,
                        initialImage: image,
                      );
                    },
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: CachedNetworkImage(
                    imageUrl: image.fullHDImage,
                    fit: BoxFit.fill,
                    errorWidget: (context, url, error) => Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, color: Colors.red[200]),
                        Text('تعذر تحميل الصورة', style: TextStyle(color: Colors.red[200])),
                      ],
                    ),
                    placeholder: (context, url) => Stack(
                      alignment: Alignment.center,
                      children: [
                        IntrinsicHeight(
                          child: CachedNetworkImage(
                            imageUrl: image.thumbImage,
                            fit: BoxFit.fill,
                            placeholder: (context, url) => const CustomIndicator(),
                            errorWidget: (context, url, error) => Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error, color: Colors.red[200]),
                                Text('تعذر تحميل الصورة', style: TextStyle(color: Colors.red[200])),
                              ],
                            ),
                          ),
                        ),
                        const CustomIndicator(),
                      ],
                    ),
                  ),
                ),
              )
          ],
          carouselController: _controller,
          options: CarouselOptions(
            enlargeCenterPage: true,
            viewportFraction: 1,
            onPageChanged: (index, reason) => setState(() => _current = index),
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            return SizedBox(
              height: 36,
              // width: constraints.maxWidth,
              child: Center(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.images.length,
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    final image = widget.images.elementAt(index);
                    return GestureDetector(
                      onTap: () => _controller.animateToPage(index),
                      child: Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: CircleAvatar(
                          backgroundColor: Colors.black,
                          radius: _getIndicatorSize(index),
                          child: Padding(
                            padding: EdgeInsets.all(index == _current ? 2 : 1),
                            child: CircleAvatar(
                              backgroundImage: CachedNetworkImageProvider(image.thumbImage),
                              onBackgroundImageError: (exception, stackTrace) => Icon(Icons.error, color: Colors.red[200]),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  double _getIndicatorSize(int index) {
    return index == _current ? 16 : 12;
  }
}
