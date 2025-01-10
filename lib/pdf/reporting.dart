import 'package:manassa_e_commerce/models/invoice.dart';
import 'package:manassa_e_commerce/models/item.dart';
import 'package:manassa_e_commerce/ui/app.dart';
import 'package:manassa_e_commerce/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart';
import 'package:pdf/pdf.dart';

abstract class Reporting {
  static Future<Uint8List> createPdfInvoice(Invoice invoice) async {
    final font = await fontFromAssetBundle(
      'assets/fonts/HacenTunisia/Regular.ttf',
    );
    final footerWidget = await footer(invoice);
    final fontBold = await fontFromAssetBundle(
      'assets/fonts/HacenTunisia/Bold-Regular.ttf',
    );
    final logo = await imageFromAssetBundle('assets/images/logo.webp');
    final pdf = Document();

    pdf.addPage(
      Page(
        pageTheme: PageTheme(
          pageFormat: PdfPageFormat.a4,
          theme: ThemeData(
            defaultTextStyle: TextStyle(font: font, fontBold: fontBold),
          ),
          textDirection: TextDirection.rtl,
        ),
        build: (context) {
          return LayoutBuilder(
            builder: (context, constraints) {
              return Center(
                child: Container(
                  width: constraints?.maxWidth ?? 480,
                  child: Column(
                    children: [
                      header(invoice, logo),
                      SizedBox(height: 32),
                      table(invoice),
                      SizedBox(height: 32),
                      footerWidget,
                      Spacer(),
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: Text('المستلم: . . . . . . . . . . . . . . . .'),
                      ),
                      SizedBox(height: 32),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Text(
                          'Created by Manassa Ltd. - manassa.ly',
                          style: const TextStyle(color: PdfColors.grey, fontSize: 10),
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );

    return pdf.save();
  }

  static Widget header(Invoice invoice, ImageProvider logo) {
    TextStyle redValueStyle = TextStyle(color: PdfColor.fromHex('#cc3300'));
    TextStyle orangeValueStyle = TextStyle(color: PdfColor.fromHex('#fcb103'));
    TextStyle greenValueStyle = TextStyle(color: PdfColor.fromHex('#009900'));

    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('اســم المستلم'),
            Text('رقــم الهـاتـف'),
            Text('عنوان المستلم'),
            Text('التـــــــــاريــــخ'),
            Text('حالة الطلب'),
            Text('حالة الدفع'),
          ],
        ),
        Column(
          children: [
            Text('  :'),
            Text('  :'),
            Text('  :'),
            Text('  :'),
            Text('  :'),
            Text('  :'),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(invoice.recipientName),
            Text(invoice.recipientPhone),
            Text(invoice.recipientAddress),
            Text(format(invoice.createAt!)),
            Text(
              invoice.orderStatus.toString().split('.').last,
              style: invoice.orderStatus == OrderStatus.pending || invoice.orderStatus == OrderStatus.canceled
                  ? redValueStyle
                  : invoice.orderStatus == OrderStatus.inProgress
                      ? orangeValueStyle
                      : greenValueStyle,
            ),
            Text(
              invoice.paymentStatus.toString().split('.').last,
              style: invoice.paymentStatus == PaymentStatus.unpaid
                  ? redValueStyle
                  : invoice.paymentStatus == PaymentStatus.partiallyPaid
                      ? orangeValueStyle
                      : greenValueStyle,
            ),
          ],
        ),
        Spacer(),
        SizedBox.square(dimension: 64, child: Image(logo)),
      ],
    );
  }

  static String format(Timestamp timestamp) {
    final year = '${timestamp.toDate().year}';
    final month = '${timestamp.toDate().month}';
    final day = '${timestamp.toDate().day}';
    final hour = timestamp.toDate().hour;
    final minute = timestamp.toDate().minute;
    return '$year-${month.padLeft(2, '0')}-${day.padLeft(2, '0')} '
        '${hour % 12}:$minute ${hour < 12 ? 'ص' : 'م'}';
  }

  static Widget table(Invoice invoice) {
    final invoiceItems = invoice.invoiceItems;

    return Table(
      columnWidths: {
        0: const FixedColumnWidth(50),
        1: const FixedColumnWidth(60),
        2: const FixedColumnWidth(40),
        3: const FixedColumnWidth(40),
        4: const FractionColumnWidth(0.5),
      },
      children: [
        TableRow(
          children: [
            Text('المجموع', textAlign: TextAlign.center),
            Text('سعر الوحدة', textAlign: TextAlign.center),
            Text('الكمية', textAlign: TextAlign.center),
            Text('الحجم', textAlign: TextAlign.center),
            Text('اسم الصنف', textAlign: TextAlign.center),
          ],
        ),
        TableRow(children: [for (int i = 0; i < 5; i++) Divider(height: 1, thickness: 1)]),
        for (int i = 0; i < invoiceItems.length; i++) ...[
          TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text('${invoiceItems.elementAt(i).totalPrice}', textAlign: TextAlign.center),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: priceWidget(invoiceItems.elementAt(i).item),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: Text('${invoiceItems.elementAt(i).quantity}', textAlign: TextAlign.center),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: Column(
                  children: [Text(invoiceItems.elementAt(i).size ?? 'قياسي', textAlign: TextAlign.center)],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: Text(invoiceItems.elementAt(i).item.name),
              ),
            ],
          ),
          TableRow(children: [for (int i = 0; i < 5; i++) Divider(height: 0.25, thickness: 0.25)]),
        ],
      ],
    );
  }

  static Widget priceWidget(Item item) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (item.discount != null)
          Text(
            '${item.price}',
            style: const TextStyle(decoration: TextDecoration.lineThrough, color: PdfColors.grey),
          ),
        Text('${item.discountedPrice}'),
      ],
    );
  }

  static Future<Widget> footer(Invoice invoice) async {
    final font = Font.ttf(await rootBundle.load("assets/fonts/Arial-Unicode-Font.ttf"));
    const googleMapUrl = 'https://www.google.com/maps?q=';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Column(
              children: [
                BarcodeWidget(
                  data: '$googleMapUrl${invoice.latitude},${invoice.longitude}',
                  barcode: Barcode.qrCode(),
                  width: 64,
                  height: 64,
                ),
                Text('الموقع'),
              ],
            ),
            SizedBox(width: 64),
            Column(
              children: [
                BarcodeWidget(
                  data: '$baseUrl/#/invoices/${invoice.id}',
                  barcode: Barcode.qrCode(),
                  width: 64,
                  height: 64,
                ),
                Text('الفاتورة'),
              ],
            ),
            Spacer(),
            Column(children: [
              Text(
                'الإجمالي: ${invoice.total} $currency',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'لقد ادخرت: ${invoice.savings} $currency',
                style: TextStyle(fontWeight: FontWeight.bold),
              )
            ]),
          ],
        ),
        SizedBox(height: 32),
        if (invoice.note!.isNotEmpty)
          Row(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                ' ✶ ',
                style: TextStyle(
                  color: PdfColor.fromHex('#fcb103'),
                  font: font,
                  fontSize: 18,
                ),
              ),
              Text('ملاحظة : ', style: const TextStyle(fontSize: 18)),
              Text('${invoice.note}'),
            ],
          ),
      ],
    );
  }
}
