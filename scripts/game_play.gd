class_name GamePlay
extends Node2D

@onready var main_grid = %MainGrid
@onready var operator_stack = %OperatorStack
@onready var drop_zones = %DropZones
@onready var container = %Container
@onready var complete_heading = %CompleteHeading
@onready var next_lvl_btn = %NextLvlBtn

const TilePrefab = preload("res://prefabs/Tile.tscn")
const DropZonePrefab = preload("res://prefabs/DropZone.tscn")

var board: Array[Array]
var drop_top_zones: Array[Array]
var drop_in_zones: Array[Array]

var level: int = 1
var _board_gap: int = 90
var is_stucked: bool = false

func _ready():
	GameManager.board_updated.connect(on_board_updated)
	GameManager.new_operator_tile_added.connect(on_operator_tile_added)
	GameManager.tile_cleared.connect(on_tile_cleared)
	GameManager.negative_hazard.connect(on_negative_hazard)
	GameManager.level_completed.connect(on_level_completed)
	GameManager.level_stuck.connect(on_level_stuck)
	GameManager.in_between_tile_status_changed.connect(on_in_between_tile_status_changed)
	
	reset()
	new_game()

func reset():
	GameManager.set_board_size(level * 2)
	
	GameManager.set_lower_limit(8) # setting loweset number in board
	GameManager.set_upper_limit(40) # setting highest number in board
	
	GameManager.set_stack_size(7) # setting number of operator at a time
	
	for op_tile in operator_stack.get_children():
		op_tile.remove_tile()
	
	for child in drop_zones.get_children():
		child.queue_free()
	
	for child in main_grid.get_children():
		child.queue_free()
	
	board.clear()
	drop_in_zones.clear()
	drop_top_zones.clear()

func new_game():
	# Initializing board and operator stack data
	GameManager.Initialize_Board()
	GameManager.Initialize_Stack()
	
	var board_size = GameManager.get_board_size()
	for i in range(board_size):
		var row: Array[Tile] = []
		var zones: Array[DropZone] = []
		var in_zones: Array[DropZone] = []
		row.resize(board_size)
		zones.resize(board_size)
		for j in range(board_size):
			zones[j] = add_on_top_drop_zone(i, j)
			var between_zones = add_in_between_drop_zone(i, j)
			for b_z in between_zones:
				in_zones.append(b_z)
			row[j] = initiate_num_tile(GameManager.get_board_tile_data(i, j), i, j)
			
		board.append(row)
		drop_top_zones.append(zones)
		drop_in_zones.append(in_zones)
		GameManager._in_between_drop_zone_status.append(in_zones)
	
	# Initialize a stack of operators with random operator tiles
	for i in range(GameManager.get_stack_size()):
		initiate_operator_tile(i)

# Initiate number tile in the board
func initiate_num_tile(v: int, r: int, c: int) -> Tile:
	var tile: Tile = TilePrefab.instantiate()
	tile.position = Vector2((c+1) * _board_gap, (r+1) * _board_gap)
	main_grid.add_child(tile)
	tile.Initialize_Value(v)
	tile.set_board_pos(r, c)
	
	return tile

func add_on_top_drop_zone(r: int, c: int) -> DropZone:
	if r >= 0 and r < drop_top_zones.size() and c >= 0 and c < drop_top_zones[r].size():
		drop_top_zones[r][c].tiles.clear()
		return drop_top_zones[r][c]
	
	var dropZone: DropZone = DropZonePrefab.instantiate()
	dropZone.type = GlobalConst.DropZone.ON_TOP
	dropZone.is_active = true
	dropZone.add_board_pos(Vector2(r, c))
	dropZone.position = Vector2((c+1) * _board_gap, (r+1) * _board_gap)
	drop_zones.add_child(dropZone)
	
	return dropZone

