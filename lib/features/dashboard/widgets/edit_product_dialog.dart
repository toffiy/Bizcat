import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EditProductDialog extends StatefulWidget {
  final String initialName;
  final int initialQty;
  final int initialPrice; // 🔹 price as int since whole numbers only
  final Future<void> Function(String name, int qty, int price) onSubmit;

  const EditProductDialog({
    super.key,
    required this.initialName,
    required this.initialQty,
    required this.initialPrice,
    required this.onSubmit,
  });

  static Future<void> show(
    BuildContext context, {
    required String name,
    required int qty,
    required int price,
    required Future<void> Function(String, int, int) onSubmit,
  }) {
    return showDialog(
      context: context,
      builder: (_) => EditProductDialog(
        initialName: name,
        initialQty: qty,
        initialPrice: price,
        onSubmit: onSubmit,
      ),
    );
  }

  @override
  State<EditProductDialog> createState() => _EditProductDialogState();
}

class _EditProductDialogState extends State<EditProductDialog> {
  late TextEditingController _nameController;
  late TextEditingController _qtyController;
  late TextEditingController _priceController;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _qtyController = TextEditingController(text: widget.initialQty.toString());
    _priceController = TextEditingController(text: widget.initialPrice.toString());
  }

  void _handleSave() async {
    final name = _nameController.text.trim();
    final qty = int.tryParse(_qtyController.text) ?? -1;
    final price = int.tryParse(_priceController.text) ?? -1;

    // Validation
    if (name.isEmpty) {
      setState(() => _errorMessage = "Product name cannot be empty");
      return;
    }
    if (qty < 0) {
      setState(() => _errorMessage = "Quantity must be a whole number ≥ 0");
      return;
    }
    if (price < 0) {
      setState(() => _errorMessage = "Price must be a whole number ≥ 0");
      return;
    }

    setState(() => _errorMessage = null);

    await widget.onSubmit(name, qty, price);
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Text(
        "Edit Product",
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9]')), // ✅ only digits allowed
            ],
            decoration: const InputDecoration(
              labelText: "Quantity",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9]')), // ✅ only digits allowed
            ],
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
          onPressed: _handleSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: const Text(
            "Save",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
