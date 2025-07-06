import 'dart:convert';
import 'package:http/http.dart' as http;
import 'item.dart';

class ItemService {
  // 아이템 정보를 제공하는 codex 서버의 주소입니다.
  // 안드로이드 에뮬레이터에서 localhost에 접근하려면 10.0.2.2를 사용해야 합니다.
  final String _baseUrl = 'http://192.168.45.180:8001';

  // 서버로부터 모든 아이템 목록을 가져오는 함수
  Future<List<Item>> getAllItems() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/items'));

      // 서버가 성공적으로 응답했을 때 (상태 코드 200)
      if (response.statusCode == 200) {
        // 응답 본문(body)은 JSON 형태의 문자열이므로, jsonDecode로 파싱합니다.
        // 서버에서 [{"code":...}, {"code":...}] 형태의 리스트를 보내주므로 List<dynamic>으로 변환합니다.
        List<dynamic> body = jsonDecode(response.body);
        
        // 각 JSON 객체를 Item.fromJson을 사용해 Item 객체로 변환하고, 리스트로 만듭니다.
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
