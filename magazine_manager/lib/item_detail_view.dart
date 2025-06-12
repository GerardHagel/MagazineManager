import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:magazine_manager/add_item_view.dart';
import 'package:magazine_manager/l10n/app_localizations.dart';
import 'dart:convert';

import 'models/stock.dart';
import 'models/item.dart';

class ItemDetailView extends StatefulWidget {
  final Item item;
  final String token;
  final String apiUrl;

  const ItemDetailView({
    super.key,
    required this.item,
    required this.token,
    required this.apiUrl,
  });

  @override
  State<ItemDetailView> createState() => _ItemDetailViewState();
}

class _ItemDetailViewState extends State<ItemDetailView> {
  List<Stock> stockList = [];
  bool isLoading = true;

  Future<void> fetchStock() async {
    try {
      final response = await http.get(
        Uri.parse('${widget.apiUrl}/api/stock/index'),
        headers: {'Token': widget.token, 'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body)['array'];
        setState(() {
          stockList = data
              .map((json) => Stock.fromJson(json))
              .where((stock) => stock.productId == widget.item.id)
              .toList();
          isLoading = false;
        });
      } else {
        throw Exception('Błąd pobierania stock');
      }
    } catch (e) {
      print('Błąd: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchStock();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text('${loc.details}: ${widget.item.name}')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : stockList.isEmpty
          ? const Center(child: Text('Brak danych stock'))
          : ListView.builder(
              itemCount: stockList.length,
              itemBuilder: (context, index) {
                final stock = stockList[index];
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text('${loc.location}: ${stock.location}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${loc.amount}: ${stock.amount}'),
                        Text('${loc.date}: ${stock.date}'),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddItemView(
                item: widget.item,
                token: widget.token,
                apiUrl: widget.apiUrl,
              ),
            ),
          );

          if (result == true) {
            fetchStock();
          }
        },
      ),
    );
  }
}
