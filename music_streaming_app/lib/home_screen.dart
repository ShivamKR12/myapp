import 'package:flutter/material.dart';

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
          },
          child: const Text('Play Music'),
        ),
      ),
    );
  }
}
