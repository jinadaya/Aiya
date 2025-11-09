extends CanvasLayer
class_name DialogManager

const DIALOG_PATH : StringName = "dialog_path"
const DIALOG_IS_POPUP : StringName = "is_popup"

var canvas : CanvasLayer = CanvasLayer.new()

enum GameDialogs {
	EnterCave,
	MeetEchoMonster,
	FindStone,
	EnterBeach,
	FoundGate,
	MeetOwl,
	OwlFreed,
	MeetCat,
	CatPassed,
	MeetCrow,
	MeetCreator,
}

const DETAILED_DIALOGS : Dictionary [ GameDialogs, Dictionary ] = {
	GameDialogs.EnterCave : {
		DIALOG_PATH : "",
		DIALOG_IS_POPUP : "",
	},
	GameDialogs.MeetEchoMonster : {
		DIALOG_PATH : "",
		DIALOG_IS_POPUP : "",
	},
	GameDialogs.FindStone : {
		DIALOG_PATH : "",
		DIALOG_IS_POPUP : "",
	},
	GameDialogs.EnterBeach : {
		DIALOG_PATH : "",
		DIALOG_IS_POPUP : "",
	},
	GameDialogs.FoundGate : {
		DIALOG_PATH : "",
		DIALOG_IS_POPUP : "",
	},
	GameDialogs.MeetOwl : {
		DIALOG_PATH : "",
		DIALOG_IS_POPUP : "",
	},
	GameDialogs.OwlFreed : {
		DIALOG_PATH : "",
		DIALOG_IS_POPUP : "",
	},
	GameDialogs.MeetCat : {
		DIALOG_PATH : "",
		DIALOG_IS_POPUP : "",
	},
	GameDialogs.CatPassed : {
		DIALOG_PATH : "",
		DIALOG_IS_POPUP : "",
	},
	GameDialogs.MeetCrow : {
		DIALOG_PATH : "",
		DIALOG_IS_POPUP : "",
	},
	GameDialogs.MeetCreator : {
		DIALOG_PATH : "",
		DIALOG_IS_POPUP : "",
	}
}

func _ready() -> void:
	add_child(canvas)

# Should show
func show_dialog(_position_1 : Vector2, _position_2 : Vector2, with : DialogStorage.DialogEntities):
	var dialog_path : String = DETAILED_DIALOGS[with][DIALOG_PATH]
	var is_popup : bool = DETAILED_DIALOGS[with][DIALOG_IS_POPUP]
	pass
