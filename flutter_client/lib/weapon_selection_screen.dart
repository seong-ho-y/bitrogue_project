import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_client/main.dart';
import 'package:flutter_client/weapon.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_client/leaderboard_screen.dart';
import 'package:flutter_client/item_dictionary_screen.dart'; // New import
import 'package:flutter_client/constants.dart';

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
  int _userHighScore = 0; // State variable for user's high score
  late PageController _pageController; // For weapon sliding
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.8); // Show part of next/prev weapon
    _gameDataFuture = _loadGameData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<int> _fetchUserHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    final int? userId = prefs.getInt('userId');

    if (userId == null) {
      print('Error: User ID not found for fetching high score.');
      return 0;
    }

    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/users/$userId/high_score'),
      );

      if (response.statusCode == 200) {
        return int.parse(response.body);
      } else {
        print('Failed to fetch user high score: ${response.statusCode}');
        return 0;
      }
    } catch (e) {
      print('Error fetching user high score: $e');
      return 0;
    }
  }

  // 서버에서 무기 목록을 가져오고, 로컬에서 최고 점수를 불러오는 비동기 함수
  Future<Map<String, dynamic>> _loadGameData() async {
    try {
      // 1. 무기 가져오기
      final response = await http.get(Uri.parse('${AppConstants.codexBaseUrl}/weapons'));
      if (response.statusCode != 200) {
        throw Exception('Failed to load weapons from server');
      }
      final List<dynamic> weaponsJson = json.decode(utf8.decode(response.bodyBytes));
      final List<WeaponInfo> weapons = weaponsJson.map((json) => WeaponInfo.fromJson(json)).toList();

      // 2. HighScore 가져오기
      _userHighScore = await _fetchUserHighScore();
      
      // 3. 선택된 무기 없을 때
      if (_selectedWeaponInfo == null) {
          final firstUnlockedWeapon = weapons.firstWhere((w) => _userHighScore >= w.unlockScore, orElse: () => weapons.first);
          _selectedWeaponInfo = firstUnlockedWeapon;
      }

      return {'weapons': weapons, 'highScore': _userHighScore};
    } catch (e) {
      // 에러 발생 시 재시도 버튼을 보여주기 위해 에러를 전파
      print('Error loading game data: $e');
      rethrow;
    }
  }

  // WeaponInfo.code를 기반으로 실제 Weapon 객체를 생성
  Weapon _createWeaponFromInfo(WeaponInfo info) {
    switch (info.code) {
      case 'W001':
        return Rifle();
      case 'W006':
        return Shotgun();
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
      body: FutureBuilder<Map<String, dynamic>>(
        future: _gameDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
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
              ),
            );
          } else if (snapshot.hasData) {
            final List<WeaponInfo> weapons = snapshot.data!['weapons'];

            return Stack(
              children: [
                Positioned.fill(
                  child: Image.network(
                    'https://via.placeholder.com/800x600.png?text=Hangar+Background',
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.6),
                  ),
                ),
                // Main Content
                Column(
                  children: [
                    //타이틀, 하이스코어
                    Padding(
                      padding: const EdgeInsets.only(top: 60.0, bottom: 20.0),
                      child: Column(
                        children: [
                          const Text(
                            'ARMORY',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 4,
                              shadows: [
                                Shadow(blurRadius: 10.0, color: Colors.black, offset: Offset(3.0, 3.0)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'High Score: $_userHighScore',
                            style: TextStyle(color: Colors.amberAccent, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    // 무기 교체 슬라이더
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: weapons.length,
                        onPageChanged: (index) {
                          setState(() {
                            _currentPage = index;
                            _selectedWeaponInfo = weapons[index];
                          });
                        },
                        itemBuilder: (context, index) {
                          final weaponInfo = weapons[index];
                          final bool isUnlocked = _userHighScore >= weaponInfo.unlockScore;
                          final bool isSelected = weaponInfo.code == _selectedWeaponInfo?.code;

                          return AnimatedBuilder(
                            animation: _pageController,
                            builder: (context, child) {
                              double value = 1.0;
                              if (_pageController.position.haveDimensions) {
                                value = _pageController.page! - index;
                                value = (1 - (value.abs() * 0.3)).clamp(0.0, 1.0); // Scale effect
                              }
                              return Center(
                                child: SizedBox(
                                  height: Curves.easeOut.transform(value) * 300, // Height animation
                                  width: Curves.easeOut.transform(value) * 250, // Width animation
                                  child: child,
                                ),
                              );
                            },
                            child: GestureDetector(
                              onTap: isUnlocked ? () {
                                setState(() {
                                  _selectedWeaponInfo = weaponInfo;
                                  _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                                });
                              } : null,
                              child: Card(
                                elevation: 10,
                                color: isUnlocked ? Colors.blueGrey[700] : Colors.grey[800],
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: isSelected ? Colors.amber : Colors.transparent,
                                      width: 3,
                                    ),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        weaponInfo.name.toUpperCase(),
                                        style: TextStyle(
                                          color: isUnlocked ? Colors.white : Colors.grey[500],
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        weaponInfo.description,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: isUnlocked ? Colors.grey[300] : Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 15),
                                      if (!isUnlocked)
                                        Text(
                                          'UNLOCK AT ${weaponInfo.unlockScore} SCORE',
                                          style: const TextStyle(
                                            color: Colors.redAccent,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ) else if (isSelected) 
                                        const Icon(Icons.check_circle, color: Colors.amber, size: 30),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Page Indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: weapons.map((weapon) {
                        int index = weapons.indexOf(weapon);
                        return Container(
                          width: 8.0,
                          height: 8.0,
                          margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 2.0),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentPage == index
                                ? Colors.amber
                                : Colors.grey.withOpacity(0.5),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    // Bottom Buttons
                    Padding(
                      padding: const EdgeInsets.only(bottom: 40.0, right: 20.0),
                      child: Align(
                        alignment: Alignment.bottomRight,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _selectedWeaponInfo == null || !(_userHighScore >= _selectedWeaponInfo!.unlockScore) ? null : () {
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
                              icon: const Icon(Icons.play_arrow, color: Colors.white),
                              label: const Text('START GAME', style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[700],
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const LeaderboardScreen()),
                                );
                              },
                              icon: const Icon(Icons.leaderboard, color: Colors.white),
                              label: const Text('VIEW LEADERBOARD', style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[700],
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const ItemDictionaryScreen()),
                                );
                              },
                              icon: const Icon(Icons.book, color: Colors.white),
                              label: const Text('ITEM DICTIONARY', style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange[700],
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          }
          return const Text('No weapon data found.', style: TextStyle(color: Colors.white));
        },
      ),
    );
  }
}
