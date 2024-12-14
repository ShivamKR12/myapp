import 'database_helper.dart';

class PlaylistService {
  Future<void> createPlaylist(String playlistName) async {
    await DatabaseHelper.instance.createPlaylist(playlistName);
  }

  Future<void> addSongToPlaylist(String songId, String playlistName) async {
    await DatabaseHelper.instance.addSongToPlaylist(songId as int, playlistName as int);
  }
}
