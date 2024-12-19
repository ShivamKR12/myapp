import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class Song {
  final int id;
  final String title;
  final String artist;
  final String source;

  Song({required this.id, required this.title, this.artist = '', required this.source});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'source': source,
    };
  }
}

class DatabaseHelper {
  static const _databaseName = "MyDatabase.db";
  static const _databaseVersion = 1;

  // Playlist table
  static const playlistTable = 'playlists';
  static const columnPlaylistId = 'id';
  static const columnPlaylistName = 'name';

  // Songs table
  static const songsTable = 'songs';
  static const columnSongId = 'id';
  static const columnSongTitle = 'title';
  static const columnSongArtist = 'artist';
  static const columnSongSource = 'source';

  // Playlist-Songs mapping table
  static const playlistSongsTable = 'playlist_songs';

  // Downloaded Songs table
  static const downloadedSongsTable = 'downloaded_songs';
  static const columnFilePath = 'file_path';
  static const columnIsDownloaded = 'is_downloaded';

  // Singleton instance
  static Database? _database;

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onConfigure: (db) async {
        // Enable foreign key constraints
        await db.execute("PRAGMA foreign_keys = ON;");
      },
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $playlistTable (
        $columnPlaylistId INTEGER PRIMARY KEY,
        $columnPlaylistName TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $songsTable (
        $columnSongId INTEGER PRIMARY KEY,
        $columnSongTitle TEXT NOT NULL,
        $columnSongArtist TEXT,
        $columnSongSource TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $playlistSongsTable (
        playlist_id INTEGER,
        song_id INTEGER,
        FOREIGN KEY (playlist_id) REFERENCES $playlistTable($columnPlaylistId) ON DELETE CASCADE,
        FOREIGN KEY (song_id) REFERENCES $songsTable($columnSongId) ON DELETE CASCADE,
        PRIMARY KEY (playlist_id, song_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE $downloadedSongsTable (
        $columnSongId INTEGER PRIMARY KEY,
        $columnFilePath TEXT NOT NULL,
        $columnIsDownloaded INTEGER NOT NULL,
        FOREIGN KEY ($columnSongId) REFERENCES $songsTable($columnSongId) ON DELETE CASCADE
      )
    ''');
  }

  Future<int> createPlaylist(String playlistName) async {
    Database db = await instance.database;
    try {
      return await db.insert(playlistTable, {columnPlaylistName: playlistName});
    } catch (e) {
      print('Error creating playlist: $e');
      return -1; // Error indicator
    }
  }

  Future<int> deletePlaylist(int id) async {
    Database db = await instance.database;
    try {
      return await db.delete(playlistTable, where: '$columnPlaylistId = ?', whereArgs: [id]);
    } catch (e) {
      print('Error deleting playlist: $e');
      return -1; // Error indicator
    }
  }

  Future<void> markSongAsDownloaded(int songId, String filePath) async {
    Database db = await instance.database;
    try {
      await db.insert(downloadedSongsTable, {
        columnSongId: songId,
        columnFilePath: filePath,
        columnIsDownloaded: 1,
      });
    } catch (e) {
      print('Error marking song as downloaded: $e');
    }
  }

  Future<void> updateSongAsDownloaded(int songId) async {
    Database db = await instance.database;
    try {
      await db.update(
        downloadedSongsTable,
        {columnIsDownloaded: 1},
        where: '$columnSongId = ?',
        whereArgs: [songId],
      );
    } catch (e) {
      print('Error updating song download status: $e');
    }
  }

  Future<bool> isSongDownloaded(int songId) async {
    Database db = await instance.database;
    var result = await db.query(
      downloadedSongsTable,
      where: '$columnSongId = ?',
      whereArgs: [songId],
    );
    return result.isNotEmpty;
  }

  Future<void> insertDownloadedSong(Song song, String path) async {
    final db = await database;
    await db.insert('songs', song.toMap());
  }

  // Implement or remove these methods if not needed
  Future<void> insertPlaylist(Map<String, dynamic> map) async {
    // TODO: Implementation
  }

  Future<void> updatePlaylistSongs(int playlistId, List<int> songIds) async {
    // TODO: Implementation
  }

  Future<List<Map<String, dynamic>>> queryAllPlaylists() async {
    // TODO: Implementation
    return [];
  }

  Future<void> addSongToPlaylist(int songId, int playlistId) async {
    // TODO: Implementation
  }
}
