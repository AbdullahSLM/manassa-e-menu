import 'dart:async';

import 'package:manassa_e_commerce/db/db.dart';
import 'package:manassa_e_commerce/models/invoice.dart';
import 'package:manassa_e_commerce/pdf/reporting.dart';
import 'package:manassa_e_commerce/ui/app.dart';
import 'package:manassa_e_commerce/ui/widgets/custom_indicator.dart';
import 'package:manassa_e_commerce/ui/home_page.dart';
import 'package:manassa_e_commerce/ui/invoice_page.dart';
import 'package:manassa_e_commerce/ui/invoice_viewer.dart';
import 'package:manassa_e_commerce/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:resizable_widget/resizable_widget.dart';

final getInvoicesProvider = FutureProvider((_) => Database.searchDocuments<Invoice>(
  collectionRef: Database.invoicesRef,  // تمرير CollectionReference
  fromJson: (data) => Invoice.fromJson(data),  // استخدام fromJson لتحويل البيانات
  limit: 10,  // تحديد الحد
));


final selectedInvoice = StateProvider<Invoice?>((_) => null);

final pagingController = PagingController<String?, Invoice>(firstPageKey: null);

final searchText = StateProvider((ref) => '');

class InvoicesPage extends StatelessWidget {
  const InvoicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    const widget = InvoicesView();
    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          appBar: AppBar(title: const Text('الفواتير')),
          drawer: drawer(context),
          body: widget,
        );
      },
    );
  }
}

class InvoicesView extends ConsumerStatefulWidget {
  const InvoicesView({super.key});

  @override
  ConsumerState<InvoicesView> createState() => _InvoicesPageState();

  static void refresh(WidgetRef ref) {
    ref.read(selectedInvoice.notifier).state = null;
    pagingController.refresh();
  }
}

class _InvoicesPageState extends ConsumerState<InvoicesView> {
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    pagingController.addPageRequestListener(_fetchData);
  }

  void _fetchData(String? pageKey) async {
    try {
      final invoices = await Database.searchDocuments<Invoice>(
        collectionRef: Database.invoicesRef,  // تمرير CollectionReference
        fromJson: (data) => Invoice.fromJson(data),  // استخدام fromJson لتحويل البيانات
        searchText: ref.read(searchText),  // تمرير نص البحث
        limit: 10,  // تحديد الحد
        lastDocumentId: pageKey,  // تحديد ID آخر فاتورة (للـ pagination)
      );

      if (invoices.isEmpty) {
        pagingController.appendLastPage(invoices.toList());
      } else {
        pagingController.appendPage(invoices.toList(), invoices.lastOrNull?.id);
      }
    } catch (error) {
      pagingController.error = error;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(searchText, (previous, next) => InvoicesView.refresh(ref));

    return LayoutBuilder(
      builder: (context, constraints) {
        return Consumer(
          builder: (context, ref, child) {
            return ref.watch(getInvoicesProvider).when(
                  data: (invoices) {
                    if (constraints.isSmall) {
                      return invoicesList();
                    } else {
                      return ResizableWidget(
                        percentages: const [0.25, 0.75],
                        separatorColor: Theme.of(context).dividerColor,
                        children: [
                          invoicesList(),
                          Consumer(
                            builder: (context, ref, child) {
                              return ref.watch(selectedInvoice) != null
                                  ? InvoiceViewer(invoice: ref.read(selectedInvoice)!)
                                  : const Center(child: Text('اختر فاتورة لعرض تفاصيلها'));
                            },
                          ),
                        ],
                      );
                    }
                  },
                  error: (err, stack) => Scaffold(body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center,children: [SelectableText('Error : $err \n Stack : $stack')]))),
                  loading: () => const CustomIndicator(),
                );
          },
        );
      },
    );
  }

  Widget invoicesList() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: SearchBar(
                  elevation: const WidgetStatePropertyAll(4),
                  leading: const Icon(Icons.search),
                  hintText: 'بحث',
                  onChanged: (txt) {
                    if (_debounce?.isActive ?? false) _debounce?.cancel();
                    _debounce = Timer(const Duration(milliseconds: 300), () {
                      ref.read(searchText.notifier).state = txt;
                    });
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: IconButton(
                onPressed: () => pagingController.refresh(),
                icon: const Icon(Icons.refresh),
              ),
            ),
          ],
        ),
        const Divider(),
        Flexible(
          child: PagedListView(
            pagingController: pagingController,
            builderDelegate: PagedChildBuilderDelegate<Invoice>(
              animateTransitions: true,
              itemBuilder: (context, invoice, index) => invoiceListTile(invoice),
              firstPageErrorIndicatorBuilder: (context) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('ابحث لعرض النتائج'),
                  ),
                );
              },
              newPageErrorIndicatorBuilder: (context) => Container(),
              noItemsFoundIndicatorBuilder: (context) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('لا يوجد نماذج لعرضها', style: TextStyle(color: Color(0xe8ff9393))),
                  ),
                );
              },
              noMoreItemsIndicatorBuilder: (context) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('لا يوجد المزيد من الفواتير لعرضها', style: TextStyle(color: Color(0xe8ff9393))),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
  Widget invoiceListTile(Invoice invoice) {
    return Consumer(builder: (context, ref, child) {
      return ListTile(
        contentPadding: const EdgeInsets.only(right: 8.0),
        title: Text(
          '${invoice.recipientName} (${invoice.total} $currency)',
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(Reporting.format(invoice.createAt!)),
        onTap: () {
          if (ScreenType.type(context) == ScreenType.small) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => InvoicePage(invoice: invoice)));
            ref.read(selectedInvoice.notifier).state = invoice;
          } else {
            ref.read(selectedInvoice.notifier).state = invoice;
          }
        },
        onLongPress: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => InvoicePage(invoice: invoice)));
          ref.read(selectedInvoice.notifier).state = invoice;
        },
        selected: ref.watch(selectedInvoice) == invoice,
        trailing: Container(
          width: ref.watch(selectedInvoice) == invoice ? 8 : 0,
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    });
  }
}
