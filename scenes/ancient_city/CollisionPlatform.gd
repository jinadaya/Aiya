extends CollisionObject2D
class_name PlatformMask

func _ready() -> void:
	collision_layer = CollisionMaskStorage.layer_for(CollisionMaskStorage.CollisionLayer.PLATFORM)
	collision_mask = CollisionMaskStorage.get_mask_for_layer(CollisionMaskStorage.CollisionLayer.PLATFORM)
