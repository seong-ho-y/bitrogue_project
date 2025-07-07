import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'enemy.dart';

import 'main.dart';

// 발사체 타입을 정의하는 열거형
enum ProjectileType {
  standard,
  crack, // 분열탄
  laser,   // 관통탄
  mine,    // 기폭탄
}

// ==================== ProjectileComponent ====================
class ProjectileComponent extends RectangleComponent with HasGameReference<MyGame>, CollisionCallbacks {
  final Vector2 direction;
  final double speed = 300;
  final ProjectileType type;
  final double damage; // 데미지 속성 추가
  double lifeSpan;
  double _age = 0;

  // 속성 추가
  bool _isSplitting = false; // 분열탄이 분열 중인지 여부

  ProjectileComponent(
    Vector2 position,
    this.direction,
    {
    this.lifeSpan = 1.0,
    this.type = ProjectileType.standard,
    this.damage = 1.0, // 기본 데미지 1
    Vector2? size, // 크기 매개변수 추가
  }) : super(
          position: position,
          size: size ?? Vector2(8, 8), // 기본 크기 또는 지정된 크기
          paint: Paint()..color = _getColorForType(type),
        );

  // 타입에 따라 색상을 결정하는 헬퍼 함수
  static Color _getColorForType(ProjectileType type) {
    switch (type) {
      case ProjectileType.crack:
        return Colors.orange;
      case ProjectileType.laser:
        return Colors.red;
      case ProjectileType.mine:
        return Colors.purple;
      default:
        return Colors.yellow;
    }
  }

  @override
  void onLoad() {
    super.onLoad();
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;

    // 타입별 로직 처리
    switch (type) {
      case ProjectileType.crack:
        // 수명의 절반이 지나면 분열
        if (_age >= lifeSpan / 2 && !_isSplitting) {
          _split();
        }
        break;
      case ProjectileType.mine:
        // 기폭탄은 수명이 다하면 폭발
        if (_age >= lifeSpan) {
          _explode();
          removeFromParent();
          return;
        }
        break;
      default:
        if (_age >= lifeSpan) {
          removeFromParent();
          return;
        }
    }

    position += direction * speed * dt;
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    if (other is EnemyBaseComponent) {
      other.takeDamage(damage); // 수정: 고정 데미지 1 대신 damage 변수 사용
      if (type != ProjectileType.laser) {
        // 레이저가 아니면 충돌 시 사라짐
        removeFromParent();
      }
    }
  }

  // 크랙샷 분열 로직
  void _split() {
    _isSplitting = true;
    for (int i = 0; i < 4; i++) {
      final angle = i * (pi / 2); // 90도 간격
      final newDirection = Vector2(cos(angle), sin(angle));
      game.add(ProjectileComponent(
        position.clone(),
        newDirection,
        lifeSpan: lifeSpan / 2, // 남은 수명
      ));
    }
    removeFromParent(); // 원본은 제거
  }

  // 기폭탄 폭발 로직
  void _explode() {
    // TODO: 폭발 효과 (예: 주변 적에게 데미지) 구현 필요
    print("Boom!");
  }
}