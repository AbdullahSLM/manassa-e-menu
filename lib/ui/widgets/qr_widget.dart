import 'package:flutter/material.dart';
import 'package:manassa_e_menu/models/restaurant.dart';
import 'package:manassa_e_menu/utils.dart';
import 'package:qr_flutter/qr_flutter.dart';

Widget qrScreen({required Restaurant restaurant}) {
  String qrData = "${Utils.baseURL}/menu/${restaurant.id}";

  return Scaffold(
    body: Center(
      child: QrImageView(
        data: qrData,
        size: 100.0,
        backgroundColor: Colors.white,
      ),
    ),
  );
}
