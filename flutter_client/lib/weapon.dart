import 'dart:math';
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
  void attack(MyGame game, Vector2 playerPosition, Vector2 playerDirection, {double chargeTime = 0.0});
}


// ==================== 구체적인 무기 구현 ====================

/// 가장 기본적인 무기인 라이플 클래스입니다.
class Rifle extends Weapon {
  Rifle() : super(name: 'Rifle', coolDown: 0.4);

  @override
  void attack(MyGame game, Vector2 playerPosition, Vector2 playerDirection, {double chargeTime = 0.0}) {
    // 긴 사정거리를 가진 발사체를 생성합니다.
    game.add(ProjectileComponent(playerPosition, playerDirection, lifeSpan: 1.0));
    print("Rifle fired!");
  }
}

/// 5발을 동시에 발사하지만 사정거리가 짧은 샷건 클래스입니다.
class Shotgun extends Weapon {
  Shotgun() : super(name: 'Shotgun', coolDown: 0.8);

  @override
  void attack(MyGame game, Vector2 playerPosition, Vector2 playerDirection, {double chargeTime = 0.0}) {
    const int bulletCount = 5;
    const double spreadAngle = pi / 8; // 22.5도

    for (int i = 0; i < bulletCount; i++) {
      // 각 총알의 각도를 계산합니다.
      final angle = (i - (bulletCount - 1) / 2) * (spreadAngle / (bulletCount - 1));
      final rotatedDirection = playerDirection.clone()..rotate(angle);

      // 짧은 사정거리를 가진 발사체를 생성합니다.
      game.add(ProjectileComponent(
        playerPosition.clone(),
        rotatedDirection,
        lifeSpan: 0.2,
      ));
    }
    print("Shotgun fired!");
  }
}

/// 차지 시간에 따라 발사체 위력이 강해지는 차지샷 클래스입니다.
class ChargeShot extends Weapon {
  ChargeShot() : super(name: 'Charge Shot', coolDown: 0.5);

  @override
  void attack(MyGame game, Vector2 playerPosition, Vector2 playerDirection, {double chargeTime = 0.0}) {
    double damage = 1.0;
    Vector2 size = Vector2(8, 8);
    double lifeSpan = 1.2;

    if (chargeTime >= 1.5) { // 3단계 (1.5초 이상)
      damage = 3.0;
      size = Vector2(24, 24);
      lifeSpan = 2.0;
      print("Charge Shot Level 3!");
    } else if (chargeTime >= 0.7) { // 2단계 (0.7초 이상)
      damage = 2.0;
      size = Vector2(16, 16);
      lifeSpan = 1.6;
      print("Charge Shot Level 2!");
    } else { // 1단계 (기본)
      print("Charge Shot Level 1!");
    }

    game.add(ProjectileComponent(playerPosition, playerDirection, lifeSpan: lifeSpan, type: ProjectileType.standard, damage: damage, size: size));
  }
}

/// 일정 거리 이동 후 4방향으로 분열되는 크랙샷 클래스입니다.
class CrackShot extends Weapon {
  CrackShot() : super(name: 'Crack Shot', coolDown: 0.7);

  @override
  void attack(MyGame game, Vector2 playerPosition, Vector2 playerDirection, {double chargeTime = 0.0}) {
    game.add(ProjectileComponent(playerPosition, playerDirection, lifeSpan: 0.8, type: ProjectileType.crack));
    print("Crack Shot fired!");
  }
}

/// 적을 관통하는 레이저 클래스입니다.
class Laser extends Weapon {
  Laser() : super(name: 'Laser', coolDown: 1.0);

  @override
  void attack(MyGame game, Vector2 playerPosition, Vector2 playerDirection, {double chargeTime = 0.0}) {
    game.add(ProjectileComponent(playerPosition, playerDirection, lifeSpan: 1.5, type: ProjectileType.laser));
    print("Laser fired!");
  }
}

/// 짧은 사정거리를 가지고, 일정 시간 후 폭발하는 기폭탄 클래스입니다.
class ProximityMine extends Weapon {
  ProximityMine() : super(name: 'Proximity Mine', coolDown: 1.2);

  @override
  void attack(MyGame game, Vector2 playerPosition, Vector2 playerDirection, {double chargeTime = 0.0}) {
    game.add(ProjectileComponent(playerPosition, playerDirection, lifeSpan: 2.0, type: ProjectileType.mine));
    print("Proximity Mine fired!");
  }
}