import 'database_helper.dart';

class PlaylistService {
  // Method to create a new playlist
  Future<void> createPlaylist(String playlistName) async {
    await DatabaseHelper.instance.createPlaylist(playlistName);
  }

  // Method to add a song to an existing playlist
  Future<void> addSongToPlaylist(int songId, int playlistId) async {
    await DatabaseHelper.instance.addSongToPlaylist(songId, playlistId);
  }

  // Method to delete a playlist
  Future<void> deletePlaylist(int playlistId) async {
    await DatabaseHelper.instance.deletePlaylist(playlistId);
  }

  // Method to get all playlists
  Future<List<Map<String, dynamic>>> getAllPlaylists() async {
    return await DatabaseHelper.instance.queryAllPlaylists();
  }

  // Method to update playlist songs
  Future<void> updatePlaylistSongs(int playlistId, List<int> songIds) async {
    await DatabaseHelper.instance.updatePlaylistSongs(playlistId, songIds);
  }
}
