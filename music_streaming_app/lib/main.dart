import 'package:flutter/material.dart';
import 'player_screen.dart'; // Import the player screen file
import 'playlist_screen.dart'; // Import the playlist screen file
import 'home_screen.dart'; // Import the home screen file

void main() {
  runApp(const MyApp()); // Run the app
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Music App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // Define routes for navigation
      routes: {
        '/': (context) => const MainScreen(), // Default route (home screen)
        '/player': (context) => const PlayerScreen(),
        '/playlist': (context) => const PlaylistScreen(),
      },
      // Set initial route to the home screen
      initialRoute: '/',
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0; // Track the selected index
  final List<Widget> _screens = [
    const HomeScreen(),
    const PlayerScreen(), 
    const PlaylistScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // Update the selected index
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex], // Display the selected screen
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.music_note), label: 'Player'),
          BottomNavigationBarItem(
            icon: Icon(Icons.playlist_play), label: 'Playlists'),
        ],
        currentIndex: _selectedIndex, // Set the current index
        onTap: _onItemTapped, // Handle item tap
      ),
    );
  }
}
