import os
import random
import pygame
import argparse

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
            try:
                song = self.library[index]
                print(f"Now playing: {song['title']} - {song['artist']}")
                pygame.mixer.init()
                pygame.mixer.music.load(song['path'])
                pygame.mixer.music.play()
                while pygame.mixer.music.get_busy():
                    pygame.time.Clock().tick(10)  # Keep the program responsive
            except pygame.error as e:
                print(f"Error playing song: {e}")
        else:
            print("Invalid song index.")

def main():
    parser = argparse.ArgumentParser(description="Simple Music Player")
    parser.add_argument("-d", "--directory", default="music_directory", help="Directory containing music files")
    args = parser.parse_args()

    music_dir = args.directory
    player = MusicPlayer(music_dir) 

    if not os.path.exists(music_dir):
        print(f"Directory '{music_dir}' not found. "
              f"Please create it and add your music files, or specify a different directory using the -d option.")
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