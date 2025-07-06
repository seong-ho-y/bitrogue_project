
import 'package:flutter/material.dart';
import 'package:flutter_client/main.dart';
import 'package:flutter_client/weapon.dart';

class WeaponSelectionScreen extends StatefulWidget {
  const WeaponSelectionScreen({super.key});

  @override
  _WeaponSelectionScreenState createState() => _WeaponSelectionScreenState();
}

class _WeaponSelectionScreenState extends State<WeaponSelectionScreen> {
  // 사용 가능한 무기 목록
  final List<Weapon> availableWeapons = [Rifle(), Shotgun()];
  // 현재 선택된 무기
  late Weapon selectedWeapon;

  @override
  void initState() {
    super.initState();
    // 기본으로 첫 번째 무기를 선택
    selectedWeapon = availableWeapons[0];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'CHOOSE YOUR WEAPON',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 40),
            // 무기 선택 버튼들
            ...availableWeapons.map((weapon) {
              final isSelected = weapon.name.toLowerCase() == selectedWeapon.name.toLowerCase();

              //디버그 용
               print('Comparing: "${weapon.name}" (${weapon.name.toLowerCase()}) with "${selectedWeapon.name}"(${selectedWeapon.name.toLowerCase()})');
                print('Is selected: $isSelected');

              //
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: isSelected ? Colors.teal : Colors.transparent,
                    side: const BorderSide(color: Colors.white),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  ),
                  onPressed: () {
                    setState(() {
                      selectedWeapon = weapon;
                    });
                  },
                  child: Text(weapon.name.toUpperCase()),
                ),
              );
            }).toList(),
            const SizedBox(height: 60),
            // 게임 시작 버튼
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              ),
              onPressed: () {
                // 선택한 무기와 함께 게임 화면으로 이동
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GameBoyUI(
                      game: MyGame(initialWeapon: selectedWeapon),
                    ),
                  ),
                );
              },
              child: const Text(
                'START GAME',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
