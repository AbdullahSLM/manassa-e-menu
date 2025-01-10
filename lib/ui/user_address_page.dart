import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:manassa_e_commerce/main.dart';

final nameProvider = StateProvider((ref) => sharedPreferences.getString('name') ?? '');
final phoneProvider = StateProvider((ref) => sharedPreferences.getString('phone') ?? '');
final addressProvider = StateProvider((ref) => sharedPreferences.getString('address') ?? '');
final noteProvider = StateProvider((ref) => sharedPreferences.getString('note') ?? '');
final locationProvider = StateProvider<LatLng>(
  (ref) => LatLng(
    sharedPreferences.getDouble('latitude') ?? 32.904396192173024,
    sharedPreferences.getDouble('longitude') ?? 13.262683314191843,
  ),
);

class UserAddressPage extends ConsumerWidget {
  const UserAddressPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    return Scaffold(
      appBar: AppBar(
        title: const Text('بيانات المستلم'),
      ),
      body: width > 600 ? pcBody(context, ref) : mobileBody(context, ref),
    );
  }

  Widget pcBody(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextFormField(
                            decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'اسم المستلم'),
                            initialValue: ref.read(nameProvider),
                            onSaved: (txt) => ref.read(nameProvider.notifier).state = txt ?? '',
                            onChanged: (txt) => ref.read(nameProvider.notifier).state = txt,
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextFormField(
                            decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'رقم هاتف المستلم'),
                            initialValue: ref.read(phoneProvider),
                            onSaved: (txt) => ref.read(phoneProvider.notifier).state = txt ?? '',
                            onChanged: (txt) => ref.read(phoneProvider.notifier).state = txt,
                            keyboardType: TextInputType.phone,
                            autocorrect: false,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextFormField(
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'عنوان الاستلام',
                              hintText: 'المدينة، المنطقة، الشارع، أقرب نقطة دالة',
                            ),
                            initialValue: ref.read(addressProvider),
                            onSaved: (txt) => ref.read(addressProvider.notifier).state = txt ?? '',
                            onChanged: (txt) => ref.read(addressProvider.notifier).state = txt,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextFormField(
                            decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'ملاحظة'),
                            initialValue: ref.read(noteProvider),
                            maxLines: 3,
                            onSaved: (txt) => ref.read(noteProvider.notifier).state = txt ?? '',
                            onChanged: (txt) => ref.read(noteProvider.notifier).state = txt,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10.0),
                        child: AspectRatio(
                          aspectRatio: 4 / 3,
                          child: FlutterMap(
                            options: MapOptions(
                              initialCenter: ref.watch(locationProvider),
                              initialZoom: 15.0,
                              onTap: (tapPosition, point) => ref.watch(locationProvider.notifier).state = point,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                                subdomains: const ['a', 'b', 'c'],
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    width: 80.0,
                                    height: 80.0,
                                    point: ref.watch(locationProvider),
                                    child: const Icon(Icons.location_on, color: Colors.red, size: 40.0),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _isValid(ref) ? confirm(context, ref) : null,
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }

  Widget mobileBody(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextFormField(
                      decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'اسم المستلم'),
                      initialValue: ref.read(nameProvider),
                      onSaved: (txt) => ref.read(nameProvider.notifier).state = txt ?? '',
                      onChanged: (txt) => ref.read(nameProvider.notifier).state = txt,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextFormField(
                      decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'رقم هاتف المستلم'),
                      initialValue: ref.read(phoneProvider),
                      onSaved: (txt) => ref.read(phoneProvider.notifier).state = txt ?? '',
                      onChanged: (txt) => ref.read(phoneProvider.notifier).state = txt,
                      keyboardType: TextInputType.phone,
                      autocorrect: false,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextFormField(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'عنوان الاستلام',
                        hintText: 'المدينة، المنطقة، الشارع، أقرب نقطة دالة',
                      ),
                      initialValue: ref.read(addressProvider),
                      onSaved: (txt) => ref.read(addressProvider.notifier).state = txt ?? '',
                      onChanged: (txt) => ref.read(addressProvider.notifier).state = txt,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextFormField(
                      decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'ملاحظة'),
                      maxLines: 3,
                      initialValue: ref.read(noteProvider),
                      onSaved: (txt) => ref.read(noteProvider.notifier).state = txt ?? '',
                      onChanged: (txt) => ref.read(noteProvider.notifier).state = txt,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10.0),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: ref.watch(locationProvider),
                          initialZoom: 15.0,
                          onLongPress: (tapPosition, point) {
                            ref.watch(locationProvider.notifier).state = point;
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                            subdomains: const ['a', 'b', 'c'],
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                width: 80.0,
                                height: 80.0,
                                point: ref.watch(locationProvider),
                                child: const Icon(
                                  Icons.location_on,
                                  color: Colors.red,
                                  size: 40.0,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _isValid(ref) ? confirm(context, ref) : null,
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }

  bool _isValid(WidgetRef ref) {
    return ref.watch(nameProvider).trim().isNotEmpty && ref.watch(phoneProvider).trim().isNotEmpty && ref.watch(addressProvider).trim().isNotEmpty;
  }

  VoidCallback confirm(BuildContext context, WidgetRef ref) {
    sharedPreferences.setString('name', ref.read(nameProvider));
    sharedPreferences.setString('phone', ref.read(phoneProvider));
    sharedPreferences.setString('address', ref.read(addressProvider));
    sharedPreferences.setString('note', ref.read(noteProvider));
    sharedPreferences.setDouble('latitude', ref.watch(locationProvider).latitude);
    sharedPreferences.setDouble('longitude', ref.watch(locationProvider).longitude);

    return () => Navigator.pushNamed(context, '/checkout');
  }
}
