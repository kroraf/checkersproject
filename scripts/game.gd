extends Node2D
@onready var board: TileMapLayer = $Board
@onready var highlighter: Node2D = $Board/Highlighter
@onready var camera_2d = $Camera2D
@onready var white_pawn_container = $WhitePawnContainer
@onready var black_pawn_container = $BlackPawnContainer

var base_pawn = preload("res://scenes/pawn.tscn")
var black_pawn = preload("res://scenes/black_pawn.tscn")
var white_pawn = preload("res://scenes/white_pawn.tscn")
const outline_shader = preload("res://shaders/pawn_outline.gdshader")

var cell_color = {"orange": Vector2i(0, 6), "gray": Vector2i(0, 3)}

static var green_tile: Vector2i =  Vector2i(0, 0)
static var orange_tile: Vector2i =  Vector2i(0, 6)
static var BLACKS_MOVEMENT_DIR: int = 1
static var WHITES_MOVEMENT_DIR: int = -1

var BLACK_PAWN_START_COORDINATES = [Vector2i(0, 0), Vector2i(0, 2), Vector2i(0, 4), Vector2i(0, 6),
									Vector2i(1, 1), Vector2i(1, 3), Vector2i(1, 5), Vector2i(1, 7)]
									
var WHITE_PAWN_START_COORDINATES = [Vector2i(6, 6), Vector2i(6, 4), Vector2i(6, 2), Vector2i(6, 0),
									Vector2i(7, 7), Vector2i(7, 5), Vector2i(7, 3), Vector2i(7, 1)]

signal jumped_over(coordinates)

var selected_pawn: Pawn = null
var destination_tiles: Array[Vector2i] = []
var outline = ShaderMaterial.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	create_pawns()
	Events.pawn_clicked.connect(_on_pawn_clicked)
	_setup_outline_shader()
	jumped_over.connect(_on_jumped_over)
	
func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("lmb_click"):
		var clicked_cell_coordinates = board.local_to_map(board.get_global_mouse_position())
		var clicked_cell_position = board.map_to_local(clicked_cell_coordinates)
		var cell_data = board.get_cell_tile_data(clicked_cell_coordinates)
		if cell_data:
			if selected_pawn and clicked_cell_coordinates in destination_tiles:
				var selected_pawn_star_coordinates = board.local_to_map(selected_pawn.position)
				clear_destination_tiles()
				await selected_pawn.move(clicked_cell_position).finished
				if is_jump(selected_pawn_star_coordinates, clicked_cell_coordinates):
					jumped_over.emit(clicked_cell_coordinates)
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
		black_pawn_container.add_child(pawn_instance, true)
		pawn_instance.position = board.map_to_local(i)
	for i in WHITE_PAWN_START_COORDINATES:
		var pawn_instance = white_pawn.instantiate()
		white_pawn_container.add_child(pawn_instance, true)
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
	selected_pawn = pawn
	selected_pawn.z_index = 10
	calculate_possible_movement(pawn)
	selected_pawn.sprite_2d.set_material(outline)

func deselect_pawn():
	if selected_pawn:
		selected_pawn.z_index = 0
		selected_pawn.sprite_2d.set_material(null)
		selected_pawn = null
		clear_destination_tiles()

	
func calculate_possible_movement(pawn: Pawn):
	var pawn_coordinates: Vector2 = board.local_to_map(pawn.position)
	var tiles_to_check: Array[Vector2i]
	if pawn.is_type_black:
		tiles_to_check.append(Vector2i(pawn_coordinates.x + BLACKS_MOVEMENT_DIR, pawn_coordinates.y - 1))
		tiles_to_check.append(Vector2i(pawn_coordinates.x + BLACKS_MOVEMENT_DIR, pawn_coordinates.y + 1))
	else:
		tiles_to_check.append(Vector2i(pawn_coordinates.x + WHITES_MOVEMENT_DIR, pawn_coordinates.y - 1))
		tiles_to_check.append(Vector2i(pawn_coordinates.x + WHITES_MOVEMENT_DIR, pawn_coordinates.y + 1))
	for tile_coodinates in tiles_to_check:
		if tile_coodinates in board.get_used_cells():
			if is_tile_occupied(tile_coodinates):
				if is_opponent_pawn_on_coordinates(tile_coodinates):
					var jump_coordinates: Vector2i
					if pawn.is_type_black:
						jump_coordinates = Vector2i(tile_coodinates.x + BLACKS_MOVEMENT_DIR, tile_coodinates.y + (tile_coodinates.y - pawn_coordinates.y))
					else:
						jump_coordinates = Vector2i(tile_coodinates.x + WHITES_MOVEMENT_DIR, tile_coodinates.y + (tile_coodinates.y - pawn_coordinates.y))
					if jump_coordinates in board.get_used_cells() and not is_tile_occupied(jump_coordinates):
						board.set_cell(jump_coordinates, 0, green_tile)
						destination_tiles.append(jump_coordinates)
			else:
				board.set_cell(tile_coodinates, 0, green_tile)
				destination_tiles.append(tile_coodinates)

			
func clear_destination_tiles():
	for tile in destination_tiles:
		board.set_cell(tile, 0, orange_tile)
	destination_tiles.clear()
		
func _setup_outline_shader() -> void:
	outline.set_shader(outline_shader)
	outline.set_shader_parameter("outline_color", Color("5b83c9"))
	
func piece_move_finished():
	deselect_pawn()
	
func is_tile_occupied(tile_coordinates):
	var all_pawn_instances = black_pawn_container.get_children() + white_pawn_container.get_children()
	for p in all_pawn_instances:
		if board.local_to_map(p.position) == tile_coordinates:
			return true

func is_opponent_pawn_on_coordinates(coordinates):
	var all_pawn_instances = black_pawn_container.get_children() + white_pawn_container.get_children()
	for p in all_pawn_instances:
		if board.local_to_map(p.position) == coordinates:
			if p.is_type_black != selected_pawn.is_type_black:
				return true

func _on_jumped_over(coordinates):
	print("HOPS!")
	
func is_jump(start_coordinates: Vector2i, end_coordinates: Vector2i):
	if abs(end_coordinates.x - start_coordinates.x) > 1:
		return true
