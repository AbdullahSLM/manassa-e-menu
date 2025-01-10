import 'dart:async';
import 'dart:convert';
import 'package:manassa_e_commerce/db/db.dart';
import 'package:manassa_e_commerce/models/item.dart';
import 'package:manassa_e_commerce/ui/app.dart';
import 'package:manassa_e_commerce/ui/appearance_page.dart';
import 'package:manassa_e_commerce/ui/widgets/custom_indicator.dart';
import 'package:manassa_e_commerce/utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _emptyItem = Item(
  name: '',
  sizes: [],
  images: [],
  price: 0.0,
);

final _originalItem = StateProvider((ref) => _emptyItem);

final _currentItem = StateProvider((ref) => ref.watch(_originalItem));

class _JsonError {
  final FormatException exception;
  final StackTrace stackTrace;

  _JsonError(this.exception, this.stackTrace);
}

final _jsonError = StateProvider<_JsonError?>((ref) => null);

final _canSave = StateProvider(
  (ref) {
    return ref.watch(_originalItem) != ref.watch(_currentItem) && ref.watch(_jsonError) == null;
  },
);

class AddEditItemPage extends ConsumerWidget {
  final Item? item;
  final String? id;

  const AddEditItemPage({super.key, this.item, this.id});

  @override
  Widget build(context, ref) {
    // _jsonError need to be reset to remove previous state if set.
    WidgetsBinding.instance.addPostFrameCallback(
      (timeStamp) => ref.read(_jsonError.notifier).state = null,
    );

    if (item != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (timeStamp) => ref.read(_originalItem.notifier).state = item!,
      );
      return const _AddEditItemPage();
    } else if (id != null) {
      return FutureBuilder<Item?>(
        future: Database.getItem(id!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasData) {
              ref.read(_originalItem.notifier).state = snapshot.requireData!;
              return const _AddEditItemPage();
            }
          } else if (snapshot.connectionState == ConnectionState.waiting) {
            return const CustomIndicator();
          }
          return Text('Error!! ${snapshot.error}');
        },
      );
    } else {
      // Ensure that _original item is _emptyItem
      WidgetsBinding.instance.addPostFrameCallback(
        (timeStamp) => ref.read(_originalItem.notifier).state = _emptyItem,
      );
      return const _AddEditItemPage();
    }
  }
}

class _AddEditItemPage extends StatelessWidget {
  const _AddEditItemPage();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            actions: [
              Consumer(builder: (context, ref, child) {
                return IconButton(
                  onPressed: ref.watch(_canSave) && ref.watch(_currentItem).images.isNotEmpty
                      ? () {
                          final future = Database.addUpdateItem(ref.read(_currentItem));

                          future.catchError((error, stacktrace) {
                            // TODO: show an error message
                          });

                          future.then((item) {
                            ref.read(_originalItem.notifier).state = item;
                            ref.read(_currentItem.notifier).state = item;
                            if (context.mounted) {
                              showDialog(
                                context: context,
                                builder: (context) => const SuccessDialog(),
                              );
                            }
                          });
                        }
                      : null,
                  icon: const Icon(Icons.check),
                );
              }),
            ],
          ),
          body: const _VisualFormItem(),
          // _JsonFormItem(),
        ),
      ),
    );
  }
}

class _JsonFormItem extends StatelessWidget {
  const _JsonFormItem();

