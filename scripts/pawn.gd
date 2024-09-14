extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func move(destination):
	var distance = position.distance_to(destination)
	var move_tween: Tween
	move_tween = get_tree().create_tween()
	move_tween.tween_property(self, "position", destination, 0.03 * distance).from_current().set_trans(Tween.TRANS_SPRING)
