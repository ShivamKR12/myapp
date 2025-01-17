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
}

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final _player = AudioPlayer();
  bool _isPlaying = false;
  String _currentSongTitle = 'No song selected';
  final String _currentSongPath = '';

  final List<Map<String, dynamic>> _songs = [];
  final List<String> _localSongPaths = [];
  final Map<String, double> _downloadProgress = {};
  bool _isShuffleOn = false;
  bool _isRepeatOn = false;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _pickLocalFiles(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: true,
    );

    if (result != null) {
      if (!mounted) return;
      setState(() {
        _localSongPaths.addAll(result.paths.whereType<String>());
        for (String path in _localSongPaths) {
          _songs.add({
            'title': path.split('/').last,
            'artist': 'Unknown',
            'source': path,
            'id': path.hashCode.toString(),
          });
        }
      });
    } else {
      if (!mounted) return;
      _showErrorSnackbar(context, 'No file selected');
    }
  }

  void _showCreatePlaylistDialog() {
    // Implement the method to show a dialog for creating a playlist
  }

  Future<void> _downloadSong(String songId, String source) async {
    // Implement the method to download a song
  }

  Future<void> _playSong(String source) async {
    // Implement the method to play a song
  }

  void _showErrorSnackbar(BuildContext context, String message) {
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
      appBar: AppBar(title: const Text('My Music App')),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () => _pickLocalFiles(context),
            child: const Text('Pick Local Files'),
          ),
          ElevatedButton(
            onPressed: () {
              _showCreatePlaylistDialog();
            },
            child: const Text('Create Playlist'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const PlaylistManagementScreen()));
            },
            child: const Text('View Playlists'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _songs.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_songs[index]['title']!),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_downloadProgress.containsKey(_songs[index]['id']) &&
                          _downloadProgress[_songs[index]['id']]! < 1.0)
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            value: _downloadProgress[_songs[index]['id']],
                          ),
                        )
                      else
                        IconButton(
                          icon: const Icon(Icons.download),
                          onPressed: () => _downloadSong(
                              _songs[index]['id']!, _songs[index]['source']!),
                        ),
                    ],
                  ),
                  subtitle: Text(_songs[index]['artist']!),
                  onTap: () {
                    setState(() {
                      _currentSongTitle = _songs[index]['title']!;
                      _playSong(_songs[index]['source']!);
                    });
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  'Now Playing: $_currentSongTitle',
                  style: const TextStyle(fontSize: 18),
                ),
                Text(
                  'Source: $_currentSongPath',
                  style: const TextStyle(fontSize: 16),
                ),
                StreamBuilder<Duration?>(
                  stream: _player.durationStream,
                  builder: (context, snapshot) {
                    final duration = snapshot.data ?? Duration.zero;
                    return Slider(
                      min: 0.0,
                      max: duration.inMilliseconds.toDouble(),
                      value: _player.position.inMilliseconds.toDouble(),
                      onChanged: (value) {
                        _player.seek(Duration(milliseconds: value.toInt()));
                      },
                    );
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Tooltip(
                      message: 'Shuffle',
                      child: IconButton(
                        onPressed: () {
                          setState(() {
                            _isShuffleOn = !_isShuffleOn;
                          });
                          _player.setShuffleModeEnabled(_isShuffleOn);
                        },
                        icon: Icon(
                          Icons.shuffle,
                          color: _isShuffleOn ? Colors.blue : Colors.grey,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        if (_isPlaying) {
                          await _player.pause();
                        } else {
                          await _player.play();
                        }
                        setState(() {
                          _isPlaying = !_isPlaying;
                        });
                      },
                      icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                    ),
                    Tooltip(
                      message: 'Repeat',
                      child: IconButton(
                        onPressed: () {
                          setState(() {
                            _isRepeatOn = !(_isRepeatOn);
                          });
                        },
                        icon: Icon(
                          Icons.repeat,
                          color: _isRepeatOn ? Colors.blue : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.volume_mute),
                    Expanded(
                      child: Slider(
                        value: _player.volume,
                        min: 0.0,
                        max: 1.0,
                        onChanged: (value) {
                          setState(() {
                            _player.setVolume(value);
                          });
                        },
                      ),
                    ),
                    const Icon(Icons.volume_up),
                    Text('${(_player.volume * 100).toInt()}%'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
