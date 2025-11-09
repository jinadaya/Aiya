extends Node

enum CollisionLayer {
	PLAYER,
	PLATFORM,
	OBSTACLE,
	VOICE,
	STONE,
	CREATURE,
	MECH,
}

func layer_for(layer : CollisionLayer) -> int:
	return 1 << int(layer)

func get_mask_for_layer(layer : CollisionLayer) -> int:
	var res : int = 0
	match layer:
		CollisionLayer.PLAYER :
			res |= layer_for(CollisionLayer.PLATFORM)
			res |= layer_for(CollisionLayer.OBSTACLE)
		
		CollisionLayer.PLATFORM :
			res |= layer_for(CollisionLayer.PLAYER)
		
		CollisionLayer.OBSTACLE:
			res |= layer_for(CollisionLayer.PLAYER)
		
		CollisionLayer.VOICE :
			res |= layer_for(CollisionLayer.PLATFORM)
			res |= layer_for(CollisionLayer.CREATURE)
		
		CollisionLayer.STONE :
			res |= layer_for(CollisionLayer.MECH)
		
		CollisionLayer.CREATURE : pass
		
		CollisionLayer.MECH : pass
		
		_ : pass
	return res
	
