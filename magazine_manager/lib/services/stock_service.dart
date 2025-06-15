import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import '../models/stock.dart';

class StockService {
  final String token;
  final String apiUrl;

  StockService({required this.token, required this.apiUrl});

  Future<List<Stock>> fetchStock(int productId) async {
    final conn = await Connectivity().checkConnectivity();
    final isOffline = conn == ConnectivityResult.none;
    final box = Hive.box('stockBox');

    if (isOffline) {
      final cached = box.get('stock');
      if (cached != null) {
        final list = (jsonDecode(cached) as List)
            .map((e) => Stock.fromJson(e))
            .toList();
        return list.where((s) => s.productId == productId).toList();
      }
      return [];
    }

    final response = await http.get(
      Uri.parse('$apiUrl/api/stock/index'),
      headers: {'Token': token, 'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body)['array'] as List;
      await box.put('stock', jsonEncode(list));
      return list
          .map((e) => Stock.fromJson(e))
          .where((s) => s.productId == productId)
          .toList();
    } else {
      throw Exception('Błąd stock: ${response.statusCode}');
    }
  }

  Future<void> syncPending() async {
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) return;
    final box = Hive.box('pendingItemsBox');
    final pending = (box.get('items', defaultValue: []) as List).cast<Map>();
    final success = <Map>[];

    for (var itemData in pending) {
      final res = await http.post(
        Uri.parse('$apiUrl/api/stock/add'),
        headers: {'Token': token, 'Content-Type': 'application/json'},
        body: jsonEncode(itemData),
      );
      if (res.statusCode == 200) success.add(itemData);
    }

    final remaining = pending.where((e) => !success.contains(e)).toList();
    await box.put('items', remaining);
  }
}
