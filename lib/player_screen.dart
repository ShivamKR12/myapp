import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';


class PlayerScreen extends StatefulWidget {
  const PlayerScreen({Key? key}) : super(key: key);

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final _player = AudioPlayer();
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    // Replace 'your_audio_file.mp3' with the actual path to your audio file.
    _player.setAudioSource(AudioSource.uri(Uri.parse('your_audio_file.mp3')));
  }


  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Music Player'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Placeholder for album art
            Container(
              width: 200,
              height: 200,
              color: Colors.grey,
            ),
            const SizedBox(height: 20),
             // Placeholder for song title
            const Text('Song Title', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 10),
            // Placeholder for artist
            const Text('Artist Name', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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
          ],
        ),
      ),
    );
  }
}
