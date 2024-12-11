import os
import random

class MusicPlayer:
    def __init__(self, music_dir="music_directory"):
        self.music_dir = music_dir
        self.library = []
        self.load_library()

    def load_library(self):
        """Loads songs from the music directory into the library."""
        for filename in os.listdir(self.music_dir):
            if filename.endswith((".mp3", ".wav", ".ogg")):
                song_path = os.path.join(self.music_dir, filename)
                song_title = os.path.splitext(filename)[0]  # Use filename as title
                self.library.append({"title": song_title, "artist": "Unknown", "path": song_path})

    def add_song(self, title, artist, path):
        """Adds a song to the library."""
        self.library.append({"title": title, "artist": artist, "path": path})

    def list_songs(self):
        """Lists all songs in the library."""
        if not self.library:
            print("Library is empty.")
            return

        for i, song in enumerate(self.library):
            print(f"{i + 1}. {song['title']} - {song['artist']}")

    def play_song(self, index):
        """Plays the song at the given index."""
        if 0 <= index < len(self.library):
            song = self.library[index]
            print(f"Now playing: {song['title']} - {song['artist']}")
            # Placeholder for actual playback functionality
            # You would use a library like pygame or playsound here
        else:
            print("Invalid song index.")

def main():
    player = MusicPlayer()
    music_dir = "music_directory"  # Replace with your actual music directory

    if not os.path.exists(music_dir):
        print(f"Directory '{music_dir}' not found. Please add your music files.")
        return

    # player.add_songs(music_dir)  # No need to call add_songs, it's done in load_library

    while True:
        print("\nMusic Player Menu:")
        print("1. List Songs")
        print("2. Play Song")
        print("3. Exit")
        choice = input("Enter your choice: ")

        if choice == '1':
            player.list_songs()
        elif choice == '2':
            player.list_songs()  # List songs for user to choose
            if player.library:  # Check if there are songs in the library
                try:
                    song_index = int(input("Enter song number to play: ")) - 1
                    player.play_song(song_index)
                except ValueError:
                    print("Invalid input. Please enter a number.")
        elif choice == '3':
            break
        else:
            print("Invalid choice. Please try again.")


if __name__ == "__main__":
    main()