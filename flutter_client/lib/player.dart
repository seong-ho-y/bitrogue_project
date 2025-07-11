import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flame/collisions.dart';
import 'package:flutter_client/enemy.dart';
import 'package:flame/effects.dart';
import 'package:vibration/vibration.dart';


import 'package:flutter_client/item.dart';
import 'package:flutter_client/weapon.dart';
import 'main.dart';


// ==================== PlayerComponent ====================
class PlayerComponent extends RectangleComponent with HasGameReference<MyGame>, CollisionCallbacks {
  late Weapon currentWeapon;

  PlayerComponent({required Weapon initialWeapon})
      : super(
          position: Vector2(100, 30),
          size: Vector2(16, 16),
          paint: Paint()..color = const Color(0xFF33CC33),
        ) {
    currentWeapon = initialWeapon;
  }
    double maxHealth = 5;
    double currentHealth = 5;
    double maxShield = 3; // 최대 쉴드
    double currentShield = 3; // 현재 쉴드

    // 획득한 아이템 코드 목록
    List<String> collectedItemCodes = [];

    // 무기 관련 변수
    double _timeSinceLastAttack = 0.0;
    double _chargeStartTime = 0.0; // 차지 시작 시간

    // 이동 관련 변수 (관성 적용)
    Vector2 velocity = Vector2.zero();
    double maxSpeed = 150.0;
    double acceleration = 300.0;
    double friction = 2.5; // 초당 감속 비율


  //피격 관련 변수들
  bool isInvincible = false; //무적인지 아닌지
  double invincibleDuration = 1.0;
  double invincibleTimer = 0.0;
  double blinkTimer = 0.0;
  double blinkInterval = 0.1;
  bool isVisible = true;

  //닷지 관련 변수들
  bool isDodging = false;
  final double dodgeSpeed = 300.0;
  final double dodgeDuration = 0.2;
  final double dodgeCooldown = 1.0;
  double dodgeCooldownTimer = 0.0;

  @override
  void onLoad(){
    super.onLoad();
    add(RectangleHitbox()); //Hitbox 추가
  }


  @override
  void update(double dt) {
    super.update(dt);
    _timeSinceLastAttack += dt;

    // Update weapon reload state
    currentWeapon.updateReload(dt);

    // Handle player blinking during reload
    if (currentWeapon.isReloading) {
      blinkTimer -= dt;
      if (blinkTimer <= 0) {
        blinkTimer = blinkInterval;
        isVisible = !isVisible;
        paint.color = isVisible ? const Color(0xFF33CC33) : const Color(0x88FFFFFF); // Blink effect
      }
    } else if (!isVisible) { // Ensure player is visible when not reloading
      isVisible = true;
      paint.color = const Color(0xFF33CC33);
    }

    if (dodgeCooldownTimer > 0) {
      dodgeCooldownTimer -= dt;
    }

    if (isInvincible){
      invincibleTimer -= dt;
      blinkTimer -= dt;

      if(blinkTimer <= 0){
        blinkTimer = blinkInterval;
        isVisible = !isVisible;
        paint.color = isVisible ? const Color(0xFF33CC33) : const Color(0x88FFFFFF);
      }
      if(invincibleTimer <= 0){
        isInvincible = false;
        paint.color = const Color(0xFF33CC33);
      }
    }

//====================== 이동로직 (관성 적용) ==========================
    if (!isDodging) {
      final direction = Vector2.zero();
      if (MyGame.isMovingUp) direction.y -= 1;
      if (MyGame.isMovingDown) direction.y += 1;
      if (MyGame.isMovingLeft) direction.x -= 1;
      if (MyGame.isMovingRight) direction.x += 1;

      if (!direction.isZero()) {
        // 키 입력이 있을 때: 가속
        velocity += direction.normalized() * acceleration * dt;
        if (velocity.length > maxSpeed) {
          velocity = velocity.normalized() * maxSpeed;
        }
        game.lastDirection = direction.normalized();
      } else {
        // 키 입력이 없을 때: 감속 (마찰)
        velocity *= (1 - friction * dt);
        if (velocity.length < 1.0) {
          velocity = Vector2.zero();
        }
      }
      position += velocity * dt;

      // 화면 경계 처리
      if (position.x > game.size.x - size.x){
        position.x = 0;
      }
      if (position.x < 0){
        position.x = game.size.x - size.x;
      }
      if (position.y > game.size.y - size.y){
        position.y = 0;
      }
      if (position.y < 0){
        position.y = game.size.y - size. y;
      }
    }
  }

  /// 무기 발사
  void fire({double chargeTime = 0.0}) {
    if (currentWeapon.isReloading) return; // Cannot fire while reloading
    if (currentWeapon.currentAmmo <= 0) {
      currentWeapon.startReload();
      return;
    }

    if (game.currentTime() - _timeSinceLastAttack >= currentWeapon.coolDown) {
      currentWeapon.attack(game, position.clone(), game.lastDirection.clone(), chargeTime: chargeTime);
      _timeSinceLastAttack = 0.0;
    }
  }

