import 'package:flutter/material.dart';
import 'package:manassa_e_menu/services/firestore_service.dart';

import '../models/restaurant_model.dart';

class EditRestaurantScreen extends StatefulWidget {
  final Restaurant? restaurant;

  const EditRestaurantScreen({super.key, this.restaurant});

  @override
  State<EditRestaurantScreen> createState() => _EditRestaurantScreenState();
}

class _EditRestaurantScreenState extends State<EditRestaurantScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _imageController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.restaurant?.name ?? '');
    _addressController =
        TextEditingController(text: widget.restaurant?.address ?? '');
    _imageController =
        TextEditingController(text: widget.restaurant?.image ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  Future<void> _saveRestaurant() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final newRestaurant = Restaurant(
      id: widget.restaurant?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      address: _addressController.text.trim(),
      image: _imageController.text.trim(),
    );

    try {
      await FirestoreService().saveRestaurant(newRestaurant);
      setState(() => _isLoading = false);
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorMessage("فشل في حفظ المطعم. حاول مرة أخرى.");
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.restaurant == null
            ? 'إضافة مطعم'
            : 'تعديل بيانات ${_nameController.text}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    // اسم المطعم
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'اسم المطعم',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'يرجى إدخال اسم المطعم' : null,
                    ),
                    const SizedBox(height: 12),

                    // العنوان
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'العنوان',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'يرجى إدخال العنوان' : null,
                    ),
                    const SizedBox(height: 12),

                    // رابط الصورة
                    TextFormField(
                      controller: _imageController,
                      decoration: const InputDecoration(
                        labelText: 'رابط الصورة',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'يرجى إدخال رباط الصورة' : null,
                      onChanged: (value) => setState(() {}),
                    ),
                    const SizedBox(height: 12),

                    // عرض الصورة المعاينة
                    if (_imageController.text.isNotEmpty)
                      Builder(builder: (context) {
                        double widthOfScreen = MediaQuery.sizeOf(context).width;
                        return SizedBox(
                          height: widthOfScreen * 0.8,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.network(
                              _imageController.text,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.broken_image,
                                      size: 100, color: Colors.grey),
                            ),
                          ),
                        );
                      }),
                    const SizedBox(height: 20),
                  ],
                ),
              ),

              // زر الحفظ
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveRestaurant,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('حفظ',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
