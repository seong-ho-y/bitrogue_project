import 'dart:convert';

//import 'package:http/http.dart' as http;
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:flame/input.dart';
import 'package:flame/extensions.dart';
import 'package:flutter_client/enemyManager.dart';
import 'package:flutter_client/item_manager.dart';
import 'player.dart';
import 'projectile.dart';
import 'enemyManager.dart';


// ==================== MyGame ====================
class MyGame extends FlameGame with HasCollisionDetection {
  static bool isMovingUp = false;
  static bool isMovingDown = false;
  static bool isMovingLeft = false;
  static bool isMovingRight = false;
  static int score = 0;


  static int playerSpeed = 100;

  Vector2 lastDirection = Vector2(0, -1); // 기본 위쪽
  late PlayerComponent player;
  late EnemyManager enemyManager;
  late ItemManager itemManager;
  late TextComponent _scoreText;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    player = PlayerComponent();
    add(player);

    //EnemyManager 생성 및 추가
    enemyManager = EnemyManager();
    add(enemyManager);

    //ItemManager 생성 및 추가
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
  }

  @override
  void update(double dt) {
    super.update(dt);
    _scoreText.text = 'Score: ${MyGame.score}';
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
            // 상단 스크린 영역
            Expanded(
              flex: 3,
              child: Container(
                color: Colors.green[900],
                child: GameWidget(game: game),
              ),
            ),
            // 하단 UI 영역
            Expanded(
              flex: 2,
              child: Container(
                color: Colors.grey[800],
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // D패드 + A/B 버튼 영역
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // D패드
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTapDown: (_) {
                                MyGame.isMovingUp = true;
                              },
                              onTapUp: (_) {
                                MyGame.isMovingUp = false;
                              },
                              onTapCancel: () {
                                MyGame.isMovingUp = false;
                              },
                              child: const Icon(Icons.arrow_drop_up, size: 48, color: Colors.white),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                GestureDetector(
                                  onTapDown: (_) {
                                    MyGame.isMovingLeft = true;
                                  },
                                  onTapUp: (_) {
                                    MyGame.isMovingLeft = false;
                                  },
                                  onTapCancel: () {
                                    MyGame.isMovingLeft = false;
                                  },
                                  child: const Icon(Icons.arrow_left, size: 48, color: Colors.white),
                                ),
                                const SizedBox(width: 48),
                                GestureDetector(
                                  onTapDown: (_) {
                                    MyGame.isMovingRight = true;
                                  },
                                  onTapUp: (_) {
                                    MyGame.isMovingRight = false;
                                  },
                                  onTapCancel: () {
                                    MyGame.isMovingRight = false;
                                  },
                                  child: const Icon(Icons.arrow_right, size: 48, color: Colors.white),
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTapDown: (_) {
                                MyGame.isMovingDown = true;
                              },
                              onTapUp: (_) {
                                MyGame.isMovingDown = false;
                              },
                              onTapCancel: () {
                                MyGame.isMovingDown = false;
                              },
                              child: const Icon(Icons.arrow_drop_down, size: 48, color: Colors.white),
                            ),
                          ],
                        ),

                        // A/B 버튼
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Transform.translate(
                              offset: const Offset(20, 0),
                              child: ElevatedButton(
                                onPressed: () {
                                  game.add(ProjectileComponent(
                                    game.player.position.clone(),
                                    game.lastDirection.clone(),
                                  ));
                                },
                                child: const Text('A'),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Transform.translate(
                              offset: const Offset(-20, 0),
                              child: ElevatedButton(
                                onPressed: () {
                                  game.player.dodge();
                                },
                                child: const Text('B'),
                              ),
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

//=========================   MyApp    ==============================

class MyApp extends StatefulWidget{ //나중에 서버 연동해서 불러올 때 쓸 코드
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String leaderboardText = "Loading...";

  @override
  void initState() {
    super.initState();
    //getLeaderboard();
  }
  
  // Future<void> getLeaderboard() async {
  //   final url = Uri.parse('http://[YOUR_PC_IP]:8000/leaderboard');
  //   final response = await http.get(url);

  //   if (response.statusCode == 200) {
  //     final data = jsonDecode(response.body);
  //     setState(() {
  //       leaderboardText = data.toString();
  //     });
  //   } else {
  //     setState(() {
  //       leaderboardText = 'Failed to load: ${response.statusCode}';
  //     });
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('BitRogue Leaderboard')),
        body: Center(child: Text(leaderboardText)),
      ),
    );
  }
}

// ==================== main ====================
final myGame = MyGame();

void main() {
  runApp(GameBoyUI(game: myGame));
}
