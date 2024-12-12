import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _audioPlayer = AudioPlayer();

  Future<void> _playMusic(String assetPath) async {
    try {
      await _audioPlayer.setAsset(assetPath);
      await _audioPlayer.play();
    } catch (e) {
      print("Error playing music: $e");
      // Consider showing a user-friendly error message here
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error playing music: $e')),
      );
    }
  }


  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Music Player')),
        body: Center(
          child: ElevatedButton(
            onPressed: () => _playMusic('assets/your_music_file.mp3'), // Replace 'your_music_file.mp3' with your actual file
            child: Text('Play Music'),
          ),
        ),
      ),
    );
  }
}