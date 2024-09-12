extends Node2D
@onready var board: TileMapLayer = $Board
@onready var pawn: Node2D = $Board/Pawn
@onready var highlighter: Node2D = $Board/Highlighter

signal clicked_on_board(destination)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not clicked_on_board.is_connected(pawn.move):
		clicked_on_board.connect(pawn.move)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if mouse_in_board_region():
		highlighter.position = get_global_mouse_position().snapped(Vector2(32, 16))
	
func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("lmb_click"):
		var clicked_cell = board.local_to_map(board.get_global_mouse_position())
		var destination_tile_coordinates = board.map_to_local(clicked_cell)
		var cell_data = board.get_cell_tile_data(clicked_cell)
		if cell_data:
			clicked_on_board.emit(destination_tile_coordinates)

func mouse_in_board_region():
	var cell_coordinates = board.local_to_map(board.get_global_mouse_position())
	var cell_position = board.map_to_local(cell_coordinates)
	var cell_data = board.get_cell_tile_data(cell_coordinates)
	if cell_data:
		return true
	return false
	
	
	
