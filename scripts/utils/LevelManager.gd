extends Node

signal level_changed(from : Location, to : Location)
signal music_level_changed(level: Location)

enum Location {
	INIT,
	BEACH, CAVE, ANCIENT_CITY_1,
	ANCIENT_CITY_2, ANCIENT_CITY_3,
	LIGHTHOUSE
}

var LocPath : Dictionary [ Location, StringName ] = {
	Location.INIT : &"res://scenes/StartMenuScene.tscn",
	Location.BEACH : &"res://scenes/beach/Beach.tscn",
	Location.CAVE : &"res://scenes/cave/DarkCave.tscn",
	Location.ANCIENT_CITY_1 : &"res://scenes/ancient_city/1/AncientCity_1.tscn",
	Location.ANCIENT_CITY_2 : &"res://scenes/ancient_city/2/AncientCity_2.tscn",
	Location.ANCIENT_CITY_3 : &"res://scenes/ancient_city/3/AncientCity_3.tscn",
	Location.LIGHTHOUSE : &"res://scenes/lighthouse/Lighthouse.tscn",
}

func _ready() -> void:
	music_level_changed.emit(Location.INIT)

func go(from : Location, to: Location, need_remember: bool = true):
	if need_remember: _write_data(from, to)
	level_changed.emit(from, to)
	music_level_changed.emit(to)
	InputManager.off()
	await GlobalFader.fade_out()
	var to_path = LocPath.get(to)
	if not to_path: push_warning("LevelManager: cannot go from ", from, " to ", to, " location. No file path found.")
	get_tree().change_scene_to_file(to_path)
	await GlobalFader.fade_in()
	InputManager.on()

func go_blur(from : Location, to: Location):
	_write_data(from, to)
	InputManager.off()
	await GlobalFader.blur_out()
	var to_path = LocPath.get(to)
	if not to_path: 
		push_warning("LevelManager: cannot go from ", from, " to ", to, " location. No file path found.")
	get_tree().change_scene_to_file(to_path)
	await GlobalFader.blur_in()
	InputManager.on()

func go_blur_fade(from : Location, to: Location):
	_write_data(from, to)
	InputManager.off()
	await GlobalFader.blur_fade_out()
	var to_path = LocPath.get(to)
	if not to_path: 
		push_warning("LevelManager: cannot go from ", from, " to ", to, " location. No file path found.")
	get_tree().change_scene_to_file(to_path)
	await GlobalFader.blur_fade_in()
	InputManager.on()

func _write_data(from: Location, to: Location) -> void:
	match to:
		Location.ANCIENT_CITY_3:
			var from_to_ac3: WorldInfo.ACData.From
			match from:
				Location.ANCIENT_CITY_2: from_to_ac3 = WorldInfo.ACData.From.AC_PREV
				_: pass
			WorldInfo.ac_3_data.come_from = from_to_ac3
			WorldInfo.current_walking_material = "stone"
		Location.ANCIENT_CITY_2:
			var from_to_ac2: WorldInfo.ACData.From
			match from:
				Location.ANCIENT_CITY_1: 
					from_to_ac2 = WorldInfo.ACData.From.AC_PREV
				Location.ANCIENT_CITY_3: 
					from_to_ac2 = WorldInfo.ACData.From.AC_NEXT
				_: pass
			WorldInfo.ac_2_data.come_from = from_to_ac2
			WorldInfo.current_walking_material = "stone"
		Location.ANCIENT_CITY_1:
			var from_to_ac1: WorldInfo.ACData.From
			match from:
				Location.BEACH: from_to_ac1 = WorldInfo.ACData.From.BEACH
				Location.ANCIENT_CITY_2: from_to_ac1 = WorldInfo.ACData.From.AC_NEXT
				_: pass
			WorldInfo.ac_1_data.come_from = from_to_ac1
			WorldInfo.current_walking_material = "stone"
		Location.BEACH:
			var from_to_beach: WorldInfo.BeachData.From
			match from:
				Location.ANCIENT_CITY_1,\
				Location.ANCIENT_CITY_2,\
				Location.ANCIENT_CITY_3:
					from_to_beach = WorldInfo.BeachData.From.CITY
				Location.CAVE:
					from_to_beach = WorldInfo.BeachData.From.CAVE
				_: 
					from_to_beach = WorldInfo.BeachData.From.INIT
			WorldInfo.beach_data.come_from = from_to_beach
			WorldInfo.beach_data.been_before = true
			WorldInfo.current_walking_material = "sand"
		_: WorldInfo.current_walking_material = "stone"
