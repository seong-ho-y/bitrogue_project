
import 'package:flame/components.dart';
import 'package:flutter_client/main.dart';
import 'package:flutter_client/projectile.dart';

/// 모든 무기 클래스의 기반이 되는 추상 클래스입니다.
/// 스트래티지 패턴의 '전략' 역할을 합니다.
abstract class Weapon {
  /// 무기 이름
  final String name;
  /// 공격 후 다음 공격까지의 딜레이 (초)
  final double coolDown;
  /// 마지막으로 공격한 시간
  double lastAttackTime = 0.0;

  Weapon({required this.name, required this.coolDown});

  /// 공격을 수행하는 메소드.
  /// 각 무기는 이 메소드를 자신만의 방식으로 구현해야 합니다.
  void attack(MyGame game, Vector2 playerPosition, Vector2 playerDirection);
}


// ==================== 구체적인 무기 구현 ====================

/// 가장 기본적인 무기인 라이플 클래스입니다.
class Rifle extends Weapon {
  Rifle() : super(name: 'Rifle', coolDown: 0.4);

  @override
  void attack(MyGame game, Vector2 playerPosition, Vector2 playerDirection) {
    // ProjectileComponent를 생성하여 게임에 추가합니다.
    game.add(ProjectileComponent(playerPosition, playerDirection));
    print("Rifle fired!");
  }
}
