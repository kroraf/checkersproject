extends Node2D
class_name Pawn
@onready var sprite_2d: Sprite2D = $Sprite2D


@export_enum("black", "white") var type: String

func _ready() -> void:
	pass # Replace with function body.

func move(destination):
	var distance = position.distance_to(destination)
	var move_tween: Tween
	move_tween = get_tree().create_tween()
	move_tween.tween_property(self, "position", destination, 0.03 * distance).from_current().set_trans(Tween.TRANS_SPRING)
	return move_tween

func _on_input_event(viewport, event, shape_idx):
	if Input.is_action_just_pressed("lmb_click"):
		Events.pawn_clicked.emit(self)
