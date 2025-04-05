import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:manassa_e_menu/models/item.dart';
import 'package:manassa_e_menu/services/firestore_service.dart';

class EditItemScreen extends StatefulWidget {
  final String categoryId;
  final Item? item;

  const EditItemScreen({super.key, required this.categoryId, this.item});

  @override
  State<EditItemScreen> createState() => _EditItemScreenState();
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
    _descriptionController =
        TextEditingController(text: widget.item?.description ?? '');
    _priceController =
        TextEditingController(text: widget.item?.price.toString() ?? '');
    _imageController = TextEditingController(text: widget.item?.image ?? '');

    _imageController.addListener(() {
      if (mounted) setState(() {}); // تحديث عند تغيير رابط الصورة
    });
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

      if (!mounted) {
        return; // ✅ التأكد من أن الصفحة لا تزال نشطة قبل استخدام Navigator
      }
      Navigator.pop(context);
    } catch (e) {
      if (mounted) _showErrorMessage("فشل في حفظ الصنف. حاول مرة أخرى.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
        title: Text(widget.item == null
            ? 'إضافة صنف'
            : 'تعديل ${_nameController.text}'),
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
                    _buildTextField(
                        _nameController, 'اسم الصنف', 'يرجى إدخال اسم الصنف'),
                    const SizedBox(height: 12),
                    _buildTextField(_descriptionController, 'الوصف', null),
                    const SizedBox(height: 12),
                    _buildTextField(
                        _priceController, 'السعر', 'يرجى إدخال السعر',
                        isNumeric: true),
                    const SizedBox(height: 12),
                    _buildTextField(_imageController, 'رابط الصورة',
                        'يرجى إدخال رابط الصورة'),
                    const SizedBox(height: 12),
                    if (_imageController.text.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: CachedNetworkImage(
                          height: MediaQuery.of(context).size.width / 2,
                          fit: BoxFit.cover,
                          imageUrl: _imageController.text,
                          errorWidget: (context, url, error) => const Icon(
                              Icons.broken_image,
                              size: 100,
                              color: Colors.grey),
                        ),
                      ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveItem,
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

  Widget _buildTextField(
      TextEditingController controller, String label, String? errorMessage,
      {bool isNumeric = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (errorMessage != null && (value == null || value.trim().isEmpty)) {
          return errorMessage;
        }
        if (isNumeric && value != null && double.tryParse(value) == null) {
          return 'يرجى إدخال قيمة صحيحة';
        }
        return null;
      },
    );
  }
}
