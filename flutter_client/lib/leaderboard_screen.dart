
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_client/constants.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  late Future<List<dynamic>> _leaderboardData;

  @override
  void initState() {
    super.initState();
    _leaderboardData = _fetchLeaderboard();
  }

  Future<List<dynamic>> _fetchLeaderboard() async {
    try {
      final response = await http.get(Uri.parse('${AppConstants.baseUrl}/leaderboard'));

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('Failed to load leaderboard: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching leaderboard: $e');
      throw Exception('Failed to connect to server or parse data.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.deepPurple, Colors.indigo],
          ),
        ),
        child: FutureBuilder<List<dynamic>>(
          future: _leaderboardData,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text('No scores yet. Be the first!', style: TextStyle(color: Colors.white)),
              );
            } else {
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final scoreEntry = snapshot.data![index];
                  final userName = scoreEntry['user']['username'] ?? 'Unknown';
                  final score = scoreEntry['score'] ?? 0;
                  final weapon = scoreEntry['weapon'] ?? 'N/A';
                  final items = scoreEntry['items'] ?? 'None';

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: Colors.deepPurple[700],
                    elevation: 4,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.deepPurple[400],
                        child: Text('${index + 1}', style: const TextStyle(color: Colors.white)),
                      ),
                      title: Text(
                        '$userName - Score: $score',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Weapon: $weapon | Items: $items',
                        style: TextStyle(color: Colors.grey[300]),
                      ),
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }
}
