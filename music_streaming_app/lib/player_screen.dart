import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'database_helper.dart';
import 'playlist_management_screen.dart';
import 'playlist_service.dart';
import 'strings.dart';

const String appTitle = 'My Music App';
const String pickLocalFilesButtonText = 'Pick Local Files';
const String createPlaylistButtonText = 'Create Playlist';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final _player = AudioPlayer();
  bool _isPlaying = false;
  String _currentSongTitle = 'No song selected';
  String _currentSongPath = '';

  final List<Map<String, dynamic>> _songs = [
    {
      'title': 'Song 1',
      'artist': 'Artist A',
      'source': 'https://luan.xyz/files/audio/ambient_c_motion.mp3',
      'id': '1'
    },
    {
      'title': 'Song 2',
      'artist': 'Artist B',
      'source': 'https://luan.xyz/files/audio/coins.mp3',
      'id': '2'
    },
    {
      'title': 'Song 3',
      'artist': 'Artist A',
      'source': 'https://luan.xyz/files/audio/newsroom.mp3',
      'id': '3'
    },
  ];

  final List<String> _localSongPaths = [];
  final Map<String, double> _downloadProgress = {};
  bool _isShuffleOn = false;
  bool _isRepeatOn = false;
  final PlaylistService _playlistService = PlaylistService();

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _player.currentIndexStream.listen((index) {
      if (index != null && index < _songs.length) {
        setState(() {
          _currentSongTitle = _songs[index]['title']!;
        });
      }
    });

    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _handleSongCompletion();
      } else if (state.processingState == ProcessingState.idle) {
        setState(() {
          _isPlaying = false;
          _currentSongTitle = 'No song selected';
        });
      }
    });
  }

  void _handleSongCompletion() {
    if (_isRepeatOn) {
      _player.seek(Duration.zero);
      _player.play();
    } else if (_isShuffleOn) {
      _player.seekToNext();
    } else {
      final nextIndex = _player.currentIndex! + 1;
      if (nextIndex < _songs.length) {
        _player.seek(nextIndex as Duration?);
      } else {
        _player.stop();
      }
    }
  }

  Future<void> _playSong(String source) async {
    try {
      setState(() {
        _currentSongPath = source;
      });

      if (source.startsWith('http')) {
        await _player.setAudioSource(AudioSource.uri(Uri.parse(source)));
      } else {
        _validateAudioFile(source);
        await _player.setAudioSource(AudioSource.file(source));
      }

      await _player.play();
      setState(() => _isPlaying = true);
    } catch (e) {
      _showErrorSnackbar('Error playing song: ${e.toString()}');
    }
  }

  Future<void> _downloadSong(String songId, String sourceUrl) async {
    final dir = await DatabaseHelper.instance.getAppDocumentsDirectory();
    final file = File('$dir/$songId.mp3'); // Corrected the path access

    setState(() {
      _downloadProgress[songId] = 0.0;
    });

    try {
      final response = await http.get(Uri.parse(sourceUrl));
      if (response.statusCode != 200) {
        throw HttpException('Failed to download song: ${response.statusCode}');
      }
      setState(() {
        _downloadProgress[songId] = 1.0;
      });
      DatabaseHelper.instance.insertDownloadedSong(songId as Song, file.path);
    } on SocketException {
      _showErrorSnackbar('No internet connection');
    } on HttpException catch (e) {
      _showErrorSnackbar('Download failed: ${e.message}');
    } on IOException catch (e) {
      _showErrorSnackbar('File write error: ${e.toString()}');
    } finally {
      setState(() {
        _downloadProgress[songId] = 1.0;
      });
    }
  }

  Future<void> _pickLocalFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: true,
    );

    if (result != null) {
      setState(() {
        _localSongPaths.addAll(result.paths.cast<String>());
        for (String? path in result.paths) {
          if (path == null) continue;
          _songs.add({
            'title': path.split('/').last,
            'artist': 'Unknown',
            'source': path,
            'id': path.hashCode.toString(),
          });
        }
      });
    } else {
      _showErrorSnackbar(errorNoFileSelected);
    }
  }

  Future<void> _createPlaylist(String playlistName) async {
    await _playlistService.createPlaylist(playlistName);
    setState(() {});
  }

  void _showCreatePlaylistDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String newPlaylistName = '';
        return AlertDialog(
          title: const Text(createPlaylistText),
          content: TextField(
            onChanged: (value) => newPlaylistName = value,
            decoration: const InputDecoration(hintText: playlistNameHint),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(cancelText)),
            TextButton(
              onPressed: () {
                if (newPlaylistName.isNotEmpty) {
                  _createPlaylist(newPlaylistName);
                  Navigator.pop(context);
                }
              },
              child: const Text(createText),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(appTitle)),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _pickLocalFiles,
            child: const Text(pickLocalFilesButtonText),
          ),
          ElevatedButton(
            onPressed: () {
              _showCreatePlaylistDialog();
            },
            child: const Text(createPlaylistButtonText),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const PlaylistManagementScreen()));
            },
            child: const Text(viewPlaylistsText),
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
                            _isRepeatOn = !_isRepeatOn;
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

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _validateAudioFile(String filePath) {
    if (filePath.isEmpty || !filePath.endsWith('.mp3')) {
      throw Exception("Invalid file format. Please select an MP3 file.");
    }
  }
}

class MusicPlayerScreen extends StatelessWidget {
  const MusicPlayerScreen({super.key}); // Added key parameter

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Music Player'),
      ),
      body: const Center(
        child: Text('Music Player Screen'),
      ),
    );
  }
}
