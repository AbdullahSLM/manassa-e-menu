import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/item_model.dart';
import '../services/firestore_service.dart';

class EditItemScreen extends StatefulWidget {
  final String categoryId;
  final Item? item;

  const EditItemScreen({super.key, required this.categoryId, this.item});

  @override
  _EditItemScreenState createState() => _EditItemScreenState();
}

class _EditItemScreenState extends State<EditItemScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _imageController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item?.name ?? '');
    _descriptionController = TextEditingController(text: widget.item?.description ?? '');
    _priceController = TextEditingController(text: widget.item?.price?.toString() ?? '');
    _imageController = TextEditingController(text: widget.item?.image ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final newItem = Item(
        id: widget.item?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        categoryId: widget.categoryId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        image: _imageController.text.trim(),
      );

      await FirestoreService().saveMenuItem(newItem);
      Navigator.pop(context);
    } catch (e) {
      _showErrorMessage("فشل في حفظ الصنف. حاول مرة أخرى.");
    } finally {
      setState(() => _isLoading = false);
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
        title: Text(widget.item == null ? 'إضافة صنف' : 'تعديل ${_nameController.text}'),
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
                    // اسم الصنف
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'اسم الصنف',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value!.isEmpty ? 'يرجى إدخال اسم الصنف' : null,
                    ),
                    const SizedBox(height: 12),

                    // وصف الصنف
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'الوصف',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // السعر
                    TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'السعر',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value!.isEmpty) return 'يرجى إدخال السعر';
                        if (double.tryParse(value) == null) return 'يرجى إدخال قيمة صحيحة';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // رابط الصورة
                    TextFormField(
                      controller: _imageController,
                      decoration: const InputDecoration(
                        labelText: 'رابط الصورة',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value!.isEmpty ? 'يرجى إدخال رابط الصورة' : null,
                      onChanged: (value) => setState(() {}),
                    ),
                    const SizedBox(height: 12),

                    // عرض الصورة إذا كان هناك رابط صالح
                    if (_imageController.text.isNotEmpty)
                      Builder(
                        builder: (context) {
                          double widthOfScreen = MediaQuery.sizeOf(context).width;
                          return SizedBox(
                            height: widthOfScreen / 2,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: CachedNetworkImage(
                                fit: BoxFit.cover,
                                imageUrl: _imageController.text,
                                errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 100, color: Colors.grey),
                              ),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),

              // زر الحفظ
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveItem,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('حفظ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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
