
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:flutter_client/main.dart';
import 'package:flutter_client/weapon_selection_screen.dart';

class IntroScreen extends StatefulWidget {
  @override
  _IntroScreenState createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
    serverClientId: "569377590166-2mml97i6m2o1f0b7inagaksf47v8s0kg.apps.googleusercontent.com",
  );

  Future<void> _handleSignIn() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled the sign-in
        return;
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Send ID token to backend
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/users'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'token': googleAuth.idToken!,
        }),
      );

      if (response.statusCode == 200) {
        // Navigate to the weapon selection screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const WeaponSelectionScreen()),
        );
      } else {
        // Handle error
        print('Failed to sign in: ${response.body}');
      }
    } catch (error) {
      print('Error signing in: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'BitRogue',
              style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: _handleSignIn,
              child: Text('Sign in with Google'),
            ),
          ],
        ),
      ),
    );
  }
}
