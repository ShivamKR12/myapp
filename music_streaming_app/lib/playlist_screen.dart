import 'package:flutter/material.dart';
import 'database_helper.dart';

class PlaylistScreen extends StatefulWidget {
  const PlaylistScreen({super.key});

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  final _playlistNameController = TextEditingController();
  List<Map<String, dynamic>> _playlists = [];
  int? _selectedPlaylistId; 

  // Sample song data - replace with actual song data from your app
  final List<Map<String, dynamic>> _songs = [
    {'id': 1, 'title': 'Song 1', 'artist': 'Artist A'},
    {'id': 2, 'title': 'Song 2', 'artist': 'Artist B'},
    {'id': 3, 'title': 'Song 3', 'artist': 'Artist C'},
  ];

  @override
  void initState() {
    super.initState();
    _refreshPlaylists();
  }

  Future<void> _refreshPlaylists() async {
    final playlists = await DatabaseHelper.instance.queryAllPlaylists();
    setState(() {
      _playlists = playlists;
    });
  }

  Future<void> _createPlaylist() async {
    try {
      if (_playlistNameController.text.isNotEmpty) {
        await DatabaseHelper.instance.insertPlaylist({
          DatabaseHelper.columnName: _playlistNameController.text,
          DatabaseHelper.columnSongIds: '', // Initially empty song list
        });
        _playlistNameController.clear();
        _refreshPlaylists();
      }
    } catch (e) {
      _showErrorSnackBar('Error creating playlist: $e');
    }
  }

  Future<void> _deletePlaylist(int id) async {
    try {
      await DatabaseHelper.instance.deletePlaylist(id);
      _refreshPlaylists();
    } catch (e) {
      _showErrorSnackBar('Error deleting playlist: $e');
    }
  }

  // Function to handle adding/removing songs from a playlist
  Future<void> _updatePlaylistSongs(int playlistId, int songId, bool add) async {
    try {
      final playlist = _playlists.firstWhere((p) => p['id'] == playlistId,
          orElse: () => throw Exception('Playlist not found')); 
      final songIds = (playlist['song_ids'] as String?) ?? '';
      final songIdList = songIds.isNotEmpty
          ? songIds.split(',').map(int.parse).toList()
          : [];

    if (add && !songIdList.contains(songId)) {
      songIdList.add(songId);
    } else if (!add && songIdList.contains(songId)) {
      songIdList.remove(songId);
    }

    await DatabaseHelper.instance.updatePlaylistSongs(
        playlistId, songIdList.map((id) => id.toString()).join(','));
    _refreshPlaylists();
    } catch (e) {
      _showErrorSnackBar('Error updating playlist: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Playlists')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _playlistNameController,
              decoration: const InputDecoration(hintText: 'Enter playlist name'),
            ),
          ),
          ElevatedButton(
            onPressed: _createPlaylist,
            child: const Text('Create Playlist'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _playlists.length,
              itemBuilder: (context, index) {
                final playlist = _playlists[index];
                return ListTile(
                  title: Text(playlist['name']),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deletePlaylist(playlist['id']),
                  ),
                  onTap: () {
                    setState(() {
                      _selectedPlaylistId = playlist['id'];
                    });
                  },
                );
              },
            ),
          ),
          if (_selectedPlaylistId != null)
            Expanded(
              child: ListView.builder(
                itemCount: _songs.length,
                itemBuilder: (context, index) {
                  final song = _songs[index];
                  final playlist = _playlists.firstWhere((p) => p['id'] == _selectedPlaylistId);
                  final songIds = (playlist['song_ids'] as String?) ?? '';
                  final songIdList = songIds.isNotEmpty ? songIds.split(',').map(int.parse).toList() : [];
                  final isInPlaylist = songIdList.contains(song['id']);

                  return CheckboxListTile(
                    title: Text(song['title']),
                    subtitle: Text(song['artist']),
                    value: isInPlaylist,
                    onChanged: (value) {
                      _updatePlaylistSongs(_selectedPlaylistId!, song['id'], value!);
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