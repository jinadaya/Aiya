extends Node

enum Song {
	BeachSong1,
	BeachSong2,
}

var storage : Dictionary[Song, Resource] = {
	Song.BeachSong1: preload("res://audio/beach/beach_1.mp3"),
	Song.BeachSong2: preload("res://audio/beach/beach_2.mp3")
}

func get_song(song_id : Song) -> Resource:
	return storage[song_id]