  /// 차지 시작
  void startCharge() {
    if (currentWeapon.isReloading) return; // Cannot charge while reloading
    _chargeStartTime = game.currentTime();
  }

  /// 차지 해제 및 발사
  void releaseCharge() {
    if (currentWeapon.isReloading) return; // Cannot release charge while reloading
    final chargeTime = game.currentTime() - _chargeStartTime;
    fire(chargeTime: chargeTime);
  }

  /// 무기 교체
  void equipWeapon(Weapon newWeapon) {
    currentWeapon = newWeapon;
    game.currentWeaponNotifier.value = newWeapon; // Update the notifier
    print('Equipped ${currentWeapon.name}');
  }

      /// 피해 처리 함수
  void takeDamage(double damage, [Vector2? fromPosition]) {
    if (isInvincible) return;

    if (currentShield > 0) {
      currentShield -= damage;
      print('쉴드 피격! 현재 쉴드: $currentShield');
    } else {
      currentHealth -= damage;
      print('플레이어 피격! 현재 체력: $currentHealth');
    }

    if (currentHealth <= 0) {
      die();
    }

    isInvincible = true;
    invincibleTimer = invincibleDuration;

    // 피격시 적에게서 튕겨나가기
    if (fromPosition != null) {
      final knockbackDirection = (position - fromPosition).normalized();
      final knockbackDistance = 20.0;
      final knockbackTarget = position + knockbackDirection * knockbackDistance;

      add(MoveEffect.to(
        knockbackTarget,
        EffectController(duration: 0.1, curve: Curves.easeOut),
        ));
    }

    //휴대폰 진동
    vibrateOnHit();
  }
  void dodge() {
    if (dodgeCooldownTimer > 0 || isDodging) {
      return;
    }
    print("플레이어 닷지");

    isDodging = true;
    isInvincible = true;
    invincibleTimer = dodgeDuration; // 닷지 시간 동안 무적
    dodgeCooldownTimer = dodgeCooldown;

    // 마지막으로 움직인 방향으로 닷지. 방향이 없으면 위로.
    final dodgeDirection = game.lastDirection.isZero() ? Vector2(0, -1) : game.lastDirection;
    final dodgeDistance = dodgeSpeed * dodgeDuration;
    final dodgeTarget = position + dodgeDirection.normalized() * dodgeDistance;

    add(MoveEffect.to(
      dodgeTarget,
      EffectController(duration: dodgeDuration, curve: Curves.easeOut),
      onComplete: () {
        isDodging = false;
        // 닷지 후 무적은 dodgeDuration만큼만 유지되므로 isInvincible을 여기서 false로 바꿀 필요 없음.
      },
    ));
  }

  /// 사망 처리
  void die() {
    print('플레이어 사망');
    game.onPlayerDeath(); // 게임 오버 로직을 MyGame 클래스에 위임
    removeFromParent(); // 플레이어 객체 제거
  }
  
  void vibrateOnHit() async {
  if (await Vibration.hasVibrator() ?? false) {
    Vibration.vibrate(duration: 100); // 100ms 진동
  }
}
  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other){
    super.onCollision(intersectionPoints, other);
    if (other is EnemyBaseComponent){
        takeDamage(1, other.position);
    } else if (other is ItemComponent) {
      // 아이템과 충돌했을 때
      _applyItemEffect(other.itemData);
      other.removeFromParent(); // 아이템 제거
    }
  }

  // 아이템 효과를 적용하는 함수
  void _applyItemEffect(Item item) {
    print('Picked up item: ${item.name} (${item.description})');
    collectedItemCodes.add(item.name); // 획득한 아이템 이름 추가

    // 아이템 효과 문자열을 ':' 기준으로 분리 (예: "health:1")
    final parts = item.effect.split(':');
    if (parts.length != 2) return; // 형식이 잘못되었으면 무시

    final type = parts[0];
    final value = int.tryParse(parts[1]);
    if (value == null) return; // 값이 숫자가 아니면 무시

    switch (type) {
      case 'health':
        currentHealth = (currentHealth + value).clamp(0, maxHealth);
        print('Health +$value! Current health: $currentHealth');
        break;
      case 'shield':
        currentShield = (currentShield + value).clamp(0, maxShield);
        print('Shield +$value! Current shield: $currentShield');
        break;
      case 'speed':
        maxSpeed += value;
        print('MaxSpeed +$value! Current maxSpeed: $maxSpeed');
        break;
      case 'damage':
        // TODO: 발사체 데미지 증가 로직 추가
        print('Damage +$value! (Not implemented yet)');
        break;
      default:
        print('Unknown item effect type: $type');
    }
  }
}