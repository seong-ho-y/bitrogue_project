import 'dart:math';
import 'package:flame/components.dart';
import 'item.dart';
import 'item_service.dart';
import 'main.dart';

class ItemManager extends Component with HasGameReference<MyGame> {
  final ItemService _itemService = ItemService();
  List<Item> _availableItems = [];
  int _lastSpawnScore = 0;
  final Random _random = Random();

  @override
  Future<void> onLoad() async {
    super.onLoad();
    // 게임 시작 시 서버에서 아이템 목록을 가져옵니다.
    try {
      _availableItems = await _itemService.getAllItems();
      print('Successfully loaded ${_availableItems.length} items from the server.');
    } catch (e) {
      print('Error loading items: $e');
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // 아이템 목록이 비어있으면 아무것도 하지 않습니다.
    if (_availableItems.isEmpty) {
      return;
    }

    // 현재 점수가 마지막 스폰 점수보다 500점 이상 높으면 아이템을 스폰합니다.
    if (MyGame.score >= _lastSpawnScore + 500) {
      _spawnItem();
      // 다음 스폰 기준 점수를 현재 점수대의 500점 단위로 설정합니다.
      // 예: 점수가 520점이면, 다음 스폰은 1000점부터이므로 _lastSpawnScore는 500이 됩니다.
      _lastSpawnScore = (MyGame.score ~/ 500) * 500;
    }
  }

  void _spawnItem() {
    // 사용 가능한 아이템 중 하나를 무작위로 선택합니다.
    final randomItem = _availableItems[_random.nextInt(_availableItems.length)];

    // 게임 화면 내의 무작위 위치를 생성합니다.
    final spawnPosition = Vector2(
      _random.nextDouble() * game.size.x,
      _random.nextDouble() * game.size.y,
    );

    // ItemComponent를 생성하여 게임에 추가합니다.
    final itemComponent = ItemComponent(itemData: randomItem, position: spawnPosition);
    game.add(itemComponent);

    print('Spawned item: ${randomItem.name} at $spawnPosition');
  }
}
