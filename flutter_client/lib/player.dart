import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flame/collisions.dart';
import 'package:flutter_client/enemy.dart';

import 'main.dart';


// ==================== PlayerComponent ====================
class PlayerComponent extends RectangleComponent with HasGameReference<MyGame> {
  PlayerComponent()
      : super(
          position: Vector2(100, 30),
          size: Vector2(16, 16),
          paint: Paint()..color = Colors.green,
        );
    double maxHealth = 5;
    double currentHealth = 5;
  @override
  void update(double dt) {
    super.update(dt);
    final game = this.game;

    if (MyGame.isMovingUp) {
      position.y -= MyGame.playerSpeed * dt;
      game.lastDirection = Vector2(0, -1);
    }
    if (MyGame.isMovingDown) {
      position.y += MyGame.playerSpeed * dt;
      game.lastDirection = Vector2(0, 1);
    }
    if (MyGame.isMovingLeft) {
      position.x -= MyGame.playerSpeed * dt;
      game.lastDirection = Vector2(-1, 0);
    }
    if (MyGame.isMovingRight) {
      position.x += MyGame.playerSpeed * dt;
      game.lastDirection = Vector2(1, 0);
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

  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other){

    if (other is EnemyBaseComponent){
        takeDamage(1);
        print('플레이어 피격! 현재 체력: $currentHealth');
    }
  }
}