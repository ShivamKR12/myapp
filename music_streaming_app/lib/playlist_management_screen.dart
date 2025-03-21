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
  final TextEditingController _playlistNameController = TextEditingController();
  List<Map<String, dynamic>> _playlists = [];
  int? _selectedPlaylistId;

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    final playlists = await DatabaseHelper.instance.queryAllPlaylists();
    setState(() {
      _playlists = playlists;
    });
  }

  Future<void> _createPlaylist() async {
    try {
      if (_playlistNameController.text.isNotEmpty) {
        await _playlistService.createPlaylist(_playlistNameController.text);
        _playlistNameController.clear();
        _loadPlaylists();
      }
    } catch (e) {
      _showErrorSnackBar('Error creating playlist: $e');
    }
  }

  Future<void> _deletePlaylist(int id) async {
    try {
      await DatabaseHelper.instance.deletePlaylist(id);
      _loadPlaylists();
    } catch (e) {
      _showErrorSnackBar('Error deleting playlist: $e');
    }
  }

  Future<void> _updatePlaylistSongs(int playlistId, int songId, bool add) async {
    try {
      final playlist = _playlists.firstWhere(
        (p) => p['id'] == playlistId,
        orElse: () => throw Exception('Playlist not found'),
      );
      final songIds = (playlist['song_ids'] as String?) ?? '';
      final songIdList = songIds.isNotEmpty
          ? songIds.split(',').map(int.parse).toList()
          : <int>[]; // Ensure the list is of type List<int>

      if (add && !songIdList.contains(songId)) {
        songIdList.add(songId);
      } else if (!add && songIdList.contains(songId)) {
        songIdList.remove(songId);
      }

      await _updatePlaylistInDatabase(playlistId, songIdList);
      _loadPlaylists();
    } catch (e) {
      _showErrorSnackBar('Error updating playlist: $e');
    }
  }

  Future<void> _updatePlaylistInDatabase(int playlistId, List<int> songIdList) async {
    await DatabaseHelper.instance.updatePlaylistSongs(
      playlistId,
      songIdList,
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
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
                  itemCount: _playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = _playlists[index];
                    final songIds = (playlist['song_ids'] as String?) ?? '';
                    final songIdList = songIds.isNotEmpty ? songIds.split(',').map(int.parse).toList() : [];
                    final isInPlaylist = songIdList.contains(playlist['id']);

                    return CheckboxListTile(
                      title: Text(playlist['name']),
                      value: isInPlaylist,
                      onChanged: (value) {
                        _updatePlaylistSongs(_selectedPlaylistId!, playlist['id'], value!);
                      },
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
