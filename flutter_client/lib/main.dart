import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flame/input.dart';
import 'package:flutter_client/enemyManager.dart';
import 'package:flutter_client/item_manager.dart';
import 'package:flutter_client/weapon.dart';
import 'package:flutter_client/weapon_selection_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'player.dart';

import 'projectile.dart';
import 'package:flutter_client/score_screen.dart';

// ==================== MyGame ====================
class MyGame extends FlameGame with HasCollisionDetection {
  static bool isMovingUp = false;
  static bool isMovingDown = false;
  static bool isMovingLeft = false;
  static bool isMovingRight = false;
  static int score = 0;

  final Weapon initialWeapon; // 시작 시 선택된 무기

  Vector2 lastDirection = Vector2(0, -1);
  late PlayerComponent player;
  late EnemyManager enemyManager;
  late ItemManager itemManager;
  late TextComponent _scoreText;

  // ValueNotifiers for player stats
  final ValueNotifier<double> speedNotifier = ValueNotifier(0);
  final ValueNotifier<double> healthNotifier = ValueNotifier(0);
  final ValueNotifier<double> shieldNotifier = ValueNotifier(0);

  MyGame({required this.initialWeapon}); // 생성자 수정

  @override
  Future<void> onLoad() async {
    super.onLoad();
    player = PlayerComponent(initialWeapon: initialWeapon); // 플레이어에게 무기 전달
    add(player);

    enemyManager = EnemyManager();
    add(enemyManager);

    itemManager = ItemManager();
    add(itemManager);

    _scoreText = TextComponent(
      text: 'Score: ${MyGame.score}',
      position: Vector2(size.x - 10, 10),
      anchor: Anchor.topRight,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
      ),
    );
    add(_scoreText);

    // Initialize notifiers
    healthNotifier.value = player.currentHealth / player.maxHealth;
    shieldNotifier.value = player.currentShield / player.maxShield;
  }

  @override
  void update(double dt) {
    super.update(dt);
    // 점수 업데이튼
    _scoreText.text = 'Score: $score';

    // 플레이어 상태 업데이트
    speedNotifier.value = player.velocity.length / player.maxSpeed;
    healthNotifier.value = player.currentHealth / player.maxHealth;
    shieldNotifier.value = player.currentShield / player.maxShield;
  }

  void onPlayerDeath() async {  //플레이어 죽었을 때
    final prefs = await SharedPreferences.getInstance();
    final highScore = prefs.getInt('highScore') ?? 0;

    if (score > highScore) {
      await prefs.setInt('highScore', score);
      print('New high score: $score');
    }

    // Send score and collected items to the server
    final collectedItemsString = player.collectedItemCodes.join(',');
    final currentWeaponCode = player.currentWeapon.code; // Assuming Weapon has a 'code' property

    try {
      final response = await http.post(
        Uri.parse('http://192.168.45.81:8000/scores?user_id=1'), // TODO: Replace with actual user_id
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'score': score,
          'weapon': currentWeaponCode,
          'items': collectedItemsString,
        }),
      );

      if (response.statusCode == 200) {
        print('Score and items submitted successfully!');
      } else {
        print('Failed to submit score and items: ${response.statusCode}');
      }
    } catch (e) {
      print('Error submitting score and items: $e');
    }

    // Reset score for the next game
    score = 0;
    player.collectedItemCodes.clear(); // Clear collected items for the next game

    // Navigate back to the weapon selection screen
    if (buildContext != null) {
      Navigator.of(buildContext!).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ScoreScreen(
            score: score,
            highScore: highScore,
            weaponName: player.currentWeapon.name,
            collectedItems: collectedItemsString,
          ),
        ),
      );
    }
  }
}

// ==================== 무기 선택 스크린 ====================
class GaugeWidget extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const GaugeWidget({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        const SizedBox(height: 4),
        Container(
          width: 80,
          height: 10,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 1),
            borderRadius: BorderRadius.circular(2),
          ),
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: Colors.grey[800],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}


