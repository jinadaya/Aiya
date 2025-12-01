extends Node

enum Item {
	VOICE, STONE,
}

var collected_items : Array[ Item ] = []

func collect_item(item : Item):
	if not collected_items.has(item):
		collected_items.push_back(item)

func is_item_collected(item : Item) -> bool:
	return collected_items.has(item)

func clear() -> void:
	collected_items.clear()
