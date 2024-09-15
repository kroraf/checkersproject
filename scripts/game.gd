extends Node2D
@onready var board: TileMapLayer = $Board
@onready var highlighter: Node2D = $Board/Highlighter
@onready var camera_2d = $Camera2D

var base_pawn = preload("res://scenes/pawn.tscn")
var black_pawn = preload("res://scenes/black_pawn.tscn")
var white_pawn = preload("res://scenes/white_pawn.tscn")
const outline_shader = preload("res://shaders/pawn_outline.gdshader")

var cell_color = {"orange": Vector2i(0, 6), "gray": Vector2i(0, 3)}
var outline = ShaderMaterial.new()

var BLACK_PAWN_START_COORDINATES = [Vector2i(0, 0), Vector2i(0, 2), Vector2i(0, 4), Vector2i(0, 6),
									Vector2i(1, 1), Vector2i(1, 3), Vector2i(1, 5), Vector2i(1, 7)]
									
var WHITE_PAWN_START_COORDINATES = [Vector2i(6, 6), Vector2i(6, 4), Vector2i(6, 2), Vector2i(6, 0),
									Vector2i(7, 7), Vector2i(7, 5), Vector2i(7, 3), Vector2i(7, 1)]

signal clicked_on_board(destination)

var selected_pawn: Pawn = null
var possible_destination_tiles: Array[Vector2i] = []
var highlighted_tiles: Array[Vector2i] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	create_pawns()
	Events.pawn_clicked.connect(_on_pawn_clicked)
	_setup_outline_shader()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
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
		if cell_data:
			if selected_pawn and clicked_cell_coordinates in possible_destination_tiles:
				undo_highlight()
				await selected_pawn.move(clicked_cell_position).finished
				piece_move_finished()
	if Input.is_action_just_pressed("rmb_click"):
		deselect_pawn()

func mouse_in_board_region():
	var cell_coordinates = board.local_to_map(board.get_global_mouse_position())
	var cell_data = board.get_cell_tile_data(cell_coordinates)
	if cell_data:
		return true
	return false
	
func create_pawns():
	for i in BLACK_PAWN_START_COORDINATES:
		var pawn_instance = black_pawn.instantiate()
		add_child(pawn_instance, true)
		pawn_instance.position = board.map_to_local(i)
	for i in WHITE_PAWN_START_COORDINATES:
		var pawn_instance = white_pawn.instantiate()
		add_child(pawn_instance, true)
		pawn_instance.position = board.map_to_local(i)

func _on_pawn_clicked(pawn_instance: Pawn):
	if not selected_pawn:
		select_pawn(pawn_instance)
	else:
		if selected_pawn == pawn_instance:
			deselect_pawn()
		else:
			print("You cannot select {0}. A pawn is already selected".format([pawn_instance]))
		
func select_pawn(pawn: Pawn):
	print("{0}: {1}".format([pawn, board.local_to_map(pawn.position)]))
	selected_pawn = pawn
	selected_pawn.z_index = 10
	highlight_possible_movement(pawn)
	selected_pawn.sprite_2d.set_material(outline)

func deselect_pawn():
	if selected_pawn:
		selected_pawn.z_index = 0
		selected_pawn.sprite_2d.set_material(null)
		selected_pawn = null
		undo_highlight()

	
func highlight_possible_movement(pawn: Pawn):
	var pawn_coordinates: Vector2i = board.local_to_map(pawn.position)
	possible_destination_tiles.append(Vector2i(pawn_coordinates.x + 1, pawn_coordinates.y - 1))
	possible_destination_tiles.append(Vector2i(pawn_coordinates.x + 1, pawn_coordinates.y + 1))
	if pawn.type == "black":
		for i in possible_destination_tiles:
			board.set_cell(i, 0, Vector2i(0, 0))
			highlighted_tiles.append(i)
			
func undo_highlight():
	for tile in highlighted_tiles:
		board.set_cell(tile, 0, Vector2i(0, 6))
	highlighted_tiles.clear()
	possible_destination_tiles.clear()
		
func _setup_outline_shader() -> void:
	outline.set_shader(outline_shader)
	outline.set_shader_parameter("outline_color", Color("5b83c9"))
	
func piece_move_finished():
	deselect_pawn()
		
