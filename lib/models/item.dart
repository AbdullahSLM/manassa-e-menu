import 'package:manassa_e_commerce/utils.dart';
import 'package:equatable/equatable.dart';

class Item extends Equatable {
  final String? id;
  final String name;
  final int? order;
  final String? description;
  final List<String> sizes;
  final List<Manassa_e_commerceImages> images;
  final double price;
  final double? discount;

  const Item({
    this.id,
    required this.name,
    this.order,
    this.description,
    required this.sizes,
    required this.images,
    required this.price,
    this.discount,
  });

  Item.copyWith(
    Item item, {
    String? id,
    String? name,
    int? order,
    String? description,
    List<String>? sizes,
    List<Manassa_e_commerceImages>? images,
    double? price,
    double? discount,
  })  : id = id ?? item.id,
        name = name ?? item.name,
        order = order ?? item.order,
        description = description ?? item.description,
        sizes = sizes ?? item.sizes,
        images = images ?? item.images,
        price = price ?? item.price,
        discount = discount ?? item.discount;

  Item copyWith({
    String? id,
    String? name,
    int? order,
    String? description,
    List<String>? sizes,
    List<Manassa_e_commerceImages>? images,
    double? price,
    double? discount,
  }) =>
      Item.copyWith(
        this,
        id: id,
        name: name,
        order: order,
        description: description,
        sizes: sizes,
        images: images,
        price: price,
        discount: discount,
      );

  Item.fromJson(JsonMap json)
      : id = json['id'],
        name = json['name'],
        order = json['order'],
        description = json['description'],
        sizes = List.from(json['sizes'] ?? []),
        images = List.unmodifiable([
          for (final jsonMap in json['images']) Manassa_e_commerceImages.fromJson(jsonMap)
        ]),
        price = json['price'].toDouble(),
        discount = json['discount']?.toDouble();

  JsonMap toJson() {
    return {
      'id': id,
      'name': name,
      'order': order,
      'description': description,
      'sizes': sizes,
      'images': images.map((image) => image.toJson()).toList(),
      'price': price,
      'discount': discount,
    };
  }

  @override
  String toString() => 'Item($name)';

  double get discountedPrice => price - (discount ?? 0);

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        ...sizes,
        ...images,
        price,
        discount,
        discountedPrice,
      ];
}

class Manassa_e_commerceImages extends Equatable {
  final String thumbImage;
  final String fullHDImage;

  const Manassa_e_commerceImages({required this.thumbImage, required this.fullHDImage});

  Manassa_e_commerceImages.fromJson(JsonMap json)
      : thumbImage = json['thumbImage'],
        fullHDImage = json['fullHDImage'];

  JsonMap toJson() {
    return  {
      'thumbImage': thumbImage,
      'fullHDImage': fullHDImage,
    };
  }

  @override
  List<Object?> get props => [thumbImage, fullHDImage];


}