  @override
  Widget build(BuildContext context) {
    Timer timer = Timer(const Duration(milliseconds: 100), () {});

    final controller = TextEditingController();

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Consumer(
          builder: (context, ref, child) {
            final selection = controller.selection;
            controller.text = Utils.getPrettyString(ref.watch(_currentItem).toJson());
            try {
              controller.selection = selection;
            } catch (e) {
              // Sometimes error happened
            }
            return Consumer(
              builder: (context, ref, child) {
                return TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    filled: true,
                    // fillColor: ref.watch(_jsonError) == null ? Colors.transparent : Colors.red.shade50,
                  ),
                  scrollPadding: const EdgeInsets.all(8.0),
                  keyboardType: TextInputType.multiline,
                  maxLines: 0xffff,
                  autofocus: true,
                  onChanged: (txt) {
                    if (timer.isActive) timer.cancel();
                    timer = Timer(
                      const Duration(milliseconds: 100),
                      () {
                        try {
                          final currentItem = Item.fromJson(json.decode(txt));
                          ref.read(_currentItem.notifier).state = currentItem;

                          // Reset _jsonError
                          ref.read(_jsonError.notifier).state = null;
                        } on FormatException catch (exception, stackTrace) {
                          ref.read(_jsonError.notifier).state = _JsonError(exception, stackTrace);
                          debug(exception);
                        }
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _VisualFormItem extends StatelessWidget {
  const _VisualFormItem();

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, child) {
      final originalItem = ref.watch(_originalItem);
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'الحقل الذي يحتوي على رمز النجمة   ( * )   إلزامي',
                style: TextStyle(color: Colors.red[200], fontWeight: FontWeight.w100),
              ),
              const SizedBox(height: 16),
              // Name Field
              TextFormField(
                key: GlobalKey(),
                cursorErrorColor: Colors.red,
                initialValue: originalItem.name,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'الإسم *',
                  filled: true,
                ),
                onChanged: (txt) {
                  final currentItem = ref.read(_currentItem);
                  ref.read(_currentItem.notifier).state = currentItem.copyWith(name: txt);
                },
              ),
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.0),
                child: Text('صور المنتج *'),
              ),
              // List of images
              SizedBox(
                height: 160,
                child: Consumer(
                  builder: (context, ref, child) {
                    final List<Manassa_e_commerceImages> images = ref.watch(_currentItem.select((item) => item.images.isNotEmpty ? item.images : []));
                    return ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: TextButton(
                            style: ButtonStyle(
                              shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  side: BorderSide(color: Theme.of(context).colorScheme.primary),
                                ),
                              ),
                              minimumSize: const WidgetStatePropertyAll(Size.square(160.0)),
                            ),
                            onPressed: () {
                              _showImageDialog(
                                context,
                                image: null,
                                onSave: (newImage) {
                                  final currentItem = ref.read(_currentItem);
                                  var updatedImages = [...images, newImage];
                                  ref.read(_currentItem.notifier).state = currentItem.copyWith(
                                    images: updatedImages,
                                  );
                                },
                              );
                            },
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add),
                                Text("إضافة صورة جديدة"),
                              ],
                            ),
                          ),
                        ),
                        for (var i = 0; i < images.length; i++)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: IntrinsicWidth(
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Theme.of(context).colorScheme.primary),
                                  borderRadius: const BorderRadius.all(Radius.circular(8.0)),
                                ),
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: ClipRRect(
                                          borderRadius: const BorderRadius.all(Radius.circular(6.0)),
                                          child: CachedNetworkImage(
                                            imageUrl: images[i].thumbImage,
                                            height: 100,
                                            fit: BoxFit.scaleDown,
                                            placeholder: (_, __) => const CustomIndicator(),
                                            errorWidget: (context, error, stackTrace) {
                                              return SizedBox(
                                                height: 100,
                                                child: Center(
                                                  child: Text(
                                                    'تعذر تحميل الصورة',
                                                    style: TextStyle(color: Colors.red[200]),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        TextButton(
                                          onPressed: () {
                                            _showImageDialog(
                                              context,
                                              image: images[i],
                                              onSave: (updatedImage) {
                                                final currentItem = ref.read(_currentItem);
                                                var updatedImages = [...images];
                                                updatedImages[i] = updatedImage;
                                                ref.read(_currentItem.notifier).state = currentItem.copyWith(
                                                  images: updatedImages,
                                                );
                                              },
                                            );
                                          },
                                          child: const Text("تعديل"),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  title: const Text('تأكيد الحذف'),
                                                  content: const Text('هل أنت متأكد أنك تريد حذف هذه الصورة؟'),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () => Navigator.of(context).pop(),
                                                      child: const Text('إلغاء'),
                                                    ),
                                                    TextButton(
                                                      onPressed: () {
                                                        final currentItem = ref.read(_currentItem);
                                                        var updatedImages = [...images];
                                                        updatedImages.removeAt(i);
                                                        ref.read(_currentItem.notifier).state = currentItem.copyWith(images: updatedImages);
                                                        Navigator.of(context).pop();
                                                      },
                                                      child: const Text('حذف'),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          },
                                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                                          child: const Text('حذف'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              const Divider(height: 24.0),
              // List of Sizes
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.0),
                child: Text('الأحجام'),
              ),
              SizedBox(
                height: 80,
                child: Consumer(
                  builder: (context, ref, child) {
                    final sizes = ref.watch(_currentItem.select((item) => item.sizes));
                    return ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: TextButton(
                            style: ButtonStyle(
                              shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  side: BorderSide(color: Theme.of(context).colorScheme.primary),
                                ),
                              ),
                              minimumSize: const WidgetStatePropertyAll(Size.square(80.0)),
                            ),
                            onPressed: () {
                              var updatedSizes = [...sizes, ''];
                              ref.read(_currentItem.notifier).state = ref.read(_currentItem).copyWith(sizes: updatedSizes);
                            },
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add),
                                Text("إضافة حجم جديد"),
                              ],
                            ),
                          ),
                        ),
                        for (var i = 0; i < sizes.length; i++)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: Container(
                              width: 100,
                              decoration: BoxDecoration(
                                border: Border.all(color: Theme.of(context).colorScheme.primary),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Column(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: sizes[i],
                                      textAlign: TextAlign.center,
                                      textAlignVertical: TextAlignVertical.bottom,
                                      decoration: const InputDecoration(border: InputBorder.none, filled: true),
                                      onChanged: (txt) {
                                        final currentItem = ref.read(_currentItem);
                                        var updatedSizes = [...sizes];
                                        updatedSizes[i] = txt;
                                        ref.read(_currentItem.notifier).state = currentItem.copyWith(sizes: updatedSizes);
                                      },
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      final currentItem = ref.read(_currentItem);
                                      var updatedSizes = [...sizes];
                                      updatedSizes.removeAt(i);
                                      ref.read(_currentItem.notifier).state = currentItem.copyWith(
                                        sizes: updatedSizes,
                                      );
                                    },
                                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                                    child: const Text('حذف'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 24.0),

              // Price and Discount Fields
              Row(
                children: [
                  // Price Field
                  Flexible(
                    child: TextFormField(
                      key: GlobalKey(),
                      initialValue: originalItem.price != 0 ? '${originalItem.price}' : null,
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'سعر',
                        alignLabelWithHint: true,
                        filled: true,
                        suffixIcon: Text(currency),
                      ),
                      onChanged: (txt) {
                        ref.read(_currentItem.notifier).state = ref.read(_currentItem).copyWith(price: double.tryParse(txt));
                      },
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  // Discount Field and Switch
                  Flexible(
                    child: TextFormField(
                      key: GlobalKey(),
                      initialValue: originalItem.discount != null && originalItem.discount != 0 ? '${originalItem.discount}' : null,
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'التخفيض',
                        alignLabelWithHint: true,
                        filled: true,
                        suffixIcon: Text(currency),
                        suffixStyle: TextStyle(fontSize: 20),
                      ),
                      onChanged: (txt) {
                        ref.read(_currentItem.notifier).state = ref.read(_currentItem).copyWith(discount: double.tryParse(txt));
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24.0),

              // Description Field
              TextFormField(
                initialValue: originalItem.description ?? '',
                maxLines: 3,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'الوصف',
                  alignLabelWithHint: true,
                  filled: true,
                ),
                onChanged: (txt) {
                  ref.read(_currentItem.notifier).state = ref.read(_currentItem).copyWith(description: txt);
                },
              ),
            ],
          ),
        ),
      );
    });
  }

  Future<void> _showImageDialog(
    BuildContext context, {
    Manassa_e_commerceImages? image,
    required void Function(Manassa_e_commerceImages) onSave,
  }) async {
    final TextEditingController thumbController = TextEditingController(
      text: image?.thumbImage ?? '',
    );
    final TextEditingController fullHDController = TextEditingController(
      text: image?.fullHDImage ?? '',
    );

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 200, // تحديد أقصى عرض للنافذة
          ),
          child: AlertDialog(
            title: const Text('إضافة / تعديل صورة'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: thumbController,
                  decoration: const InputDecoration(
                    labelText: 'رابط الصورة المصغرة',
                  ),
                ),
                TextField(
                  controller: fullHDController,
                  decoration: const InputDecoration(
                    labelText: 'رابط الصورة عالية الدقة',
                  ),
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('إلغاء'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text('حفظ'),
                onPressed: () {
                  final updatedImage = Manassa_e_commerceImages(
                    thumbImage: thumbController.text,
                    fullHDImage: fullHDController.text,
                  );
                  onSave(updatedImage);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
