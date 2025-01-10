import 'package:manassa_e_commerce/db/db.dart';
import 'package:manassa_e_commerce/models/item.dart';
import 'package:manassa_e_commerce/ui/widgets/custom_indicator.dart';
import 'package:manassa_e_commerce/ui/home_page.dart';
import 'package:manassa_e_commerce/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final allItemsProvider = FutureProvider((ref) => Database.getItems());

final homePageItemsProvider = FutureProvider((ref) => Database.getHomePageItems());

// Define the selected items provider
final selectedItemsProvider = StateNotifierProvider<SelectedItemsNotifier, Iterable<Item>>((ref) {
  final homePageItems = ref.watch(homePageItemsProvider).asData?.value;
  return SelectedItemsNotifier(homePageItems ?? []);
});

class SelectedItemsNotifier extends StateNotifier<Iterable<Item>> {
  SelectedItemsNotifier(super.items);

  void addItem(Item item) {
    state = [...state, item];
  }

  void removeItem(Item item) {
    state = state.where((i) => i.id != item.id).toList();
  }

  void reorderItems(int oldIndex, int newIndex) {
    final List<Item> updatedList = List.from(state);
    if (newIndex > oldIndex) newIndex -= 1;
    final item = updatedList.removeAt(oldIndex);
    updatedList.insert(newIndex, item);
    state = updatedList;
  }

  void setItems(List<Item> items) {
    state = items;
  }
}

class AppearancePage extends StatelessWidget {
  const AppearancePage({super.key});

