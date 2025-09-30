import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AddProductDialog extends StatefulWidget {
  final Future<void> Function(String name, int qty, double price, XFile image)
      onSubmit;

  const AddProductDialog({super.key, required this.onSubmit});

  static Future<void> show(
    BuildContext context,
    Future<void> Function(String, int, double, XFile) onSubmit,
  ) {
    return showDialog(
      context: context,
      builder: (_) => AddProductDialog(onSubmit: onSubmit),
    );
  }

  @override
  State<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> {
  final _nameController = TextEditingController();
  final _qtyController = TextEditingController();
  final _priceController = TextEditingController();

  XFile? _selectedImage;
  File? _imageFile;
  String? _errorMessage;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedImage = picked;
        _imageFile = File(picked.path);
      });
    }
  }

  void _handleAdd() async {
    final name = _nameController.text.trim();
    final qty = int.tryParse(_qtyController.text) ?? -1;
    final price = double.tryParse(_priceController.text) ?? -1.0;

    // Validation
    if (_selectedImage == null) {
      setState(() => _errorMessage = "Please select an image");
      return;
    }
    if (name.isEmpty) {
      setState(() => _errorMessage = "Product name cannot be empty");
      return;
    }
    if (qty <= 0) {
      setState(() => _errorMessage = "Quantity must be greater than 0");
      return;
    }
    if (price <= 0) {
      setState(() => _errorMessage = "Price must be greater than 0");
      return;
    }

    setState(() => _errorMessage = null);

    try {
      await widget.onSubmit(name, qty, price, _selectedImage!);
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceFirst("Exception: ", ""));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Text(
        "Add Product",
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: _imageFile != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(_imageFile!, fit: BoxFit.cover),
                    )
                  : const Center(
                      child: Text("Tap to select image",
                          style: TextStyle(color: Colors.grey)),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: "Name",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _qtyController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "Quantity",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "Price",
              border: OutlineInputBorder(),
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: _handleAdd,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: const Text(
            "Add",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
