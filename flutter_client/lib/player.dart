import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flame/collisions.dart';
import 'package:flutter_client/enemy.dart';
import 'package:flame/effects.dart';
import 'package:vibration/vibration.dart';


import 'main.dart';


// ==================== PlayerComponent ====================
class PlayerComponent extends RectangleComponent with HasGameReference<MyGame>, CollisionCallbacks {
  PlayerComponent()
      : super(
          position: Vector2(100, 30),
          size: Vector2(16, 16),
          paint: Paint()..color = const Color(0xFF33CC33),
        );
    double maxHealth = 5;
    double currentHealth = 5;

  //피격 관련 변수들  
  bool isInvincible = false; //무적인지 아닌지 
  double invincibleDuration = 1.0;
  double invincibleTimer = 0.0;
  double blinkTimer = 0.0;
  double blinkInterval = 0.1;
  bool isVisible = true;

  //닷지 관련 변수들
  bool isDodge = false;
  double dodgeMoving = 1.0; //닷지 시 회피거리
  double dodgeCool = 1.0; //닷지 쿨타임
  double dodgeTiemr = 0.0;
  double dodgeTime = 0.7; //닷지 시간
  //닷지 프레임 회피
  bool isPerfectDodge = false;
  double pDodgeTime = 0.3; //퍼펙트 닷지 시간
  



  @override
  void onLoad(){
    super.onLoad();

    add(RectangleHitbox()); //Hitbox 추가
  }


  @override
  void update(double dt) {
    super.update(dt);

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

//====================== 이동로직 ==========================
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
  void takeDamage(double damage, [Vector2? fromPosition]) {
    if (isInvincible) return;

    currentHealth -= damage;
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
    print('플레이어 피격! 현재 체력: $currentHealth');
  }
  void dodge(){

    print("플레이어 닷지");

  }
  /// 사망 처리
  void die() {
    print('플레이어 사망');
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
    }
  }
}