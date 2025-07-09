import 'package:flutter/material.dart';
import 'package:flutter_client/weapon_selection_screen.dart';

class ScoreScreen extends StatelessWidget {
  final int score;
  final int highScore;
  final String weaponName;
  final String collectedItems;

  const ScoreScreen({
    super.key,
    required this.score,
    required this.highScore,
    required this.weaponName,
    required this.collectedItems,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'GAME OVER',
                style: TextStyle(fontSize: 48, color: Colors.redAccent, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              Text(
                'Score: $score',
                style: const TextStyle(fontSize: 28, color: Colors.white),
              ),
              const SizedBox(height: 10),
              Text(
                'High Score: $highScore',
                style: const TextStyle(fontSize: 28, color: Colors.yellowAccent),
              ),
              const SizedBox(height: 20),
              Text(
                'Weapon Used: $weaponName',
                style: const TextStyle(fontSize: 24, color: Colors.lightBlueAccent),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  'Items Collected: ${collectedItems.isEmpty ? "None" : collectedItems}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, color: Colors.greenAccent),
                ),
              ),
              const SizedBox(height: 50),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const WeaponSelectionScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                child: const Text('PLAY AGAIN'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
