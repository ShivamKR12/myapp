import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'playlist_service.dart';

class PlaylistManagementScreen extends StatefulWidget {
  const PlaylistManagementScreen({super.key});

  @override
  State<PlaylistManagementScreen> createState() => _PlaylistManagementScreenState();
}

class _PlaylistManagementScreenState extends State<PlaylistManagementScreen> {
  final PlaylistService _playlistService = PlaylistService();
  List<Map<String, dynamic>> _playlists = [];

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    final playlists = await _playlistService.getPlaylists();
    setState(() {
      _playlists = playlists;
    });
  }

  void _showCreatePlaylistDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String newPlaylistName = '';
        return AlertDialog(
          title: const Text('Create Playlist'),
          content: TextField(
            onChanged: (value) => newPlaylistName = value,
            decoration: const InputDecoration(hintText: 'Playlist Name'),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                if (newPlaylistName.isNotEmpty) {
                  _createPlaylist(newPlaylistName);
                  Navigator.pop(context);
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createPlaylist(String playlistName) async {
    await _playlistService.createPlaylist(playlistName);
    _loadPlaylists();
  }

  Future<void> _deletePlaylist(int playlistId) async {
    await _playlistService.deletePlaylist(playlistId);
    _loadPlaylists();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Playlist Management'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Manage your playlists here'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _showCreatePlaylistDialog,
              child: const Text('Create Playlist'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _playlists.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_playlists[index]['name']),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deletePlaylist(_playlists[index]['id']),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pop(context);
        },
        child: const Icon(Icons.arrow_back),
      ),
    );
  }
}
