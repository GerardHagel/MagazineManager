import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddItemView extends StatefulWidget {
  final int productId;
  final String token;
  final String apiUrl;

  const AddItemView({
    super.key,
    required this.productId,
    required this.token,
    required this.apiUrl,
  });

  @override
  State<AddItemView> createState() => _AddItemViewState();
}

class _AddItemViewState extends State<AddItemView> {
  bool isSubmitting = false;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController locationController = TextEditingController();

  Future<void> submit() async {
    if (isSubmitting) return;

    if (_formKey.currentState!.validate()) {
      setState(() => isSubmitting = true);

      final int productId = widget.productId;
      final int amount = int.parse(amountController.text);
      final String location = locationController.text;

      final response = await http.post(
        Uri.parse('${widget.apiUrl}/api/stock/add'),
        headers: {'Token': widget.token, 'Content-Type': 'application/json'},
        body: jsonEncode({
          'ProductID': productId,
          'Amount': amount,
          'Location': location,
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Dodano produkt!')));
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Błąd: ${response.body}')));
          setState(() => isSubmitting = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dodaj przedmiot do stock')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text(
                'Produkt: ID ${widget.productId}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: amountController,
                decoration: const InputDecoration(labelText: 'Ilość'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Wpisz ilość' : null,
              ),
              TextFormField(
                controller: locationController,
                decoration: const InputDecoration(labelText: 'Lokalizacja'),
                validator: (value) =>
                    value!.isEmpty ? 'Wpisz lokalizację' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: isSubmitting ? null : submit,
                child: isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Zatwierdź'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
