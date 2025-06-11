import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:magazine_manager/main.dart';
import 'dart:convert';
import 'item_detail_view.dart';
import 'models/item.dart';

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
          });
        }
      } else {
        throw Exception('Nie udało się pobrać danych');
      }
    } catch (e) {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista przedmiotów'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Wyloguj się',
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => const MyHomePage(title: 'Zaloguj się'),
                ),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
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
