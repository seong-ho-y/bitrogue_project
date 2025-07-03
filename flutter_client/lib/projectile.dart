import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'main.dart';

// ==================== ProjectileComponent ====================
class ProjectileComponent extends RectangleComponent with HasGameReference<MyGame> {
  final Vector2 direction;
  final double speed = 300;

  ProjectileComponent(Vector2 position, this.direction)
      : super(
          position: position,
          size: Vector2(8, 8),
          paint: Paint()..color = Colors.yellow,
        );

  @override
  void update(double dt) {
    super.update(dt);
    position += direction * speed * dt;

    if (game.size.x != null) {
      if (position.x < 0 || position.x > game.size.x ||
          position.y < 0 || position.y > game.size.y) {
        removeFromParent();
      }
    }
  }
}