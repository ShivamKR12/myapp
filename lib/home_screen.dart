import 'package:flutter/material.dart';
import 'package:music_streaming_app/player_screen.dart'; // Import the PlayerScreen

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Screen'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PlayerScreen()),
            );
          },
          child: const Text('Go to Player Screen'),
        ),
      ),
    );
  }
}
