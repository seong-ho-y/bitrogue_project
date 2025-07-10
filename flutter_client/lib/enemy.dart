import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter_client/enemy_projectile.dart';
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

// 빠른 적
class RunnerEnemy extends EnemyBaseComponent {
  RunnerEnemy({Vector2? position}) : super(
    maxHealth: 3,
    moveSpeed: 120,
    position: position,
    size: Vector2(12, 12),
  );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    paint = Paint()..color = Colors.blue;
  }
}

// 원거리 공격 적
class RangerEnemy extends EnemyBaseComponent {
  late Timer _attackTimer;
  final double _attackCooldown = 2.0;
  final double _preferredDistance = 150.0;

  RangerEnemy({Vector2? position}) : super(
    maxHealth: 4,
    moveSpeed: 50,
    position: position,
    size: Vector2(20, 20),
  ) {
    _attackTimer = Timer(_attackCooldown, repeat: true, onTick: _attack);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    paint = Paint()..color = Colors.green;
    _attackTimer.start();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _attackTimer.update(dt);

    final player = game.children.whereType<PlayerComponent>().firstOrNull;
    if (player != null) {
      final distance = position.distanceTo(player.position);
      if (distance < _preferredDistance) {
        // 플레이어와 너무 가까우면 뒤로 물러남
        final direction = (position - player.position).normalized();
        position += direction * moveSpeed * dt;
      } else {
        // 적정 거리를 유지하며 플레이어를 향해 이동
        final direction = (player.position - position).normalized();
        position += direction * moveSpeed * dt;
      }
    }
  }

  void _attack() {
    final player = game.children.whereType<PlayerComponent>().firstOrNull;
    if (player != null) {
      final direction = (player.position - position).normalized();
      game.add(EnemyProjectile(
        position: position.clone(),
        direction: direction,
      ));
    }
  }
}

// 소환하는 적
class SummonerEnemy extends EnemyBaseComponent {
  late Timer _summonTimer;
  final double _summonCooldown = 5.0;

  SummonerEnemy({Vector2? position}) : super(
    maxHealth: 8,
    moveSpeed: 30,
    position: position,
    size: Vector2(24, 24),
  ) {
    _summonTimer = Timer(_summonCooldown, repeat: true, onTick: _summon);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    paint = Paint()..color = Colors.purple;
    _summonTimer.start();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _summonTimer.update(dt);
  }

  void _summon() {
    // 주변에 작은 적(RunnerEnemy)을 소환
    for (int i = 0; i < 2; i++) {
      final offset = Vector2(Random().nextDouble() * 40 - 20, Random().nextDouble() * 40 - 20);
      game.add(RunnerEnemy(position: position + offset));
    }
  }
}
