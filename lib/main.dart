import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:logger/logger.dart';
import 'package:music_streaming_app/player_screen.dart'; // Import the PlayerScreen

final logger = Logger();

void main() {
  if (const bool.fromEnvironment('dart.vm.product') == false) {
    // Only call registerExtension in non-production environments
    developer.registerExtension('extensionName', (String method, Map<String, String> parameters) async {
      // Your extension code here
      return developer.ServiceExtensionResponse.result('{"status": "ok"}');
    });
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  final _audioPlayer = AudioPlayer();
  bool isPlaying = false;
  String currentSongTitle = "No song playing";
  final String apiKey = "EABCC"; // Your TheAudioDB API key
  final String apiBaseUrl = "www.theaudiodb.com/api/v1/json";


  void _togglePlayPause() {
    setState(() {
      if (isPlaying) {
        _audioPlayer.pause();
      } else {
        _audioPlayer.play();
      }
      isPlaying = !isPlaying;
    });
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
        appBar: AppBar(
          title: Text(currentSongTitle),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ElevatedButton(
                onPressed: _togglePlayPause,
                child: Text(isPlaying ? 'Pause' : 'Play'),
              ),
            ],
          ),
        ),
      ),
      routes: {
        '/player': (context) => const PlayerScreen(),
      },
    );
  }
}
