import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_client/main.dart';
import 'package:flutter_client/projectile.dart';

abstract class Weapon { //추상클래스로 해서 구체화 할거임
  /// 무기 코드
  final String code;
  /// 무기 이름
  final String name;
  /// 공격 후 다음 공격까지의 딜레이 (초)
  final double coolDown;
  /// 최대 탄약 수
  final int maxAmmo;
  /// 재장전 시간 (초)
  final double reloadTime;

  /// 현재 탄약 수
  ValueNotifier<int> currentAmmoNotifier;
  /// 재장전 중인지 여부
  bool isReloading = false;
  /// 재장전 타이머
  double reloadTimer = 0.0;

  /// 마지막으로 공격한 시간
  double lastAttackTime = 0.0;

  Weapon({required this.code, required this.name, required this.coolDown, required this.maxAmmo, required this.reloadTime})
      : currentAmmoNotifier = ValueNotifier(maxAmmo);

  /// 공격
  void attack(MyGame game, Vector2 playerPosition, Vector2 playerDirection, {double chargeTime = 0.0});

  /// 재장전 시작하
  void startReload() {
    if (!isReloading) {
      isReloading = true;
      reloadTimer = reloadTime;
      print('${name} 재장전 시작...');
    }
  }

  /// 재장전 상태 업데이트
  void updateReload(double dt) {
    if (isReloading) {
      reloadTimer -= dt;
      if (reloadTimer <= 0) {
        currentAmmoNotifier.value = maxAmmo; // 탄약 채우기
        isReloading = false;
        print('${name} 재장전 완료! 탄약: ${currentAmmoNotifier.value}/$maxAmmo');
      }
    }
  }

  void _decreaseAmmo() {
    currentAmmoNotifier.value--;
  }
}


// ==================== 구체적인 무기 구현 가보자 ====================

//라이플 클래스
class Rifle extends Weapon {
  Rifle() : super(code: 'W001', name: 'Rifle', coolDown: 0.01, maxAmmo: 100, reloadTime: 2.0);

  @override
  void attack(MyGame game, Vector2 playerPosition, Vector2 playerDirection, {double chargeTime = 0.0}) {
    if (currentAmmoNotifier.value <= 0) {
      startReload();
      return;
    }
    if (isReloading) return;

    if (game.currentTime() - lastAttackTime >= coolDown) {
      game.add(ProjectileComponent(playerPosition, playerDirection, lifeSpan: 1.0));
      _decreaseAmmo();
      lastAttackTime = game.currentTime();
      print("Rifle fired! Ammo: ${currentAmmoNotifier.value}/$maxAmmo");
    }
  }
}

//샷건 클래스
class Shotgun extends Weapon {
  Shotgun() : super(code: 'W006', name: 'Shotgun', coolDown: 0.4, maxAmmo: 10, reloadTime: 3.0);

  @override
  void attack(MyGame game, Vector2 playerPosition, Vector2 playerDirection, {double chargeTime = 0.0}) {
    if (currentAmmoNotifier.value <= 0) {
      startReload();
      return;
    }
    if (isReloading) return;

    if (game.currentTime() - lastAttackTime >= coolDown) {
      const int bulletCount = 5;
      const double spreadAngle = pi / 8; // 22.5도

      for (int i = 0; i < bulletCount; i++) {
        final angle = (i - (bulletCount - 1) / 2) * (spreadAngle / (bulletCount - 1));
        final rotatedDirection = playerDirection.clone()..rotate(angle);

        game.add(ProjectileComponent(
          playerPosition.clone(),
          rotatedDirection,
          lifeSpan: 0.2,
        ));
      }
      _decreaseAmmo();
      lastAttackTime = game.currentTime();
      print("Shotgun fired! Ammo: ${currentAmmoNotifier.value}/$maxAmmo");
    }
  }
}

//차지샷 클래스
class ChargeShot extends Weapon {
  ChargeShot() : super(code: 'W002', name: 'Charge Shot', coolDown: 0.3, maxAmmo: 5, reloadTime: 4.0);

  @override
  void attack(MyGame game, Vector2 playerPosition, Vector2 playerDirection, {double chargeTime = 0.0}) {
    if (currentAmmoNotifier.value <= 0) {
      startReload();
      return;
    }
    if (isReloading) return;

    if (game.currentTime() - lastAttackTime >= coolDown) {
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
      _decreaseAmmo();
      lastAttackTime = game.currentTime();
      print("Charge Shot fired! Ammo: ${currentAmmoNotifier.value}/$maxAmmo");
    }
  }
}

// 4방향으로 분열되는 크랙샷 클래스
class CrackShot extends Weapon {
  CrackShot() : super(code: 'W003', name: 'Crack Shot', coolDown: 0.2, maxAmmo: 15, reloadTime: 3.5);

  @override
  void attack(MyGame game, Vector2 playerPosition, Vector2 playerDirection, {double chargeTime = 0.0}) {
    if (currentAmmoNotifier.value <= 0) {
      startReload();
      return;
    }
    if (isReloading) return;

    if (game.currentTime() - lastAttackTime >= coolDown) {
      game.add(ProjectileComponent(playerPosition, playerDirection, lifeSpan: 0.8, type: ProjectileType.crack));
      _decreaseAmmo();
      lastAttackTime = game.currentTime();
      print("Crack Shot fired! Ammo: ${currentAmmoNotifier.value}/$maxAmmo");
    }
  }
}

// 레이저 클래스
class Laser extends Weapon {
  Laser() : super(code: 'W004', name: 'Laser', coolDown: 0.3, maxAmmo: 20, reloadTime: 5.0);

  @override
  void attack(MyGame game, Vector2 playerPosition, Vector2 playerDirection, {double chargeTime = 0.0}) {
    if (currentAmmoNotifier.value <= 0) {
      startReload();
      return;
    }
    if (isReloading) return;

    if (game.currentTime() - lastAttackTime >= coolDown) {
      game.add(ProjectileComponent(playerPosition, playerDirection, lifeSpan: 1.5, type: ProjectileType.laser));
      _decreaseAmmo();
      lastAttackTime = game.currentTime();
      print("Laser fired! Ammo: ${currentAmmoNotifier.value}/$maxAmmo");
    }
  }
}

// 기폭탄 클래스
class ProximityMine extends Weapon {
  ProximityMine() : super(code: 'W005', name: 'Proximity Mine', coolDown: 0.7, maxAmmo: 3, reloadTime: 2.5);

  @override
  void attack(MyGame game, Vector2 playerPosition, Vector2 playerDirection, {double chargeTime = 0.0}) {
    if (currentAmmoNotifier.value <= 0) {
      startReload();
      return;
    }
    if (isReloading) return;

    if (game.currentTime() - lastAttackTime >= coolDown) {
      game.add(ProjectileComponent(playerPosition, playerDirection, lifeSpan: 2.0, type: ProjectileType.mine));
      _decreaseAmmo();
      lastAttackTime = game.currentTime();
      print("Proximity Mine fired! Ammo: ${currentAmmoNotifier.value}/$maxAmmo");
    }
  }
}