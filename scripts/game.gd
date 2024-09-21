extends Node2D
@onready var board: TileMapLayer = $Board
@onready var highlighter: Node2D = $Board/Highlighter
@onready var camera_2d = $Camera2D
@onready var white_pawn_container = $WhitePawnContainer
@onready var black_pawn_container = $BlackPawnContainer
@onready var turn_indicator = $UI/TurnIndicator

var TURN_MANAGER = preload("res://TurnManager.tres")

var base_pawn = preload("res://scenes/pawn.tscn")
var black_pawn = preload("res://scenes/black_pawn.tscn")
var white_pawn = preload("res://scenes/white_pawn.tscn")
const outline_shader = preload("res://shaders/pawn_outline.gdshader")

static var green_tile: Vector2i =  Vector2i(0, 0)
static var orange_tile: Vector2i =  Vector2i(0, 6)
static var BLACKS_MOVEMENT_DIR: int = 1
static var WHITES_MOVEMENT_DIR: int = -1

var BLACK_PAWN_START_COORDINATES = [Vector2i(0, 0), Vector2i(0, 2), Vector2i(0, 4), Vector2i(0, 6),
									Vector2i(1, 1), Vector2i(1, 3), Vector2i(1, 5), Vector2i(1, 7)]
									
var WHITE_PAWN_START_COORDINATES = [Vector2i(6, 6), Vector2i(6, 4), Vector2i(6, 2), Vector2i(6, 0),
									Vector2i(7, 7), Vector2i(7, 5), Vector2i(7, 3), Vector2i(7, 1)]

signal jumped_over(coordinates)

var cell_color = {"orange": Vector2i(0, 6), "gray": Vector2i(0, 3)}
var black_score: int = 0
var white_score: int = 0

var selected_pawn: Pawn = null
var destination_tiles: Array[Vector2i] = []
var outline = ShaderMaterial.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	create_pawns()
	Events.pawn_clicked.connect(_on_pawn_clicked)
	Events.pawn_killed.connect(_on_pawn_killed)
	TURN_MANAGER.black_turn_started.connect(_on_black_turn_started)
	TURN_MANAGER.white_turn_started.connect(_on_white_turn_started)
	_setup_outline_shader()
	jumped_over.connect(_on_jumped_over)
	black_score = get_tree().get_node_count_in_group("Black")
	white_score = get_tree().get_node_count_in_group("White")
	TURN_MANAGER.turn = TURN_MANAGER.BLACK_TURN
	

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("lmb_click"):
		if selected_pawn:
			_move_to_clicked_cell()
	if Input.is_action_just_pressed("rmb_click"):
		deselect_pawn()
	
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
	if TURN_MANAGER.turn == TURN_MANAGER.BLACK_TURN:
		if pawn_instance.is_in_group("White"):
			return
	else:
		if pawn_instance.is_in_group("Black"):
			return
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
	if not is_jump_possible(selected_pawn):
		switch_turns()
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
				
func get_pawn_on_coordinates(coordinates: Vector2i):
	var all_pawn_instances = black_pawn_container.get_children() + white_pawn_container.get_children()
	for p in all_pawn_instances:
		var current_pawn_coordinates = board.local_to_map(p.position)
		if current_pawn_coordinates  == coordinates:
			return p

func _on_jumped_over(coordinates):
	var pawn_for_removal = get_pawn_on_coordinates(coordinates)
	pawn_for_removal.kill()
	
func jumped_over_tile(start_coordinates: Vector2i, end_coordinates: Vector2i):
	var distance = end_coordinates.x - start_coordinates.x
	if abs(distance) > 1:
		if is_movement_left(start_coordinates, end_coordinates):
			return Vector2(start_coordinates.x + distance/2,  start_coordinates.y - 1)
		else:
			return Vector2(start_coordinates.x + distance/2,  start_coordinates.y + 1)
	return false
	
func is_movement_left(start_coordinates: Vector2i, end_coordinates: Vector2i):
	if end_coordinates.y - start_coordinates.y < 0:
		return true

func _on_pawn_killed(is_type_black: bool):
	if is_type_black:
		black_score -= 1
	else:
		white_score -= 1

func _on_black_turn_started():
	turn_indicator.text = "Turn: BLACK"
	if black_score <= 0:
		print("Blacks lost")
		get_tree().quit()
	
func _on_white_turn_started():
	turn_indicator.text = "Turn: WHITE"
	if white_score <= 0:
		print("Whites lost")
		get_tree().quit()
	
func switch_turns():
	match TURN_MANAGER.turn:
		TURN_MANAGER.BLACK_TURN:
			TURN_MANAGER.turn = TURN_MANAGER.WHITE_TURN
		TURN_MANAGER.WHITE_TURN:
			TURN_MANAGER.turn = TURN_MANAGER.BLACK_TURN
			
func _move_to_clicked_cell():
	var clicked_cell_coordinates = board.local_to_map(board.get_global_mouse_position())
	var clicked_cell_position = board.map_to_local(clicked_cell_coordinates)
	var cell_data = board.get_cell_tile_data(clicked_cell_coordinates)
	if cell_data:
		if clicked_cell_coordinates in destination_tiles:
			var selected_pawn_star_coordinates = board.local_to_map(selected_pawn.position)
			clear_destination_tiles()
			await selected_pawn.move(clicked_cell_position).finished
			var jump = jumped_over_tile(selected_pawn_star_coordinates, clicked_cell_coordinates)
			if jump:
				jumped_over.emit(jump)
			piece_move_finished()
			
func is_movement_possible(pawn: Pawn):
	calculate_possible_movement(pawn)
	if destination_tiles:
		return true
	else:
		return false
		
func get_initial_movement_coordinates(pawn: Pawn) -> Array:
	var pawn_coordinates: Vector2i = board.local_to_map(pawn.position)
	var pottential_movement_tiles: Array[Vector2i]
	if pawn.is_type_black:
		pottential_movement_tiles.append(Vector2i(pawn_coordinates.x + BLACKS_MOVEMENT_DIR, pawn_coordinates.y - 1))
		pottential_movement_tiles.append(Vector2i(pawn_coordinates.x + BLACKS_MOVEMENT_DIR, pawn_coordinates.y + 1))
	else:
		pottential_movement_tiles.append(Vector2i(pawn_coordinates.x + WHITES_MOVEMENT_DIR, pawn_coordinates.y - 1))
		pottential_movement_tiles.append(Vector2i(pawn_coordinates.x + WHITES_MOVEMENT_DIR, pawn_coordinates.y + 1))
	return pottential_movement_tiles
	
func is_jump_possible(pawn: Pawn):
	var pawn_coordinates: Vector2 = board.local_to_map(pawn.position)
	var potenatial_movement_tiles = get_initial_movement_coordinates(pawn)
	for tile in potenatial_movement_tiles:
		if tile in board.get_used_cells():
			if is_tile_occupied(tile):
				if is_opponent_pawn_on_coordinates(tile):
					var jump_coordinates: Vector2i
					if pawn.is_type_black:
						jump_coordinates = Vector2i(tile.x + BLACKS_MOVEMENT_DIR, tile.y + (tile.y - pawn_coordinates.y))
					else:
						jump_coordinates = Vector2i(tile.x + WHITES_MOVEMENT_DIR, tile.y + (tile.y - pawn_coordinates.y))
					if jump_coordinates in board.get_used_cells() and not is_tile_occupied(jump_coordinates):
						return true
	return false
