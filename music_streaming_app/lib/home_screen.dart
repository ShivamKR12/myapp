import 'package:flutter/material.dart';
import 'player_screen.dart'; // Import the music player screen
import 'database_helper.dart';
import 'playlist_management_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _songs = [];
  List<Map<String, dynamic>> _playlists = [];
  String _currentSongTitle = 'No song playing';

  @override
  void initState() {
    super.initState();
    _loadSongs();
    _loadPlaylists();
  }

  Future<void> _loadSongs() async {
    // Load songs from the database
    // This is a placeholder implementation, replace with actual database query
    _songs = [
      {'title': 'Song 1', 'artist': 'Artist A', 'source': 'source1'},
      {'title': 'Song 2', 'artist': 'Artist B', 'source': 'source2'},
    ];
    setState(() {});
  }

  Future<void> _loadPlaylists() async {
    // Load playlists from the database
    _playlists = await DatabaseHelper.instance.queryAllPlaylists();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Music Streaming App'),
      ),
      body: Column(
        children: [
          ElevatedButton(
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
          Expanded(
            child: ListView.builder(
              itemCount: _songs.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_songs[index]['title']),
                  subtitle: Text(_songs[index]['artist']),
                  onTap: () {
                    setState(() {
                      _currentSongTitle = _songs[index]['title'];
                    });
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlayerScreen(),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _playlists.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_playlists[index]['name']),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlaylistManagementScreen(),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