// ==================== GameBoyUI ====================
// 원래는 GameBoyUI로 만들었지만 메카물 형식의 디자인 UI로 바뀜
class GameBoyUI extends StatelessWidget {
  final MyGame game;
  const GameBoyUI({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Column(
          children: [
            Expanded(
              flex: 3,
              child: Container(
                color: Colors.green[900],
                child: GameWidget(game: game),
              ),
            ),
            Expanded(
              flex: 2,
              child: Container(
                color: Colors.grey[800],
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top Row: Gauges
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Speed Gauge
                        ValueListenableBuilder<double>(
                          valueListenable: game.speedNotifier,
                          builder: (context, value, child) {
                            return GaugeWidget(label: "SPEED", value: value, color: Colors.cyan);
                          },
                        ),
                        // Health and Shield Gauges
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            ValueListenableBuilder<double>(
                              valueListenable: game.healthNotifier,
                              builder: (context, value, child) {
                                return GaugeWidget(label: "HEALTH", value: value, color: Colors.green);
                              },
                            ),
                            const SizedBox(height: 10),
                            ValueListenableBuilder<double>(
                              valueListenable: game.shieldNotifier,
                              builder: (context, value, child) {
                                return GaugeWidget(label: "SHIELD", value: value, color: Colors.blue);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Bottom Row: Controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // D-Pad
                        Column(
                          children: [
                            GestureDetector(
                              onTapDown: (_) => MyGame.isMovingUp = true,
                              onTapUp: (_) => MyGame.isMovingUp = false,
                              onTapCancel: () => MyGame.isMovingUp = false,
                              child: const Icon(Icons.arrow_drop_up, size: 48, color: Colors.white),
                            ),
                            Row(
                              children: [
                                GestureDetector(
                                  onTapDown: (_) => MyGame.isMovingLeft = true,
                                  onTapUp: (_) => MyGame.isMovingLeft = false,
                                  onTapCancel: () => MyGame.isMovingLeft = false,
                                  child: const Icon(Icons.arrow_left, size: 48, color: Colors.white),
                                ),
                                const SizedBox(width: 48),
                                GestureDetector(
                                  onTapDown: (_) => MyGame.isMovingRight = true,
                                  onTapUp: (_) => MyGame.isMovingRight = false,
                                  onTapCancel: () => MyGame.isMovingRight = false,
                                  child: const Icon(Icons.arrow_right, size: 48, color: Colors.white),
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTapDown: (_) => MyGame.isMovingDown = true,
                              onTapUp: (_) => MyGame.isMovingDown = false,
                              onTapCancel: () => MyGame.isMovingDown = false,
                              child: const Icon(Icons.arrow_drop_down, size: 48, color: Colors.white),
                            ),
                          ],
                        ),
                        // A/B Buttons
                        Column(
                          children: [
                             GestureDetector(
                               onTapDown: (_) => game.player.startCharge(),
                               onTapUp: (_) => game.player.releaseCharge(),
                               onTapCancel: () => game.player.releaseCharge(),
                               child: Container(
                                 width: 60, // 버튼 크기
                                 height: 60,
                                 decoration: BoxDecoration(
                                   color: Colors.redAccent,
                                   shape: BoxShape.circle,
                                 ),
                                 child: Center(
                                   child: Text('A', style: TextStyle(fontSize: 24, color: Colors.white)),
                                 ),
                               ),
                             ),
                              const SizedBox(height: 20),
                              GestureDetector(
                                onTapDown: (_) => game.player.dodge(),
                                onTapUp: (_) => MyGame.score += 500,
                                child: const Text('B'), //Container로 좀 더 확장
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ==================== main ====================
void main() {
  runApp(
    const MaterialApp(
      home: WeaponSelectionScreen(),
    ),
  );
}