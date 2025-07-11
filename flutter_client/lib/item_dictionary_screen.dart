
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_client/constants.dart';

class ItemDictionaryScreen extends StatefulWidget {
  const ItemDictionaryScreen({super.key});

  @override
  State<ItemDictionaryScreen> createState() => _ItemDictionaryScreenState();
}

class _ItemDictionaryScreenState extends State<ItemDictionaryScreen> {
  late Future<List<dynamic>> _itemDataFuture;

  @override
  void initState() {
    super.initState();
    _itemDataFuture = _fetchItems();
  }

  Future<List<dynamic>> _fetchItems() async {
    try {
      final response = await http.get(Uri.parse('${AppConstants.codexBaseUrl}/items'));

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('Failed to load items: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching items: $e');
      throw Exception('Failed to connect to server or parse data.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Item Dictionary'),
        backgroundColor: Colors.blueGrey[800],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blueGrey[900]!, Colors.blueGrey[700]!],
          ),
        ),
        child: FutureBuilder<List<dynamic>>(
          future: _itemDataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text('No items found.', style: TextStyle(color: Colors.white)),
              );
            } else {
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final item = snapshot.data![index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: Colors.blueGrey[800],
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${item['name']} (${item['code']})',
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item['description'],
                            style: TextStyle(color: Colors.grey[300], fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Effect: ${item['effect']}',
                            style: TextStyle(color: Colors.lightBlue[200], fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }
}
