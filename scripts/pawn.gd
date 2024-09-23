extends Node2D
class_name Pawn
@onready var sprite_2d: Sprite2D = $Sprite2D

@export var is_type_black: bool

var has_just_jumped = false

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
		
func kill():
	Events.pawn_killed.emit(is_type_black)
	self.queue_free()
