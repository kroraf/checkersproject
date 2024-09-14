extends Node2D
@onready var board: TileMapLayer = $Board
@onready var highlighter: Node2D = $Board/Highlighter

var base_pawn = preload("res://scenes/pawn.tscn")

var cell_color = {"orange": Vector2i(0, 6), "gray": Vector2i(0, 3)}

signal clicked_on_board(destination)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	var piece_instance = base_pawn.instantiate()
	add_child(piece_instance, true)
	piece_instance.position = board.map_to_local(Vector2i(0, 0))
	if not clicked_on_board.is_connected(piece_instance.move):
		clicked_on_board.connect(piece_instance.move)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	#if mouse_in_board_region():
		#var clicked_cell_coordinates = board.local_to_map(board.get_global_mouse_position())
		#var cell_data = board.get_cell_tile_data(clicked_cell_coordinates)
		#if cell_data and board.get_cell_atlas_coords(clicked_cell_coordinates) == cell_color["orange"]: 
			#highlighter.position = get_global_mouse_position().snapped(Vector2(32, 16))
	
func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("lmb_click"):
		var clicked_cell_coordinates = board.local_to_map(board.get_global_mouse_position())
		var clicked_cell_position = board.map_to_local(clicked_cell_coordinates)
		var cell_data = board.get_cell_tile_data(clicked_cell_coordinates)
		if cell_data and board.get_cell_atlas_coords(clicked_cell_coordinates) == cell_color["orange"]:
			clicked_on_board.emit(clicked_cell_position)

func mouse_in_board_region():
	var cell_coordinates = board.local_to_map(board.get_global_mouse_position())
	var cell_position = board.map_to_local(cell_coordinates)
	var cell_data = board.get_cell_tile_data(cell_coordinates)
	if cell_data:
		return true
	return false
	
	
	
