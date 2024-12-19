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
}
