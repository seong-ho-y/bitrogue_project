import 'package:flame/components.dart';
import 'enemy.dart';
import 'dart:math';

class EnemyManager extends Component with HasGameReference {
  late Timer spawnTimer;
  static double spawnCool = 5;
  Random random = Random();

  EnemyManager() {
    spawnTimer = Timer(spawnCool, repeat: true, onTick: spawnEnemy);
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    spawnTimer.start();
  }

  @override
  void update(double dt) {
    super.update(dt);
    spawnTimer.update(dt);
  }

  void spawnEnemy() {
    final x = random.nextDouble() * game.size.x;
    final y = random.nextDouble() * game.size.y / 2; // 위쪽 절반에 스폰

    final type = random.nextInt(4);
    EnemyBaseComponent enemy;

    switch (type) {
      case 0:
        enemy = EnemyBaseComponent(
          maxHealth: 5,
          moveSpeed: 70,
          position: Vector2(x, y),
          size: Vector2(16, 16),
        );
        break;
      case 1:
        enemy = RunnerEnemy(position: Vector2(x, y));
        break;
      case 2:
        enemy = RangerEnemy(position: Vector2(x, y));
        break;
      case 3:
        enemy = SummonerEnemy(position: Vector2(x, y));
        break;
      default:
        enemy = EnemyBaseComponent(
          maxHealth: 5,
          moveSpeed: 70,
          position: Vector2(x, y),
          size: Vector2(16, 16),
        );
        break;
    }

    game.add(enemy);
  }
}
