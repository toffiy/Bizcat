import 'package:flutter/material.dart';

class EditProductDialog extends StatefulWidget {
  final String initialName;
  final int initialQty;
  final double initialPrice;
  final Future<void> Function(String name, int qty, double price) onSubmit;

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
    required double price,
    required Future<void> Function(String, int, double) onSubmit,
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
    final price = double.tryParse(_priceController.text) ?? -1.0;

    // Validation
    if (name.isEmpty) {
      setState(() => _errorMessage = "Product name cannot be empty");
      return;
    }
    if (qty < 0) { // ✅ allows 0, blocks negatives
      setState(() => _errorMessage = "Quantity cannot be negative");
      return;
    }
    if (price < 0) { // ✅ allows 0.0, blocks negatives
      setState(() => _errorMessage = "Price cannot be negative");
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
