import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http; // Import for HTTP requests
import 'dart:convert';

// You'll likely need other imports for database, authentication, etc. as you develop further.

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _audioPlayer = AudioPlayer();
  bool isPlaying = false;
  String currentSongTitle = "No song playing";
  final String apiKey = "EABCC"; // Your TheAudioDB API key
  final String apiBaseUrl = "www.theaudiodb.com/api/v1/json";

  Future<void> _fetchAndPlayMusic(String artist, String track) async {
    try {      
      final response = await http.get(Uri.parse('http://127.0.0.1:5000/search_track/$artist/$track'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data.containsKey('track_name') && data.containsKey('preview_url')) {
          final trackName = data['track_name'];
          final previewUrl = data['preview_url'];

          setState(() {
            currentSongTitle = trackName;
          });

          if (previewUrl != null && previewUrl.isNotEmpty) {
            await _audioPlayer.setUrl(previewUrl);
            await _audioPlayer.play();
            setState(() {
              isPlaying = true;
            });
          } else {
            // Handle case where preview URL is missing or empty
            _showErrorSnackBar('Preview URL not found for this track.');
          }
        } else {
          // Handle case where track data is missing or invalid
          _showErrorSnackBar('Track not found or invalid data received.');
        }
      } else {
        print("Error fetching track information: ${response.statusCode}");
        _updateSongTitle("Error fetching track");
        return;
      }

    } catch (e) {
      print("Error playing music: $e");
      _showErrorSnackBar('Error playing music: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }  

  void _togglePlayPause() {
    setState(() {
      if (isPlaying) {
        _audioPlayer.pause();        
      } else {
        if (_audioPlayer.playing) {
          _audioPlayer.play(); 
        }       
      }
      isPlaying = !isPlaying;
    });
  }

  void _updateSongTitle(String newTitle) {
    setState(() { currentSongTitle = newTitle; });
  }

  Future<void> _fetchAndDisplayAlbumTracks(int albumId) async {
    try {
      final albumTracksUrl =
          'https://$apiBaseUrl/$apiKey/track.php?m=$albumId';

      final response = await http.get(Uri.parse(albumTracksUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['track'] != null && data['track'].isNotEmpty) {
          for (var trackData in data['track']) {
            final trackId = trackData['idTrack'];
            
            // Fetch detailed track information
            final trackDetailsUrl =
                'https://$apiBaseUrl/$apiKey/track.php?h=$trackId';
            final detailsResponse = await http.get(Uri.parse(trackDetailsUrl));

            if (detailsResponse.statusCode == 200) {
              final detailsData = json.decode(detailsResponse.body);
              if (detailsData['track'] != null &&
                  detailsData['track'].isNotEmpty) {
                print("Track Name: ${detailsData['track'][0]['strTrack']}");
              } else {
                print("Track information not found for track ID: $trackId");
              }
            } else {
              print(
                  "Error fetching detailed track information: ${detailsResponse.statusCode}");
            }
          }
        } else {
          print("No tracks found for this album ID.");
        }
      } else {
        print("Error fetching album tracks: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching album tracks: $e");
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
        appBar: AppBar(title: const Text('Music Player')),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: Text(
                currentSongTitle,
                style: const TextStyle(fontSize: 20),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: IconButton(
                icon: Icon(isPlaying && _audioPlayer.playing
                    ? Icons.pause
                    : Icons.play_arrow), 
                onPressed: _togglePlayPause, 
              ),
            ),ElevatedButton(
              onPressed: () => _fetchAndPlayMusic("Coldplay", "Yellow"),
              child: const Text("Play Yellow by Coldplay"),
              ),
            ElevatedButton(
                onPressed: () => _fetchAndDisplayAlbumTracks(2115888),
                child: const Text("Fetch Album Tracks"),
              ),
          ],
        ),
      ),
    );
  }
}