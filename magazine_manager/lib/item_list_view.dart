import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:magazine_manager/main.dart';
import 'dart:convert';
import 'item_detail_view.dart';
import 'models/item.dart';
import 'l10n/app_localizations.dart';

class ItemListView extends StatefulWidget {
  final String token;
  final String apiUrl;
  const ItemListView({super.key, required this.token, required this.apiUrl});

  @override
  State<ItemListView> createState() => _ItemListViewState();
}

class _ItemListViewState extends State<ItemListView> {
  List<Item> items = [];
  bool isLoading = true;
  String? errorMessage;

  Future<void> fetchItems() async {
    try {
      final response = await http.get(
        Uri.parse('${widget.apiUrl}/api/item/index'),
        headers: {'Token': widget.token, 'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        final List<dynamic> data = responseBody['array'];
        if (mounted) {
          setState(() {
            items = data.map((json) => Item.fromJson(json)).toList();
            isLoading = false;
            errorMessage = null;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            errorMessage =
                'Nie udało się pobrać danych'; // Możesz dodać tłumaczenie
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Błąd podczas pobierania danych: $e';
          isLoading = false;
        });
      }
      print('Błąd podczas pobierania: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchItems();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.itemListTitle), // np. "Lista przedmiotów"
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: loc.logoutTooltip, // np. "Wyloguj się"
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      MyApp(initialLocale: Localizations.localeOf(context)),
                ),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(child: Text(errorMessage!))
          : ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return ListTile(
                  leading: CircleAvatar(child: Text(item.id.toString())),
                  title: Text(item.name),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ItemDetailView(
                          item: item,
                          token: widget.token,
                          apiUrl: widget.apiUrl,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
