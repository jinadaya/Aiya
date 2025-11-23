extends Node

enum Location {
	BEACH, CAVE, ANCIENT_CITY_1,
	ANCIENT_CITY_2, ANCIENT_CITY_3,
	LIGHTHOUSE
}

var LocPath : Dictionary [ Location, StringName ] = {
	Location.BEACH : &"",
	Location.CAVE : &"",
	Location.ANCIENT_CITY_1 : &"",
	Location.ANCIENT_CITY_2 : &"",
	Location.ANCIENT_CITY_3 : &"",
	Location.LIGHTHOUSE : &"",
}

func go(from : Location, to: Location):
	pass
