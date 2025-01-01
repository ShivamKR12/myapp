import 'package:flutter/material.dart';
import 'player_screen.dart'; // Import the music player screen

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Music Streaming App'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // Navigate to the music player screen
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MusicPlayerScreen()),
            ).catchError((error) {
              // Handle navigation error
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to navigate: $error')),
              );
            });
          },
          child: const Text('Play Music'),
        ),
      ),
    );
  }
}
