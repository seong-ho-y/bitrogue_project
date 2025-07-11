import 'dart:convert';
import 'package:http/http.dart' as http;
import 'item.dart';

class ItemService {
  final String _baseUrl = 'http://192.168.45.245:8001';

  // 서버로부터 모든 아이템 목록을 가져오는 함수
  Future<List<Item>> getAllItems() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/items'));

      // 서버가 성공적으로 응답했을 때
      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        
        List<Item> items = body.map((dynamic item) => Item.fromJson(item)).toList();
        return items;
      } else {
        // 서버가 에러 코드를 반환했을 때
        throw Exception('Failed to load items from server. Status code: ${response.statusCode}');
      }
    } catch (e) {
      // 네트워크 오류 등 http 요청 자체에서 에러가 발생했을 때
      throw Exception('Failed to connect to the item server: $e');
    }
  }
}