  @override
  Widget build(BuildContext context) {
    const widget = AppearanceView();
    return Directionality(
      textDirection: TextDirection.rtl,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return DefaultTabController(
            length: 2,
            child: Scaffold(
              appBar: AppBar(
                title: const Text('صفحة إدارة المظهر'),
                bottom:
                    constraints.isSmall ? const TabBar(tabs: [Tab(text: 'الأصناف التي سيتم عرضها'), Tab(text: 'الأصناف التي لن يتم عرضها')]) : null,
              ),
              drawer: drawer(context),
              body: LayoutBuilder(builder: (context, constraints) {
                if (constraints.isSmall) {
                  return SizedBox(
                      height: constraints.maxHeight,
                      child: const TabBarView(children: [
                        Flex(direction: Axis.vertical, children: [SelectedItems()]),
                        Flex(direction: Axis.vertical, children: [UnselectedItems()])
                      ]));
                } else {
                  return widget;
                }
              }),
              floatingActionButton: Consumer(
                builder: (BuildContext context, WidgetRef ref, Widget? child) {
                  return FloatingActionButton(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    onPressed: () async {
                      final selectedItems = ref.watch(selectedItemsProvider);
                      try {
                        final data = {'items': selectedItems.map((item) => item.id).toList()};
                        await Database.updateHomePageData(data);
                        if (context.mounted) {
                          showDialog(context: context, builder: (context) => const SuccessDialog());
                        }
                      } catch (e) {
                        if (context.mounted) {
                          showDialog(context: context, builder: (context) => const SuccessDialog());
                        }
                      }
                    },
                    child: const Icon(Icons.save_outlined),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class AppearanceView extends ConsumerWidget {
  const AppearanceView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(allItemsProvider).isLoading || ref.watch(homePageItemsProvider).isLoading;

    return Stack(
      children: [
        if (!isLoading)
          const Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    SelectedItems(),
                    VerticalDivider(width: 0),
                    UnselectedItems(),
                  ],
                ),
              ),
              Divider(height: 0),
            ],
          )
        else
          const CustomIndicator(),
      ],
    );
  }
}

class SelectedItems extends StatelessWidget {
  const SelectedItems({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Consumer(
        builder: (context, ref, child) {
          final selectedItemsAsync = ref.watch(selectedItemsProvider);
          final isLoading = ref.watch(allItemsProvider).isLoading || ref.watch(homePageItemsProvider).isLoading;
          final selectedItems = selectedItemsAsync;

          if (!isLoading) {
            return selectedItems.isEmpty
                ? const Center(child: Text('لا توجد أصناف لعرضها هنا.'))
                : ReorderableListView(
                    onReorder: (int oldIndex, int newIndex) {
                      ref.read(selectedItemsProvider.notifier).reorderItems(oldIndex, newIndex);
                    },
                    children: [
                      for (final item in selectedItems)
                        ListTile(
                          key: ValueKey(item.id),
                          title: Text(item.name),
                          trailing: SizedBox(
                            width: 75,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 32.0),
                              child: TextButton(
                                style: ButtonStyle(
                                  foregroundColor: WidgetStateProperty.all<Color?>(Colors.redAccent),
                                  shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                                    RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                      side: const BorderSide(color: Colors.redAccent, strokeAlign: 1),
                                    ),
                                  ),
                                ),
                                onPressed: () => ref.read(selectedItemsProvider.notifier).removeItem(item),
                                child: const Text('حذف'),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
          } else {
            return const CustomIndicator();
          }
        },
      ),
    );
  }

  Widget body() {
    return Consumer(
      builder: (context, ref, child) {
        final selectedItemsAsync = ref.watch(selectedItemsProvider);
        final isLoading = ref.watch(allItemsProvider).isLoading || ref.watch(homePageItemsProvider).isLoading;
        final selectedItems = selectedItemsAsync;

        if (!isLoading) {
          return selectedItems.isEmpty
              ? const Center(child: Text('لا توجد أصناف لعرضها هنا.'))
              : ReorderableListView(
                  onReorder: (int oldIndex, int newIndex) {
                    ref.read(selectedItemsProvider.notifier).reorderItems(oldIndex, newIndex);
                  },
                  children: [
                    for (final item in selectedItems)
                      ListTile(
                        key: ValueKey(item.id),
                        title: Text(item.name),
                        trailing: SizedBox(
                          width: 75,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 32.0),
                            child: TextButton(
                              style: ButtonStyle(
                                foregroundColor: WidgetStateProperty.all<Color?>(Colors.redAccent),
                                shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                    side: const BorderSide(color: Colors.redAccent, strokeAlign: 1),
                                  ),
                                ),
                              ),
                              onPressed: () => ref.read(selectedItemsProvider.notifier).removeItem(item),
                              child: const Text('حذف'),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
        } else {
          return const CustomIndicator();
        }
      },
    );
  }
}

class UnselectedItems extends StatelessWidget {
  const UnselectedItems({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Consumer(builder: (context, ref, child) {
        return ref.watch(allItemsProvider).when(
              data: (allItems) {
                final selectedItems = ref.watch(selectedItemsProvider);

                // Filter out selected items from available items
                final unselectedItems = allItems.where((item) => !selectedItems.contains(item)).toList();

                return unselectedItems.isEmpty
                    ? const Center(
                        child: Text('لا توجد أصناف لإضافتها.'),
                      )
                    : ListView(
                        children: unselectedItems.map((item) {
                          return ListTile(
                            title: Text(item.name),
                            trailing: TextButton(
                              style: ButtonStyle(
                                foregroundColor: WidgetStateProperty.all<Color?>(Colors.green),
                                shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                    side: const BorderSide(
                                      color: Colors.green,
                                      strokeAlign: 1,
                                    ),
                                  ),
                                ),
                              ),
                              onPressed: () => ref.read(selectedItemsProvider.notifier).addItem(item),
                              child: const Text('إضافة'),
                            ),
                          );
                        }).toList(),
                      );
              },
              error: (err, stack) => ErrorWidget(err),
              loading: () => Container(),
            );
      }),
    );
  }
}

class SuccessDialog extends StatelessWidget {
  const SuccessDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 50),
              child: Text('تمت العملية بنجاح'),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Center(
                        child: Text(
                          'متابعة التعديل',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/items', (route) => false),
                      child: const Center(child: Text('عودة لصفحة الإدارة', textAlign: TextAlign.center)),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/',
                        (route) => false,
                      ),
                      child: const Center(
                        child: Text(
                          'عودة للصفحة الرئيسية',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
