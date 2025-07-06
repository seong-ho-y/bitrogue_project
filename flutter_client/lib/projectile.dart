import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'enemy.dart';

import 'main.dart';

// ==================== ProjectileComponent ====================
class ProjectileComponent extends RectangleComponent with HasGameReference<MyGame>, CollisionCallbacks {
  final Vector2 direction;
  final double speed = 300;
  double lifeSpan; // 발사체의 수명 (초)
  double _age = 0; // 발사체가 살아온 시간

  ProjectileComponent(Vector2 position, this.direction, {this.lifeSpan = 1.0}) // 기본 수명 1초
      : super(
          position: position,
          size: Vector2(8, 8),
          paint: Paint()..color = Colors.yellow,
        );

  @override
  void onLoad(){
    super.onLoad();
    add(RectangleHitbox()); //Hitbox 추가
  }

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    if (_age >= lifeSpan) {
      removeFromParent(); // 수명이 다하면 제거
      return;
    }
    position += direction * speed * dt;
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    if (other is EnemyBaseComponent) {
      other.takeDamage(1);
      removeFromParent(); // 투사체 제거
    }
  }
}