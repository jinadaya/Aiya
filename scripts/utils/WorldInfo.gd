extends Node

var current_walking_material : String = "sand"

class BeachData:
	enum From {
		INIT, CAVE, CITY
	}
	var been_before: bool = false
	var come_from: From = From.INIT

class ACData:
	enum From {
		BEACH, AC_PREV, AC_NEXT
	}
	var come_from: From = From.BEACH

var beach_data: BeachData = BeachData.new()
var ac_1_data: ACData = ACData.new()
var ac_2_data: ACData = ACData.new()
var ac_3_data: ACData = ACData.new()

func reset() -> void:
	ac_1_data = ACData.new()
	ac_2_data = ACData.new()
	ac_3_data = ACData.new()
	beach_data = BeachData.new()
	Inventory.clear()
