class_name GamePlay
extends Node2D

@onready var main_grid = %MainGrid
@onready var operator_stack = %OperatorStack
@onready var container = %Container

const TilePrefab = preload("res://prefabs/Tile.tscn")
const DropZonePrefab = preload("res://prefabs/DropZone.tscn")

var board: Array[Array]
var drop_zones: Array[Array]

var level: int = 1

func _ready():
	GameManager.board_updated.connect(on_board_updated)
	GameManager.new_operator_tile_added.connect(on_operator_tile_added)
	GameManager.tile_cleared.connect(on_tile_cleared)
	GameManager.negative_hazard.connect(on_negative_hazard)
	GameManager.level_completed.connect(on_level_completed)
	
	reset()
	new_game()

func reset():
	GameManager.set_board_size(level * 2)
	
	GameManager.set_lower_limit(8) # setting loweset number in board
	GameManager.set_upper_limit(40) # setting highest number in board
	
	GameManager.set_stack_size(7) # setting number of operator at a time
	
	for op_tile in operator_stack.get_children():
		op_tile.remove_tile()
	
	for child in main_grid.get_children():
		child.queue_free()
	
	board.clear()
	drop_zones.clear()

func new_game():
	# Initializing board and operator stack data
	GameManager.Initialize_Board()
	GameManager.Initialize_Stack()
	
	var board_size = GameManager.get_board_size()
	for i in range(board_size):
		var row: Array[Tile] = []
		var zones: Array[DropZone] = []
		row.resize(board_size)
		zones.resize(board_size)
		for j in range(board_size):
			row[j] = initiate_num_tile(GameManager.get_board_tile_data(i, j), i, j)
			zones[j] = add_on_top_drop_zone(i, j, row[j])
			
		board.append(row)
		drop_zones.append(zones)
	
	# Initialize a stack of operators with random operator tiles
	for i in range(GameManager.get_stack_size()):
		initiate_operator_tile(i)

# Initiate number tile in the board
func initiate_num_tile(v: int, r: int, c: int) -> Tile:
	var tile: Tile = TilePrefab.instantiate()
	tile.position = Vector2((c+1) * 100, (r+2) * 80)
	main_grid.add_child(tile)
	tile.Initialize_Value(v)
	tile.set_board_pos(r, c)
	
	return tile

func add_on_top_drop_zone(r: int, c: int, tile: Tile) -> DropZone:
	if r >= 0 and r < drop_zones.size() and c >= 0 and c < drop_zones[r].size():
		drop_zones[r][c].tiles.clear()
		drop_zones[r][c].tiles.append(tile)
		return drop_zones[r][c]
	
	var dropZone: DropZone = DropZonePrefab.instantiate()
	dropZone.type = GlobalConst.DropZone.ON_TOP
	dropZone.is_active = true
	dropZone.tiles.append(tile)
	dropZone.board_pos = Vector2(r, c)
	dropZone.position = Vector2((c+1) * 100, (r+2) * 80)
	main_grid.add_child(dropZone)
	
	return dropZone

# Initiate operator tile in the operator stack
func initiate_operator_tile(p: int, val: int = 0):
	var rand_symbol = randi_range(0, GlobalConst.OperatorSymbol.size() - 2)
	var rand_type = randi_range(1, GlobalConst.OperatorType.size() - 2) 
	var rand_value = randi_range(1, 20)
	
	if val != 0:
		rand_symbol = GlobalConst.OperatorSymbol.SUB
		rand_type = GlobalConst.OperatorType.SINGLE
		rand_value = val
	
	var tile: Tile = TilePrefab.instantiate()
	var width = get_window().size.x
	var height = get_window().size.y
	tile.position = Vector2(width - 80, height - (p+1) * 80)
	
	operator_stack.add_child(tile)
	tile.Initialize_Value(rand_value, rand_symbol, rand_type)
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
	drop_zones[row][col].is_active = false
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

func on_level_completed():
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
	level += 1
	reset()
	new_game()
	container.visible = false
