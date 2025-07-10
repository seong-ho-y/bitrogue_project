
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_client/player.dart';

import 'main.dart';

class EnemyProjectile extends RectangleComponent with HasGameReference<MyGame>, CollisionCallbacks {
  final Vector2 direction;
  final double speed;
  double lifeSpan;
  double _age = 0;

  EnemyProjectile({
    required Vector2 position,
    required this.direction,
    this.speed = 200,
    this.lifeSpan = 2.0,
    Vector2? size,
  }) : super(
          position: position,
          size: size ?? Vector2(8, 8),
          paint: Paint()..color = Colors.red,
        );

  @override
  void onLoad() {
    super.onLoad();
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    if (_age >= lifeSpan) {
      removeFromParent();
      return;
    }
    position += direction * speed * dt;
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is PlayerComponent) {
      other.takeDamage(1);
      removeFromParent();
    }
  }
}
