import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'database_helper.dart'; // Import your DatabaseHelper

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final _player = AudioPlayer();
  bool _isPlaying = false;
  String _currentSongTitle = 'No song selected';
  String _currentArtist = '';
  final Map<String, double> _downloadProgress = {}; 

  final List<Map<String, dynamic>> _songs = [
    {'title': 'Song 1', 'artist': 'Artist A', 'source': 'audio_source_1.mp3', 'id': '1'}, // Replace with actual audio source URLs
    {'title': 'Song 2', 'artist': 'Artist B', 'source': 'audio_source_2.mp3', 'id': '2'}, // Replace with actual audio source URLs
    {'title': 'Song 3', 'artist': 'Artist A', 'source': 'audio_source_3.mp3', 'id': '3'}, // Replace with actual audio source URLs
  ];

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  void _playSong(String source) async {
    try {
      await _player.setAudioSource(AudioSource.uri(Uri.parse(source)));
      await _player.play();
      setState(() {
        _isPlaying = true;
      });
    } catch (e) {
      print("Error playing song: $e");
      // Handle the error appropriately (e.g., show a snackbar to the user)
    }
  }

  Future<void> _downloadSong(String songId, String sourceUrl) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$songId.mp3'); 
    
    setState(() {
      _downloadProgress[songId] = 0.0; 
    });

    try {
      // Replace with your actual download logic
      // For example, using http package to download the file
      // You'll need to fetch the audio data from sourceUrl and save it to file
      // ...

      // Simulate download progress for demonstration
      for (var i = 0; i <= 100; i += 10) {
        await Future.delayed(const Duration(milliseconds: 100));
        setState(() {
          _downloadProgress[songId] = i / 100.0;
        });
      }

      // After successful download, update the database
      await DatabaseHelper.instance.insertDownloadedSong(songId, file.path); 
    } catch (e) {
      print("Error downloading song: $e");
      // Handle download errors
    } finally {
      setState(() {
        _downloadProgress[songId] = 1.0; 
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Music Player')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _songs.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_songs[index]['title']!),
                  trailing: _downloadProgress.containsKey(_songs[index]['id']) &&
                          _downloadProgress[_songs[index]['id']]! < 1.0
                      ? LinearProgressIndicator(
                          value: _downloadProgress[_songs[index]['id']],
                        )
                      : IconButton(
                          icon: const Icon(Icons.download),
                          onPressed: () {
                            _downloadSong(
                              _songs[index]['id']!,
                              _songs[index]['source']!,
                            );
                          },
                        ),
                  subtitle: Text(_songs[index]['artist']!),
                  onTap: () {
                    setState(() {
                      _currentSongTitle = _songs[index]['title']!;
                      _currentArtist = _songs[index]['artist']!;
                      _playSong(_songs[index]['source']!); // Placeholder source
                    });
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  'Now Playing: $_currentSongTitle',
                  style: const TextStyle(fontSize: 18),
                ),
                Text(
                  _currentArtist,
                  style: const TextStyle(fontSize: 16),
                ),
                 IconButton(
                  onPressed: () async {
                     if (_isPlaying) {
                        await _player.pause();
                      } else {
                        await _player.play();
                      }
                    setState(() {
                      _isPlaying = !_isPlaying;
                    });
                  },
                  icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}