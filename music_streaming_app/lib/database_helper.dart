import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static const _databaseName = 'music_app.db';
  static const _databaseVersion = 1;

  static const playlistTable = 'playlists';
  static const columnId = 'id';
  static const columnName = 'name';
  static const columnSongIds = 'song_ids';

  static const downloadedSongsTable = 'downloaded_songs';
  static const columnSongId = 'song_id'; // Assuming you have a 'songs' table
  static const columnFilePath = 'file_path';
  static const columnIsDownloaded = 'is_downloaded';

  // Make this a singleton class
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async => _database ??= await _initDatabase();


  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(path,
        version: _databaseVersion, onCreate: _onCreate);
  }


  Future _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $playlistTable (
            $columnId INTEGER PRIMARY KEY,
            $columnName TEXT NOT NULL,
            $columnSongIds TEXT
          )
          ''');
    await db.execute('''
          CREATE TABLE $downloadedSongsTable (
            $columnSongId INTEGER PRIMARY KEY, 
            $columnFilePath TEXT NOT NULL,
            $columnIsDownloaded INTEGER NOT NULL
          )
          ''');
  }

  Future<int> insertPlaylist(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(playlistTable, row);
  }

  Future<List<Map<String, dynamic>>> queryAllPlaylists() async {
    Database db = await instance.database;
    return await db.query(playlistTable);
  }

    Future<int> deletePlaylist(int id) async {
    Database db = await instance.database;
    return await db.delete(playlistTable, where: '$columnId = ?', whereArgs: [id]);
  }

  Future<void> addSongToPlaylist(int playlistId, int songId) async {
    Database db = await instance.database;
    
    // Get the current song IDs for the playlist
    var playlist = await db.query(playlistTable, where: '$columnId = ?', whereArgs: [playlistId]);
    
    if (playlist.isEmpty) {
      throw Exception('Playlist not found');
    }

    String currentSongIds = playlist.first[columnSongIds] ?? '';
    List<String> songIdList = currentSongIds.isNotEmpty ? currentSongIds.split(',') : [];

    // Check if the song is already in the playlist
    if (songIdList.contains(songId.toString())) {
      throw Exception('Song already in playlist');
    }

    songIdList.add(songId.toString());
    String updatedSongIds = songIdList.join(',');

    await db.update(playlistTable, {columnSongIds: updatedSongIds}, where: '$columnId = ?', whereArgs: [playlistId]);
  }

  Future<void> removeSongFromPlaylist(int playlistId, int songId) async {
    Database db = await instance.database;
    var playlist = await db.query(playlistTable, where: '$columnId = ?', whereArgs: [playlistId]);

    if (playlist.isEmpty) {
      throw Exception('Playlist not found');
    }

    String currentSongIds = playlist.first[columnSongIds] ?? '';
    List<String> songIdList = currentSongIds.isNotEmpty ? currentSongIds.split(',') : [];
    songIdList.remove(songId.toString());
    String updatedSongIds = songIdList.join(',');

    await db.update(playlistTable, {columnSongIds: updatedSongIds}, where: '$columnId = ?', whereArgs: [playlistId]);
  }
}

  // Downloaded Songs Table Methods
  Future<int> insertDownloadedSong(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(downloadedSongsTable, row);
  }

  Future<bool> isSongDownloaded(int songId) async {
    Database db = await instance.database;
    var result = await db.query(downloadedSongsTable,
        where: '$columnSongId = ?', whereArgs: [songId]);
    return result.isNotEmpty;
  }

  Future<String?> getDownloadedSongFilePath(int songId) async {
    Database db = await instance.database;
    var result = await db.query(downloadedSongsTable,
        where: '$columnSongId = ?', whereArgs: [songId]);
    if (result.isNotEmpty) {
      return result.first[columnFilePath] as String?;
    } else {
      return null;
    }
  }

