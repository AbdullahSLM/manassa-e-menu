import 'package:manassa_e_commerce/db/db.dart';
import 'package:manassa_e_commerce/models/user.dart';
import 'package:manassa_e_commerce/pdf/reporting.dart';
import 'package:manassa_e_commerce/ui/app.dart';
import 'package:manassa_e_commerce/ui/widgets/internal_note_gialog.dart';
import 'package:manassa_e_commerce/utils.dart';
import 'package:flutter/material.dart';
import 'package:manassa_e_commerce/models/invoice.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class InvoiceViewer extends StatelessWidget {
  final Invoice invoice;

  const InvoiceViewer({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final size = constraints.biggest;
        final EdgeInsets padding;

        if (ScreenType.type(context) == ScreenType.small) {
          padding = const EdgeInsets.all(16);
        } else {
          padding = EdgeInsets.symmetric(horizontal: size.width / 8, vertical: 24);
        }

        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Padding(
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildRecipientInfo(),
                const Divider(height: 16),
                _buildInvoiceItems(context),
                const Divider(height: 16),
                _buildTotalAmount(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecipientInfo() {
    const redValueStyle = TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent);
    const orangeValueStyle = TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orangeAccent);
    const greenValueStyle = TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green);
    const style = TextStyle(fontSize: 18);
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('اسم الزبون', style: style),
                  Text('رقم الهاتف', style: style),
                  Text('العنوان', style: style),
                  Text('التاريخ', style: style),
                  Text('حالة الطلب', style: style),
                  Text('حالة الدفع', style: style),
                ],
              ),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('  |  ', style: style),
                  Text('  |  ', style: style),
                  Text('  |  ', style: style),
                  Text('  |  ', style: style),
                  Text('  |  ', style: style),
                  Text('  |  ', style: style),
                ],
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(invoice.recipientName, style: style, overflow: TextOverflow.ellipsis),
                    Text(invoice.recipientPhone, style: style, overflow: TextOverflow.ellipsis),
                    Text(invoice.recipientAddress, style: style, overflow: TextOverflow.ellipsis),
                    Text(invoice.createAt != null ? Reporting.format(invoice.createAt!) : 'يتم تحديد التاريخ عند الضغط على زر إرسال',
                        style: style, overflow: TextOverflow.ellipsis),
                    Text(
                      invoice.orderStatus.name,
                      style: invoice.orderStatus == OrderStatus.pending || invoice.orderStatus == OrderStatus.canceled
                          ? redValueStyle
                          : invoice.orderStatus == OrderStatus.inProgress
                              ? orangeValueStyle
                              : greenValueStyle,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      invoice.paymentStatus.name,
                      style: invoice.paymentStatus == PaymentStatus.unpaid
                          ? redValueStyle
                          : invoice.paymentStatus == PaymentStatus.partiallyPaid
                              ? orangeValueStyle
                              : greenValueStyle,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 75,
          height: 75,
          child: Consumer(
            builder: (context, ref, child) {
              try {
                return ref.watch(mode) != Mode.dark ? Image.asset('assets/images/logo.webp') : Image.asset('assets/images/white_logo.webp');
              } catch (e) {
                return Wrap(
                  children: [
                    Text('${const Icon(Icons.error_outline)} | Error: $e'),
                  ],
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInvoiceItems(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return _itemsList();
        } else {
          return _itemsTable();
        }
      },
    );
  }

  Widget _itemsTable() {
    const boldFontStyle = TextStyle(fontWeight: FontWeight.bold);

    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: [
                DataColumn(
                  label: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: 0.50 * constraints.maxWidth),
                    child: const Center(child: Text('الصنف', style: boldFontStyle, overflow: TextOverflow.ellipsis)),
                  ),
                ),
                const DataColumn(label: Center(child: Text('الحجم', style: boldFontStyle, overflow: TextOverflow.ellipsis))),
                const DataColumn(label: Center(child: Text('الكمية', style: boldFontStyle, overflow: TextOverflow.ellipsis)), numeric: true),
                const DataColumn(label: Center(child: Text('السعر', style: boldFontStyle, overflow: TextOverflow.ellipsis)), numeric: true),
                const DataColumn(label: Center(child: Text('المجموع', style: boldFontStyle, overflow: TextOverflow.ellipsis)), numeric: true),
              ],
              rows: [
                for (final item in invoice.invoiceItems)
                  DataRow(
                    cells: [
                      DataCell(
                        SizedBox(
                          width: 0.50 * constraints.maxWidth,
                          child: Text(item.item.name, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                      DataCell(
                        ConstrainedBox(
                          constraints: const BoxConstraints(minWidth: 64),
                          child: Text(item.size != null ? item.size! : 'قياسي', overflow: TextOverflow.ellipsis),
                        ),
                      ),
                      DataCell(
                        ConstrainedBox(
                          constraints: const BoxConstraints(minWidth: 64),
                          child: Text(item.quantity.toString(), overflow: TextOverflow.ellipsis),
                        ),
                      ),
                      DataCell(
                        ConstrainedBox(
                          constraints: const BoxConstraints(minWidth: 64),
                          child: PriceWidget(
                            price: item.item.price,
                            discount: item.item.discount,
                            direction: Axis.vertical,
                          ),
                        ),
                      ),
                      DataCell(
                        ConstrainedBox(
                          constraints: const BoxConstraints(minWidth: 64),
                          child: Text('${item.totalPrice} $currency', overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _itemsList() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'أصناف الفاتورة:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            for (final indexedItem in invoice.invoiceItems.indexed)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      indexedItem.$2.item.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Flexible(
                          child: Text(
                            'الحجم:',
                            style: TextStyle(fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          indexedItem.$2.size ?? 'قياسي',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Flexible(
                          child: Text(
                            'الكمية:',
                            style: TextStyle(fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${indexedItem.$2.quantity}x',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (indexedItem.$2.item.discountedPrice < indexedItem.$2.item.price) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Flexible(
                            child: Text(
                              'السعر قبل التخفيض:',
                              style: TextStyle(fontSize: 16),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${indexedItem.$2.item.price.toStringAsFixed(2)} $currency',
                            style: const TextStyle(
                              fontSize: 16,
                              decoration: TextDecoration.lineThrough,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Flexible(
                            child: Text(
                              'السعر بعد التخفيض:',
                              style: TextStyle(fontSize: 16),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${indexedItem.$2.item.discountedPrice.toStringAsFixed(2)} $currency',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Flexible(
                          child: Text(
                            'إجمالي السعر:',
                            style: TextStyle(fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${indexedItem.$2.totalPrice.toStringAsFixed(2)} $currency',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    if (indexedItem.$1 != invoice.invoiceItems.length - 1) const Divider(),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalAmount() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Flexible(
              child: Text(
                'الإجمالي:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${readableMoney(invoice.total)} $currency',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (invoice.savings > 0) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Text(
                  'لقد قمت بتوفير:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${readableMoney(invoice.savings)} $currency',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.green),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 24),
        if (invoice.note?.isNotEmpty == true)
          Row(
            children: [
              const Text('✶  ', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 18)),
              const Text(
                'ملاحظة : ',
                style: TextStyle(fontSize: 18),
              ),
              Expanded(child: Text('${invoice.note}')),
            ],
          ),
        if (invoice.internalNote?.isNotEmpty == true && invoice.note?.isNotEmpty == true) const Divider(thickness: 2),
        if (invoice.internalNote?.isNotEmpty == true)
          Consumer(
            builder: (context, ref, child) {
              final user = ref.watch(currentUser);
              if (user != null && user.role.index <= Role.employee.index) {
                return Row(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const Text('✶  ', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 18)),
                    const Text(
                      'ملاحظة داخلية : ',
                      style: TextStyle(fontSize: 18),
                    ),
                    Expanded(child: Text('${invoice.internalNote}')),
                    const SizedBox(width: 16),
                    Builder(builder: (context) {
                      return ElevatedButton(
                        onPressed: () {
                          // تأكد من أن التنقل يحدث بعد اكتمال بناء الواجهة
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _editInternalNote(context, invoice.internalNote);
                          });
                        },
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit),
                            Text('  تعديل'),
                          ],
                        ),
                      );
                    }),
                  ],
                );
              }
              return Container();
            },
          ),
        const SizedBox(height: 8),
        if (invoice.internalNote?.isNotEmpty == false || invoice.internalNote == null)
          Consumer(
            builder: (context, ref, child) {
              final user = ref.read(currentUser);
              if (user != null && user.role.index <= Role.employee.index) {
                return ElevatedButton(
                  onPressed: () {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _addInternalNote(context);
                    });
                  },
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add),
                      Text('  إضافة ملاحظة داخلية'),
                    ],
                  ),
                );
              }
              return Container();
            },
          ),
        const SizedBox(height: 8),
      ],
    );
  }

  void _editInternalNote(BuildContext context, String? currentNote) {
    showInternalNoteDialog(
      context,
      title: 'تعديل الملاحظة الداخلية',
      initialNote: currentNote,
      onSave: (newNote) {
        Database.updateInvoice(invoice.id!, invoice.copyWith(internalNote: newNote));
        (context as Element).markNeedsBuild();
      },
    );
  }

  void _addInternalNote(BuildContext context) {
    showInternalNoteDialog(
      context,
      title: 'إضافة ملاحظة داخلية',
      initialNote: '',
      onSave: (newNote) {
        Database.updateInvoice(invoice.id!, invoice.copyWith(internalNote: newNote));
        (context as Element).markNeedsBuild();
      },
    );
  }
}

class PriceWidget extends StatelessWidget {
  final double price;
  final double? discount;
  final Axis direction;

  final TextStyle? style;

  const PriceWidget({
    super.key,
    required this.price,
    this.discount,
    this.style,
    this.direction = Axis.horizontal,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      direction: isVertical ? Axis.vertical : Axis.horizontal,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.center,
      children: [
        if (isDiscounted)
          Text(
            '${readableMoney(price)}${isVertical ? ' $currency' : ''}',
            style: _style.copyWith(
              decoration: style?.decoration ?? TextDecoration.lineThrough,
              color: style?.color ?? Colors.red,
            ),
          ),
        if (isDiscounted && isHorizontal) const SizedBox(width: 8),
        Text(
          '${readableMoney(price - (discount ?? 0))} $currency',
          style: _style.copyWith(
            fontWeight: style?.fontWeight ?? FontWeight.bold,
            color: isDiscounted ? style?.color ?? Colors.green : null,
          ),
        ),
      ],
    );
  }

  bool get isDiscounted => discount != null && discount! > 0;

  bool get isVertical => direction == Axis.vertical;

  bool get isHorizontal => direction == Axis.horizontal;

  TextStyle get _style => style ?? const TextStyle();
}
