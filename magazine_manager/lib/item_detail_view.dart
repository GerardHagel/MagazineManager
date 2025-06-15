import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:magazine_manager/add_item_view.dart';
import 'package:magazine_manager/l10n/app_localizations.dart';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import 'package:magazine_manager/services/stock_service.dart';
import 'models/stock.dart';
import 'models/item.dart';

class ItemDetailView extends StatefulWidget {
  final Item item;
  final String token;
  final String apiUrl;
  final bool isReadOnly;

  const ItemDetailView({
    super.key,
    required this.item,
    required this.token,
    required this.apiUrl,
    this.isReadOnly = false,
  });

  @override
  State<ItemDetailView> createState() => _ItemDetailViewState();
}

class _ItemDetailViewState extends State<ItemDetailView> {
  late final StockService stockService;
  List<Stock> stockList = [];
  bool isLoading = true;

  Future<void> fetchStock() async {
    final connectivity = await Connectivity().checkConnectivity();
    final box = Hive.box('stockBox');

    if (connectivity == ConnectivityResult.none) {
      final cachedData = box.get('stock');
      print('Cached stock raw data: $cachedData');
      if (cachedData != null) {
        final List<dynamic> decodedJson = jsonDecode(cachedData);
        final allStock = decodedJson
            .map((json) => Stock.fromJson(json))
            .toList();
        setState(() {
          stockList = allStock
              .where((stock) => stock.productId == widget.item.id)
              .toList();
          isLoading = false;
          for (var stock in allStock) {
            print(
              'Stock productId: ${stock.productId}, Current item id: ${widget.item.id}',
            );
          }
        });
      } else {
        setState(() {
          stockList = [];
          isLoading = false;
        });
      }
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${widget.apiUrl}/api/stock/index'),
        headers: {'Token': widget.token, 'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body)['array'];
        await box.put('stock', data);

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
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    stockService = StockService(token: widget.token, apiUrl: widget.apiUrl);
    _loadStock();
  }

  Future<void> _loadStock() async {
    try {
      final data = await stockService.fetchStock(widget.item.id);
      setState(() {
        stockList = data;
        isLoading = false;
      });
    } catch (_) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text('${loc.details}: ${widget.item.name}')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : stockList.isEmpty
          ? Center(child: Text('Brak danych stock dla tego przedmiotu'))
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
      floatingActionButton: widget.isReadOnly
          ? null
          : FloatingActionButton(
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
