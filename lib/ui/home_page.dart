import 'package:manassa_e_commerce/main.dart';
import 'package:manassa_e_commerce/models/item.dart';
import 'package:manassa_e_commerce/models/user.dart';
import 'package:manassa_e_commerce/ui/login_form.dart';
import 'package:manassa_e_commerce/ui/widgets/custom_indicator.dart';
import 'package:manassa_e_commerce/utils.dart';
import 'package:manassa_e_commerce/ui/cart_notifier.dart';
import 'package:manassa_e_commerce/ui/widgets/items_grid_view.dart';
import 'package:manassa_e_commerce/ui/widgets/link_text.dart';
import 'package:badges/badges.dart' as badges;
import 'package:manassa_e_commerce/db/db.dart';
import 'package:manassa_e_commerce/ui/app.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final cartCount = StateProvider((ref) {
  final items = ref.watch(CartNotifier.itemsProvider);
  int count = 0;
  for (var item in items) {
    count += item.quantity;
  }
  return count;
});

final searchText = StateProvider<String>((ref) => '');

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appbar(),
      drawer: drawer(context),
      body: body(),
    );
  }

  PreferredSizeWidget appbar() {
    return AppBar(
      title: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 512, maxHeight: 50),
        child: Consumer(
          builder: (context, ref, child) {
            return SearchBar(
              hintText: 'بحث',
              // shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))),
              leading: Icon(Icons.search, color: Theme.of(context).colorScheme.primary),
              onChanged: (value) => ref.read(searchText.notifier).state = value,
            );
          },
        ),
      ),
      centerTitle: false,
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: ClipRRect(
            child: Image.asset('assets/images/white_logo.webp'),
          ),
        ),
      ],
    );
  }

  Future<bool> isConnected() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult == ConnectivityResult.mobile || connectivityResult == ConnectivityResult.wifi;
  }

  Widget body() {
    return Column(
      children: [
        Expanded(
          child: FutureBuilder(
            future: Database.getHomePageItems(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting || snapshot.connectionState == ConnectionState.active) {
                return const CustomIndicator();
              }
              if (snapshot.connectionState == ConnectionState.done) {
                if (snapshot.hasError) {
                  return Center(child: Text('${snapshot.error}'));
                }
                if (snapshot.hasData) {
                  if (snapshot.data == null || snapshot.data?.isEmpty == true) {
                    return const Center(child: Text('لا توجد بيانات!!!'));
                  }

                  return Consumer(
                    builder: (context, ref, child) {
                      final filteredItems = filter(snapshot.requireData, ref.watch(searchText));

                      if (filteredItems.isEmpty) {
                        return const Center(child: Text('لا توجد نتائج مطابقة!!!'));
                      }

                      return ItemsGridView(items: filteredItems);
                    },
                  );
                }
              }
              return Container();
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Consumer(
            builder: (context, ref, widget) {
              return ElevatedButton(
                onPressed: ref.watch(CartNotifier.itemsProvider).isNotEmpty ? () => Navigator.pushNamed(context, '/cart') : null,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('سلة المشتريات'),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Consumer(
                        builder: (context, ref, widget) {
                          return badges.Badge(
                            position: badges.BadgePosition.custom(
                              start: 30,
                              top: -3,
                            ),
                            badgeAnimation: const badges.BadgeAnimation.scale(
                              disappearanceFadeAnimationDuration: Duration(milliseconds: 100),
                              curve: Curves.easeInCubic,
                            ),
                            showBadge: true,
                            badgeStyle: badges.BadgeStyle(badgeColor: ref.watch(mode) == Mode.dark ? Colors.black : Colors.white),
                            badgeContent: Text(
                              '${ref.watch(cartCount)}',
                              style: TextStyle(color: ref.watch(mode) == Mode.dark ? Colors.white : Colors.black),
                            ),
                            child: const Icon(
                              Icons.shopping_cart_outlined,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

Widget drawer(BuildContext context) {
  return Drawer(
    child: Column(
      children: [
        Expanded(
          child: Consumer(
            builder: (context, ref, child) {
              final user = ref.watch(currentUser);
              final role = user?.role;
              return ListView(
                children: [
                  if (user != null)
                    ListTile(
                      title: Text(user.name),
                      subtitle: Text(user.email),
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      trailing: IconButton(
                        onPressed: () {
                          ref.read(currentUser.notifier).state = null;
                          Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
                        },
                        icon: const Icon(Icons.logout),
                      ),
                      onTap: () {
                        // TODO: go to user details page
                      },
                    ),
                  if (user == null)
                    ListTile(
                      title: const Text('تسجيل الدخول'),
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      trailing: const Icon(Icons.login),
                      onTap: () => login(context),
                    ),
                  ListTile(
                    title: const Row(
                      children: [
                        Icon(Icons.home_outlined),
                        SizedBox(width: 10),
                        Text('الصفحة الرئيسية'),
                      ],
                    ),
                    onTap: () => Navigator.popAndPushNamed(context, '/'),
                  ),
                  if (role == Role.admin)
                    ListTile(
                      onTap: () => Navigator.popAndPushNamed(context, '/items'),
                      title: const Row(
                        children: [
                          Icon(Icons.category_outlined),
                          SizedBox(width: 10),
                          Text('إدارة الأصناف'),
                        ],
                      ),
                    ),
                  if (role == Role.admin || role == Role.moderator)
                    ListTile(
                      onTap: () => Navigator.popAndPushNamed(context, '/invoices'),
                      title: const Row(
                        children: [
                          Icon(CupertinoIcons.doc),
                          SizedBox(width: 10),
                          Text('إدارة الفواتير'),
                        ],
                      ),
                    ),
                  if (role == Role.admin)
                    ListTile(
                      onTap: () => Navigator.popAndPushNamed(context, '/appearance'),
                      title: const Row(
                        children: [
                          Icon(Icons.color_lens_outlined),
                          SizedBox(width: 10),
                          Text('إدارة المظهر'),
                        ],
                      ),
                    ),
                  if (role == Role.admin)
                    ListTile(
                      onTap: () => Navigator.popAndPushNamed(context, '/users'),
                      title: const Row(
                        children: [
                          Icon(Icons.supervised_user_circle_outlined),
                          SizedBox(width: 10),
                          Text('إدارة المستخدمين'),
                        ],
                      ),
                    ),
                  if (role == Role.admin)
                    ListTile(
                      onTap: () => Navigator.popAndPushNamed(context, '/reports'),
                      title: const Row(
                        children: [
                          Icon(CupertinoIcons.doc_chart),
                          SizedBox(width: 10),
                          Text('التقارير'),
                        ],
                      ),
                    ),
                  ListTile(
                    onTap: () => Navigator.popAndPushNamed(context, '/license'),
                    title: const Row(
                      children: [
                        Icon(Icons.local_police_outlined),
                        SizedBox(width: 10),
                        Text('شروط الاستخدام والترخيص'),
                      ],
                    ),
                  ),
                  ListTile(
                    onTap: () {
                      showAboutDialog(context: context);
                      // Navigator.popAndPushNamed(context, '/about');
                    },
                    title: const Row(
                      children: [
                        Icon(Icons.info_outline),
                        SizedBox(width: 10),
                        Text('حول'),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Consumer(
          builder: (context, ref, child) {
            return ListTile(
              onTap: () {
                final Mode value = ref.read(mode) == Mode.dark ? Mode.light : Mode.dark;
                ref.read(mode.notifier).state = value;
                sharedPreferences.setString('mode', '$value');
              },
              title: Tooltip(
                message: 'اضغط لتغيير نمط الألوان',
                child: Text(ref.watch(mode) == Mode.light ? 'فاتح' : 'داكن'),
              ),
              trailing: Icon(ref.watch(mode) == Mode.light ? Icons.light_mode : Icons.dark_mode),
            );
          },
        ),
        LinkText('Powered by Manassa Ltd.', url: 'https://manassa.ly'),
        const SizedBox(height: 8),
      ],
    ),
  );
}

Iterable<Item> filter(Iterable<Item> items, String searchText) {
  return items.where((item) {
    return searchText.containEachOtherIgnoreCase(item.name);
  }).toList();
}

void login(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const Dialog(child: LoginForm()),
  );
}
