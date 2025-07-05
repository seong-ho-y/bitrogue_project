import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_client/enemyManager.dart';
import 'package:flutter_client/projectile.dart';
import 'main.dart';
import 'player.dart';

class EnemyBaseComponent extends RectangleComponent with HasGameReference<MyGame>, CollisionCallbacks {
  double maxHealth;
  double currentHealth;
  double moveSpeed;

  // 생성자
  EnemyBaseComponent({
    required this.maxHealth,
    required this.moveSpeed,
    Vector2? position,
    Vector2? size,
  }) : currentHealth = maxHealth,
       super(
         position: position ?? Vector2.zero(),
         size: size ?? Vector2.all(16),
         anchor: Anchor.center,
       );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 색상 기본값
    paint = Paint()..color = const Color.fromARGB(255, 212, 44, 137);

    // 충돌 박스 추가
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);

    final player = game.children.whereType<PlayerComponent>().firstOrNull;

    if (player!=null){
      final direction = (player.position - position).normalized();
      position += direction * moveSpeed * dt;
    }
  }

  /// 피해 처리 함수
  void takeDamage(double damage) {
    currentHealth -= damage;
    if (currentHealth <= 0) {
      die();
    }
  }

  /// 사망 처리
  void die() {
    MyGame.score += 100;
    if( MyGame.score % 500 == 0 ){
      EnemyManager.spawnCool /= 1.09;
    }
    removeFromParent();
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other){
    super.onCollision(intersectionPoints, other);

     if (other is EnemyBaseComponent) {
    // 적끼리 충돌 시 간단히 밀어내기
    final delta = (position - other.position).normalized();
    position += delta * 1; // 1픽셀 정도 밀어내기
    }
  }
}
