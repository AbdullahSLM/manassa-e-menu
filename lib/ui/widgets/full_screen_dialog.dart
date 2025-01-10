import 'package:manassa_e_commerce/models/item.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_view/photo_view.dart';

final currentImage = StateProvider(
  (ref) => const Manassa_e_commerceImages(
    thumbImage: 'https://i.postimg.cc/bd3c6dQ9/Manassa_e_commerce-Logo-2.jpg',
    fullHDImage: 'https://i.postimg.cc/Gh1LmytV/Manassa_e_commerce-Logo-2.jpg',
  ),
);

final controller = AutoDisposeProvider((ref) => PhotoViewController());

class FullScreenDialog extends ConsumerWidget {
  final List<Manassa_e_commerceImages> images;
  final Manassa_e_commerceImages initialImage;

  const FullScreenDialog({
    super.key,
    required this.images,
    required this.initialImage,
  });

  @override
  Widget build(context, ref) {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      ref.read(currentImage.notifier).state = initialImage;
    });

    return Dialog(
      alignment: Alignment.center,
      // backgroundColor: Theme.of(context).colorScheme.onPrimary,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Stack(
              children: [
                Consumer(builder: (context, ref, child) {
                  return PhotoView(
                    imageProvider: CachedNetworkImageProvider(
                      ref.watch(currentImage).fullHDImage,
                    ),
                    backgroundDecoration: const BoxDecoration(
                      color: Colors.transparent,
                    ),
                    controller: ref.read(controller),
                    errorBuilder: (context, error, stackTrace) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error, size: 45, color: Colors.red[200]),
                          Text('تعذر تحميل الصورة', style: TextStyle(color: Colors.red[200])),
                        ],
                      ),
                    ),
                  );
                }),
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.cancel_outlined),
                      splashRadius: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Consumer(
            builder: (context, ref, child) {
              return Wrap(
                alignment: WrapAlignment.center,
                children: [
                  for (final image in images)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: InkWell(
                        onTap: () {
                          ref.read(currentImage.notifier).state = image;
                          ref.read(controller).scale = 1;
                        },
                        child: Stack(
                          children: [
                            SizedBox(
                              width: 50,
                              height: 50,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(5),
                                child: CachedNetworkImage(
                                  imageUrl: image.thumbImage,
                                  fit: BoxFit.cover,
                                  errorWidget: (context, url, error) => Icon(Icons.error, color: Colors.red[200]),
                                ),
                              ),
                            ),
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: _getOverlayColor(ref, image),
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Color _getBorderColor(WidgetRef ref, Manassa_e_commerceImages image) {
    return image == ref.watch(currentImage) ? Colors.black : Colors.grey;
  }

  Color _getOverlayColor(WidgetRef ref, Manassa_e_commerceImages image) {
    return image == ref.watch(currentImage) ? Colors.transparent : Colors.grey.withOpacity(0.5);
  }
}
