import 'dart:convert';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flame/input.dart';
import 'package:flutter_client/enemyManager.dart';
import 'package:flutter_client/item_manager.dart';
import 'player.dart';
import 'projectile.dart';

// ==================== MyGame ====================
class MyGame extends FlameGame with HasCollisionDetection {
  static bool isMovingUp = false;
  static bool isMovingDown = false;
  static bool isMovingLeft = false;
  static bool isMovingRight = false;
  static int score = 0;

  Vector2 lastDirection = Vector2(0, -1);
  late PlayerComponent player;
  late EnemyManager enemyManager;
  late ItemManager itemManager;
  late TextComponent _scoreText;

  // ValueNotifiers for player stats
  final ValueNotifier<double> speedNotifier = ValueNotifier(0);
  final ValueNotifier<double> healthNotifier = ValueNotifier(0);
  final ValueNotifier<double> shieldNotifier = ValueNotifier(0);

  @override
  Future<void> onLoad() async {
    super.onLoad();
    player = PlayerComponent();
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
    _scoreText.text = 'Score: ${MyGame.score}';

    // Update notifiers
    speedNotifier.value = player.velocity.length / player.maxSpeed;
    healthNotifier.value = player.currentHealth / player.maxHealth;
    shieldNotifier.value = player.currentShield / player.maxShield;
  }
}

// ==================== GaugeWidget ====================
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left Side: D-Pad and Speed Gauge
                    Column(
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
                        // Speed Gauge
                        ValueListenableBuilder<double>(
                          valueListenable: game.speedNotifier,
                          builder: (context, value, child) {
                            return GaugeWidget(label: "SPEED", value: value, color: Colors.cyan);
                          },
                        ),
                      ],
                    ),
                    // Right Side: A/B Buttons and Gauges
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // A/B Buttons
                        Column(
                          children: [
                             ElevatedButton(
                                onPressed: () {
                                  game.add(ProjectileComponent(
                                    game.player.position.clone(),
                                    game.lastDirection.clone(),
                                  ));
                                },
                                child: const Text('A'),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: () => game.player.dodge(),
                                child: const Text('B'),
                              ),
                          ],
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
final myGame = MyGame();

void main() {
  runApp(GameBoyUI(game: myGame));
}
