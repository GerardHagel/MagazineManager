import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:magazine_manager/l10n/app_localizations.dart';
import 'package:magazine_manager/models/item.dart';

class AddItemView extends StatefulWidget {
  final Item item;
  final String token;
  final String apiUrl;

  const AddItemView({
    super.key,
    required this.item,
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

      final int id = widget.item.id;
      final int amount = int.parse(amountController.text);
      final String location = locationController.text;

      final response = await http.post(
        Uri.parse('${widget.apiUrl}/api/stock/add'),
        headers: {'Token': widget.token, 'Content-Type': 'application/json'},
        body: jsonEncode({
          'ProductID': id,
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
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(loc.addItem)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text(
                widget.item.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: amountController,
                decoration: InputDecoration(labelText: loc.amount),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? loc.setAmount : null,
              ),
              TextFormField(
                controller: locationController,
                decoration: InputDecoration(labelText: loc.location),
                validator: (value) => value!.isEmpty ? loc.setLocation : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: isSubmitting ? null : submit,
                child: isSubmitting
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(loc.confirm),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
