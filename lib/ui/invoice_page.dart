import 'package:manassa_e_commerce/db/db.dart';
import 'package:manassa_e_commerce/models/invoice.dart';
import 'package:manassa_e_commerce/pdf/reporting.dart';
import 'package:manassa_e_commerce/ui/widgets/custom_indicator.dart';
import 'package:manassa_e_commerce/ui/invoice_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

final invoiceProvider = StateProvider<Invoice?>((ref) => null);

class InvoicePage extends StatelessWidget {
  final Invoice? invoice;
  final String? invoiceId;

  const InvoicePage({super.key, this.invoiceId, this.invoice}) : assert(invoice != null || invoiceId != null);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('فاتورة مبيعات - ${invoice?.id ?? invoiceId}'),
          actions: [
            Consumer(
              builder: (context, ref, child) {
                final invoice = ref.watch(invoiceProvider);
                if (invoice == null) return Container();
                return IconButton(
                  onPressed: () async => Printing.sharePdf(bytes: await Reporting.createPdfInvoice(invoice)),
                  icon: const Icon(Icons.download),
                );
              },
            ),
          ],
        ),
        body: FutureBuilder<Invoice?>(
          future: invoice != null ? Future.value(invoice) : Database.getInvoice(invoiceId!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              // Show a loading indicator while waiting for the data
              return const CustomIndicator();
            } else if (snapshot.connectionState == ConnectionState.done) {
              if (snapshot.hasError) {
                return Column(
                  children: [
                    const Text('حدث خطأ يرجى التواصل مع مطور المتجر'),
                    Text('Error: ${snapshot.error}'),
                    SingleChildScrollView(child: Text('Error: ${snapshot.stackTrace}')),
                  ],
                );
              } else if (snapshot.hasData) {
                return Consumer(
                  builder: (context, ref, child) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      ref.read(invoiceProvider.notifier).state = snapshot.requireData!;
                    });
                    return InvoiceViewer(invoice: snapshot.requireData!);
                  },
                );
              } else {
                return const Center(child: Text('لم يتم العثور على الفاتورة'));
              }
            } else {
              return const Center(child: Text(' . . . '));
            }
          },
        ),
      ),
    );
  }
}