func add_in_between_drop_zone(r: int, c: int) -> Array[DropZone]:
	var d_zones: Array[DropZone] = [];
	
	if r+1 < GameManager.get_board_size():
		var d_zone: DropZone = DropZonePrefab.instantiate()
		d_zone.type = GlobalConst.DropZone.IN_BETWEEN
		d_zone.is_active = true
		d_zone.visible = false
		d_zone.add_board_pos(Vector2(int(r), int(c)))
		d_zone.add_board_pos(Vector2(int(r + 1), int(c)))
		d_zone.scale = Vector2(0.4, 0.5)
		
		d_zone.position = Vector2((c+1) * _board_gap, (r+1.5) * _board_gap)
		drop_zones.add_child(d_zone)
		d_zones.append(d_zone)
	
	if c+1 < GameManager.get_board_size():
		var d_zone: DropZone = DropZonePrefab.instantiate()
		d_zone.type = GlobalConst.DropZone.IN_BETWEEN
		d_zone.is_active = true
		d_zone.visible = false
		if !d_zone.check_board_pos(Vector2(int(r), int(c))):
			d_zone.add_board_pos(Vector2(int(r), int(c)))
		d_zone.add_board_pos(Vector2(int(r), int(c + 1)))
		d_zone.scale = Vector2(0.5, 0.4)
		
		d_zone.position = Vector2((c+1.5) * _board_gap, (r+1) * _board_gap)
		drop_zones.add_child(d_zone)
		d_zones.append(d_zone)
		
	return d_zones

func has_decimal(n: float) -> bool:
	return abs(fmod(n, 1.0)) > 0.00001

# Initiate operator tile in the operator stack
func initiate_operator_tile(p: int):
	var tile: Tile = TilePrefab.instantiate()
	var width = get_window().size.x
	var height = get_window().size.y
	tile.position = Vector2(width - 80, height - (p+1) * 80)
	
	operator_stack.add_child(tile)
	tile.Initialize_Value(
		GameManager._op_stack[p]["value"], 
		GameManager._op_stack[p]["symbol"],
		GameManager._op_stack[p]["type"]
	)
	tile.set_stack_pos(p)

func negative_op_tile(val: int, index: int, r: int, c: int):
	var tile: Tile = TilePrefab.instantiate()
	tile.position = Vector2((c+1) * 100, (r+2) * 80)
	var width = get_window().size.x
	var height = get_window().size.y
	tile.initial_position = Vector2(width - 80, height - (index+1) * 80)
	
	operator_stack.add_child(tile)
	operator_stack.move_child(tile, index)
	tile.Initialize_Value(
		val, 
		GlobalConst.OperatorSymbol.SUB, 
		GlobalConst.OperatorType.SINGLE
	)
	tile.set_state(Tile.STATE.BACKTOIDLE)
	tile.set_stack_pos(index)

func on_board_updated(row: int, col: int, new_val: int):
	var tile: Tile = board[row][col]
	if is_instance_valid(tile):
		tile.render_tile(new_val)

func on_tile_cleared(row: int, col: int):
	var tile: Tile = board[row][col]
	drop_top_zones[row][col].is_active = false
	tile.remove_tile()

func on_operator_tile_added(removed_op_pos: int):
	for op_tile in operator_stack.get_children():
		op_tile.drop_op_tile(removed_op_pos)
	
	initiate_operator_tile(6)

func on_negative_hazard(s_i: int, val: int, r: int, c: int, r_i: int):
	var op_tile: Tile = operator_stack.get_child(s_i)
	negative_op_tile(abs(val), s_i, r, c)
	op_tile.remove_tile_by_swap()
	
	await get_tree().create_timer(0.7).timeout
	
	if s_i != r_i:
		on_operator_tile_added(r_i)

func on_in_between_tile_status_changed(r: int, c: int, s: bool):
	for i in range(drop_in_zones.size()):
		for j in range(drop_in_zones[i].size()):
			if drop_in_zones[i][j].check_board_pos(Vector2(r, c)):
				drop_in_zones[i][j].is_active = s

func on_level_completed():
	is_stucked = false
	complete_heading.text = "Level Completed"
	next_lvl_btn.text = "Next Level"
	container.visible = true

func on_level_stuck():
	is_stucked = true
	complete_heading.text = "Bad luck! You are stuck"
	next_lvl_btn.text = "Restart level"
	container.visible = true

func _process(_delta):
	# Add new operator tile on the operator stack
	# Or do nothing if negative hazard happens
	#if GameManager._op_stack.size() < 7:
		#initiate_operator_tile(6)
	#
	## check for level stuck
	pass


func _on_next_lvl_btn_pressed():
	if !is_stucked:
		level += 1
	reset()
	new_game()
	container.visible = false
