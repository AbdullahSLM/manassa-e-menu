import 'package:flutter/material.dart';
import 'package:manassa_e_menu/services/firestore_service.dart';
import 'package:manassa_e_menu/models/restaurant.dart';

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
  late TextEditingController _phoneNumberController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.restaurant?.name ?? '');
    _addressController = TextEditingController(text: widget.restaurant?.address ?? '');
    _imageController = TextEditingController(text: widget.restaurant?.image ?? '');
    _phoneNumberController = TextEditingController(text: widget.restaurant?.phoneNumber ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _imageController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  Future<void> _saveRestaurant() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final newRestaurant = Restaurant(
      id: widget.restaurant?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      address: _addressController.text.trim(),
      image: _imageController.text.trim(),
      phoneNumber: _phoneNumberController.text.trim(),
    );

    try {
      await FirestoreService().saveRestaurant(newRestaurant);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showErrorMessage("فشل في حفظ المطعم. حاول مرة أخرى.");
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
        title: Text(widget.restaurant == null ? 'إضافة مطعم' : 'تعديل ${_nameController.text}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (_imageController.text.trim().isNotEmpty)
                Center(
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.red, width: 4),
                    ),
                    child: CircleAvatar(
                      radius: 100,
                      backgroundImage: NetworkImage(_imageController.text.trim()),
                      backgroundColor: Colors.grey[300],
                      onBackgroundImageError: (_, __) => const Icon(Icons.broken_image, size: 60),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  children: [
                    _buildTextField(_nameController, 'اسم المطعم'),
                    _buildTextField(_addressController, 'العنوان'),
                    _buildTextField(_phoneNumberController, 'رقم الهاتف', keyboardType: TextInputType.phone),
                    _buildTextField(_imageController, 'رابط الصورة', onChanged: (_) => setState(() {})),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveRestaurant,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.save, color: Colors.white),
                  label: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('حفظ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          )),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String labelText,
      {TextInputType keyboardType = TextInputType.text, Function(String)? onChanged}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: labelText,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        validator: (value) => value == null || value.trim().isEmpty ? 'يرجى إدخال $labelText' : null,
        onChanged: onChanged,
      ),
    );
  }
}
