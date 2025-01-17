import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:logger/logger.dart'; // Ensure this line is present
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'playlist_management_screen.dart';
import 'dart:io';

// Initialize the logger
final logger = Logger();

// ... rest of the code ...

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
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  static const String playlistTable = 'playlists';
  static const String columnPlaylistId = 'id';
  static const String columnPlaylistName = 'name';

  static const String songsTable = 'songs';
  static const String columnSongId = 'id';
  static const String columnSongTitle = 'title';
  static const String columnSongArtist = 'artist';
  static const String columnSongSource = 'source';

  static const String playlistSongsTable = 'playlist_songs';

  static const String downloadedSongsTable = 'downloaded_songs';
  static const String columnFilePath = 'file_path';
  static const String columnIsDownloaded = 'is_downloaded';

  // Add the missing getters
  static const String columnName = 'name';
  static const String columnSongIds = 'song_ids';

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'my_database.db');

    // Ensure the directory exists
    if (!await Directory(dbPath).exists()) {
      await Directory(dbPath).create(recursive: true);
    }

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
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
      logger.e('Error creating playlist: $e'); // Replace print with logger
      return -1; // Error indicator
    }
  }

  Future<int> deletePlaylist(int id) async {
    Database db = await instance.database;
    try {
      return await db.delete(playlistTable, where: '$columnPlaylistId = ?', whereArgs: [id]);
    } catch (e) {
      logger.e('Error deleting playlist: $e'); // Replace print with logger
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
      logger.e('Error marking song as downloaded: $e'); // Replace print with logger
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
      logger.e('Error updating song download status: $e'); // Replace print with logger
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

  Future<String> getAppDocumentsDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<void> insertPlaylist(Map<String, dynamic> map) async {
    final db = await database;
    try {
      await db.insert(playlistTable, map);
    } catch (e) {
      logger.e('Error inserting playlist: $e');
    }
  }

  Future<void> updatePlaylistSongs(int playlistId, List<int> songIds) async {
    final db = await database;
    final songIdsString = songIds.map((id) => id.toString()).join(',');
    await db.update(
      'playlists',
      {'song_ids': songIdsString},
      where: 'id = ?',
      whereArgs: [playlistId],
    );
  }

  Future<List<Map<String, dynamic>>> queryAllPlaylists() async {
    Database db = await instance.database;
    try {
      return await db.query(playlistTable);
    } catch (e) {
      logger.e('Error querying all playlists: $e');
      return [];
    }
  }

  Future<void> addSongToPlaylist(int songId, int playlistId) async {
    final db = await database;
    try {
      await db.insert(playlistSongsTable, {
        'playlist_id': playlistId,
        'song_id': songId,
      });
    } catch (e) {
      logger.e('Error adding song to playlist: $e');
    }
  }

  Future<void> updateSong(Song song) async {
    final db = await database;
    try {
      await db.update(
        songsTable,
        song.toMap(),
        where: '$columnSongId = ?',
        whereArgs: [song.id],
      );
    } catch (e) {
      logger.e('Error updating song: $e');
    }
  }

  Future<void> deleteSong(int id) async {
    final db = await database;
    try {
      await db.delete(
        songsTable,
        where: '$columnSongId = ?',
        whereArgs: [id],
      );
    } catch (e) {
      logger.e('Error deleting song: $e');
    }
  }

  Future<void> closeDatabase() async {
    final db = await database;
    try {
      await db.close();
    } catch (e) {
      logger.e('Error closing database: $e');
    }
  }
}
