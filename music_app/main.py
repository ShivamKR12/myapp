import os
import random
import pygame
import argparse
import tkinter as tk
from flask import Flask, jsonify, request
import requests

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
                try:
                    pygame.mixer.music.load(song['path'])
                except pygame.error as e:
                    print(f"Error loading song: {e}")
                    return
                pygame.mixer.music.play()
                while pygame.mixer.music.get_busy():
                    pygame.time.Clock().tick(10)  # Keep the program responsive
            except pygame.error as e:
                print(f"Error playing song: {e}")
        else:
            print("Invalid song index.")

class MusicPlayerGUI:
    def __init__(self, master, music_dir="music_directory"):
        self.master = master
        master.title("Music Player")

        self.player = MusicPlayer(music_dir)

        self.song_listbox = tk.Listbox(master)
        self.song_listbox.pack(fill=tk.BOTH, expand=True)

        if not self.player.library:
            self.song_listbox.insert(tk.END, "No songs found in the library.")
        else:
            for song in self.player.library:
                self.song_listbox.insert(tk.END, f"{song['title']} - {song['artist']}")

        play_button = tk.Button(master, text="Play", command=self.play_selected_song)
        play_button.pack()

    def play_selected_song(self):
        try:
            selection = self.song_listbox.curselection()
            if selection:
                song_index = selection[0]
                self.player.play_song(song_index)
        except Exception as e:
            print(f"Error playing song: {e}")

def main():
    music_dir = "music_directory"  # Default music directory

    if not os.path.exists(music_dir):
        print(f"Directory '{music_dir}' not found. "
              f"Please create it and add your music files.")
        return

    root = tk.Tk()
    player_gui = MusicPlayerGUI(root, music_dir)
    root.mainloop()

app = Flask(__name__)

API_KEY = os.getenv('API_KEY', 'EABCC')
API_BASE_URL = "https://www.theaudiodb.com/api/v1/json"

@app.route('/search_track/<artist_name>/<track_name>', methods=['GET'])
def search_track(artist_name, track_name):
    try:
        url = f"{API_BASE_URL}/{API_KEY}/searchtrack.php?s={artist_name}&t={track_name}"
        response = requests.get(url)
        response.raise_for_status()  # Raise HTTPError for bad responses (4xx or 5xx)
        data = response.json()

        if data and data['track']:
            track = data['track'][0]
            return jsonify({'track_name': track['strTrack'], 'preview_url': track['strTrackPreviewUrl']})
        else:
            return jsonify({'error': 'Track not found'}), 404

    except requests.exceptions.RequestException as e:
        return jsonify({'error': f'API request failed: {e}'}), 500
    except Exception as e:
        return jsonify({'error': f'An error occurred: {e}'}), 500


if __name__ == "__main__":
    # Uncomment the below line to run the GUI
    # main()
    app.run(debug=True)
