import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_client/main.dart';
import 'package:flutter_client/weapon.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// 서버에서 받아온 무기 정보를 담을 모델 클래스
class WeaponInfo {
  final String code;
  final String name;
  final String description;
  final int unlockScore;

  WeaponInfo({
    required this.code,
    required this.name,
    required this.description,
    required this.unlockScore,
  });

  factory WeaponInfo.fromJson(Map<String, dynamic> json) {
    return WeaponInfo(
      code: json['code'],
      name: json['name'],
      description: json['description'],
      unlockScore: json['unlock_score'],
    );
  }
}

class WeaponSelectionScreen extends StatefulWidget {
  const WeaponSelectionScreen({super.key});

  @override
  _WeaponSelectionScreenState createState() => _WeaponSelectionScreenState();
}

class _WeaponSelectionScreenState extends State<WeaponSelectionScreen> {
  late Future<Map<String, dynamic>> _gameDataFuture;
  WeaponInfo? _selectedWeaponInfo;

  @override
  void initState() {
    super.initState();
    _gameDataFuture = _loadGameData();
  }

  // 서버에서 무기 목록을 가져오고, 로컬에서 최고 점수를 불러오는 비동기 함수
  Future<Map<String, dynamic>> _loadGameData() async {
    try {
      // 1. Fetch weapons from the server
      final response = await http.get(Uri.parse('http://192.168.45.183:8001/weapons'));
      if (response.statusCode != 200) {
        throw Exception('Failed to load weapons from server');
      }
      final List<dynamic> weaponsJson = json.decode(utf8.decode(response.bodyBytes));
      final List<WeaponInfo> weapons = weaponsJson.map((json) => WeaponInfo.fromJson(json)).toList();

      // 2. Load high score from local storage
      final prefs = await SharedPreferences.getInstance();
      final highScore = prefs.getInt('highScore') ?? 0;
      
      // 3. Set default selected weapon if null
      if (_selectedWeaponInfo == null) {
          final firstUnlockedWeapon = weapons.firstWhere((w) => highScore >= w.unlockScore, orElse: () => weapons.first);
          _selectedWeaponInfo = firstUnlockedWeapon;
      }

      return {'weapons': weapons, 'highScore': highScore};
    } catch (e) {
      // 에러 발생 시 재시도 버튼을 보여주기 위해 에러를 전파
      print('Error loading game data: $e');
      rethrow;
    }
  }

  // WeaponInfo.code를 기반으로 실제 Weapon 객체를 생성하는 헬퍼 함수
  Weapon _createWeaponFromInfo(WeaponInfo info) {
    switch (info.code) {
      case 'W001':
        return Rifle();
      case 'W002':
        return ChargeShot();
      case 'W003':
        return CrackShot();
      case 'W004':
        return Laser();
      case 'W005':
        return ProximityMine();
      default:
        return Rifle(); // 기본값
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: Center(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _gameDataFuture,
          builder: (context, snapshot) {
            // 로딩 중일 때
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }

            // 에러가 발생했을 때
            if (snapshot.hasError) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _gameDataFuture = _loadGameData();
                      });
                    },
                    child: const Text('Retry'),
                  )
                ],
              );
            }

            // 데이터 로딩 성공
            if (snapshot.hasData) {
              final List<WeaponInfo> weapons = snapshot.data!['weapons'];
              final int highScore = snapshot.data!['highScore'];

              return Column(
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
                  Text(
                    'High Score: $highScore',
                    style: TextStyle(color: Colors.amber, fontSize: 16),
                  ),
                  const SizedBox(height: 40),
                  
                  // 무기 선택 버튼들
                  ...weapons.map((weaponInfo) {
                    final bool isUnlocked = highScore >= weaponInfo.unlockScore;
                    final bool isSelected = weaponInfo.code == _selectedWeaponInfo?.code;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: isSelected && isUnlocked ? Colors.teal : Colors.transparent,
                          side: BorderSide(color: isUnlocked ? Colors.white : Colors.grey),
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                        ),
                        onPressed: isUnlocked ? () {
                          setState(() {
                            _selectedWeaponInfo = weaponInfo;
                          });
                        } : null, // 잠겼으면 버튼 비활성화
                        child: Column(
                          children: [
                             Text(weaponInfo.name.toUpperCase()),
                             if (!isUnlocked)
                               Padding(
                                 padding: const EdgeInsets.only(top: 4.0),
                                 child: Text(
                                   '(Unlock at ${weaponInfo.unlockScore})',
                                   style: const TextStyle(fontSize: 10, color: Colors.grey),
                                 ),
                               ),
                          ],
                        ),
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
                    onPressed: _selectedWeaponInfo == null ? null : () {
                      final selectedWeapon = _createWeaponFromInfo(_selectedWeaponInfo!);
                      Navigator.pushReplacement(
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
              );
            }
            // 데이터가 없는 경우 (이론상 발생하기 어려움)
            return const Text('No weapon data found.', style: TextStyle(color: Colors.white));
          },
        ),
      ),
    );
  }
}