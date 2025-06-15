import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import '../models/item.dart';

class ItemService {
  final String token;
  final String apiUrl;

  ItemService({required this.token, required this.apiUrl});

  Future<List<Item>> fetchItems(bool forceOffline) async {
    final connectivity = await Connectivity().checkConnectivity();
    final isOffline = forceOffline || connectivity == ConnectivityResult.none;
    final box = Hive.box('itemsBox');

    if (isOffline) {
      final cached = box.get('items');
      if (cached != null) {
        return (cached as List).map((e) => Item.fromJson(e)).toList();
      } else {
        throw Exception('Brak danych offline');
      }
    }

    final response = await http.get(
      Uri.parse('$apiUrl/api/item/index'),
      headers: {'Token': token, 'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['array'] as List;
      await box.put('items', data);
      return data.map((e) => Item.fromJson(e)).toList();
    } else {
      throw Exception('Błąd serwera: ${response.statusCode}');
    }
  }
}
