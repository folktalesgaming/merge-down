class_name GamePlay
extends Node2D

@onready var main_grid = %MainGrid
@onready var operator_stack = %OperatorStack

const TilePrefab = preload("res://prefabs/Tile.tscn")
const DropZonePrefab = preload("res://prefabs/DropZone.tscn")

var board: Array[Array]

func _ready():
	GameManager.board_updated.connect(on_board_updated)
	GameManager.new_operator_tile_added.connect(on_operator_tile_added)
	# Initialize a board matrix of dynamic n*n size
	# And
	# Fill the board with random large number tiles
	var board_size = GameManager.get_board_size()
	for i in range(board_size):
		var row: Array[Tile] = []
		row.resize(board_size)
		for j in range(board_size):
			row[j] = initiate_num_tile(GameManager.get_board_tile_data(i, j), i, j)			
			add_on_top_drop_zone(i, j, row[j])
			
		board.append(row)
	
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

func add_on_top_drop_zone(r: int, c: int, tile: Tile):
	var dropZone: DropZone = DropZonePrefab.instantiate()
	dropZone.type = GlobalConst.DropZone.ON_TOP
	dropZone.is_active = true
	dropZone.tiles.append(tile)
	dropZone.position = Vector2((c+1) * 100, (r+2) * 80)
	main_grid.add_child(dropZone)

# Initiate operator tile in the operator stack
func initiate_operator_tile(p: int):
	var rand_symbol = randi_range(0, GlobalConst.OperatorSymbol.size() - 2)
	var rand_type = randi_range(1, GlobalConst.OperatorType.size() - 2) 
	var rand_value = randi_range(1, 20)
	
	var tile: Tile = TilePrefab.instantiate()
	var width = get_window().size.x
	var height = get_window().size.y
	tile.position = Vector2(width - 80, height - (p+1) * 80)
	
	operator_stack.add_child(tile)
	tile.Initialize_Value(rand_value, rand_symbol, rand_type)
	tile.set_stack_pos(p)

func on_board_updated(row: int, col: int, new_val: int):
	var tile: Tile = board[row][col]
	if is_instance_valid(tile):
		tile.render_tile(new_val)

func on_operator_tile_added(removed_op_pos: int):
	for op_tile in operator_stack.get_children():
		op_tile.drop_op_tile(removed_op_pos)
	
	initiate_operator_tile(6)

func _process(_delta):
	# Add new operator tile on the operator stack
	# Or do nothing if negative hazard happens
	if GameManager._op_stack.size() < 7:
		initiate_operator_tile(6)
	
	# check for level stuck
