import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:magazine_manager/main.dart';
import 'package:magazine_manager/services/item_service.dart';
import 'package:magazine_manager/services/stock_service.dart';
import 'dart:convert';
import 'item_detail_view.dart';
import 'models/item.dart';
import 'l10n/app_localizations.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';

class ItemListView extends StatefulWidget {
  final String token;
  final String apiUrl;
  final bool isOfflineMode;
  final bool isReadOnly;

  const ItemListView({
    super.key,
    required this.token,
    required this.apiUrl,
    this.isOfflineMode = false,
    this.isReadOnly = false,
  });

  @override
  State<ItemListView> createState() => _ItemListViewState();
}

class _ItemListViewState extends State<ItemListView> {
  List<Item> items = [];
  bool isLoading = true;
  String? errorMessage;

  Future<void> syncPendingItems() async {
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) return;

    final box = Hive.box('pendingItemsBox');
    final List<dynamic> pendingList = box.get('items', defaultValue: []);

    if (pendingList.isEmpty) return;

    final List<dynamic> successfullySynced = [];

    for (final itemData in pendingList) {
      try {
        final response = await http.post(
          Uri.parse('${widget.apiUrl}/api/stock/add'),
          headers: {'Token': widget.token, 'Content-Type': 'application/json'},
          body: jsonEncode(itemData),
        );

        if (response.statusCode == 200) {
          successfullySynced.add(itemData);
        }
      } catch (e) {
        // Możesz logować błędy, ale nie przerywaj całej synchronizacji
      }
    }

    if (successfullySynced.isNotEmpty) {
      final remaining = pendingList
          .where((e) => !successfullySynced.contains(e))
          .toList();
      await box.put('items', remaining);
    }
  }

  late final ItemService itemService;

  @override
  void initState() {
    super.initState();
    itemService = ItemService(token: widget.token, apiUrl: widget.apiUrl);
    final stockSvc = StockService(token: widget.token, apiUrl: widget.apiUrl);
    stockSvc.syncPending();
    _loadItems();
  }

  Future<void> _loadItems() async {
    try {
      final data = await itemService.fetchItems(widget.isOfflineMode);
      setState(() {
        items = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.itemListTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: loc.logoutTooltip,
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
                          isReadOnly: widget.isReadOnly,
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
