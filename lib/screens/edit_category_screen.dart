import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:manassa_e_menu/models/menu_category_model.dart';

import '../services/firestore_service.dart';

class EditCategoryScreen extends StatefulWidget {
  final String restaurantId;
  final MenuCategory? category;

  const EditCategoryScreen({super.key, required this.restaurantId, this.category});

  @override
  State<EditCategoryScreen> createState() => _EditCategoryScreenState();
}

class _EditCategoryScreenState extends State<EditCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _imageController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _imageController = TextEditingController(text: widget.category?.image ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final newCategory = MenuCategory(
      id: widget.category?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      restaurantId: widget.restaurantId,
      name: _nameController.text.trim(),
      image: _imageController.text.trim(),
    );

    try {
      await FirestoreService().saveMenuCategory(newCategory);
      setState(() => _isLoading = false);
      if(mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorMessage("حدث خطأ أثناء الحفظ. حاول مرة أخرى.");
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
        title: Text(widget.category == null ? 'إضافة قائمة' : 'تعديل ${_nameController.text}'),
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
                    // حقل اسم القائمة
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'اسم القائمة',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value!.isEmpty ? 'يرجى إدخال اسم القائمة' : null,
                    ),
                    const SizedBox(height: 12),

                    // حقل رابط الصورة
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

                    // عرض صورة المعاينة
                    if (_imageController.text.isNotEmpty)
                      Builder(builder: (context) {
                        double widthOfScreen = MediaQuery.sizeOf(context).width;
                        return SizedBox(
                          height: widthOfScreen * 0.8,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: CachedNetworkImage(
                              imageUrl: _imageController.text,
                              fit: BoxFit.contain,
                              placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                              errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 100, color: Colors.grey),
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
                      onPressed: _isLoading ? null : _saveCategory,
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
