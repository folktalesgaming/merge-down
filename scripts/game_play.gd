class_name GamePlay
extends Node2D

@onready var main_grid = %MainGrid
@onready var operator_stack = %OperatorStack

const TilePrefab = preload("res://prefabs/Tile.tscn")
const DropZonePrefab = preload("res://prefabs/DropZone.tscn")

var total: int = 0
var board_size: int

func _ready():
	# Initialize a board matrix of dynamic n*n size
	# And
	# Fill the board with random large number tiles
	for i in range(board_size):
		var row: Array[int] = []
		row.resize(board_size)
		for j in range(board_size):
			row[j] = randi_range(10, 50)
			total += row[j]
			var tile = initiate_num_tile(row[j], i, j)
			add_on_top_drop_zone(i, j, tile)
			
		GameManager._board.append(row)
	
	# Initialize a stack of operators with random operator tiles
	for i in range(7):
		initiate_operator_tile(i+1)

# Initiate number tile in the board
func initiate_num_tile(v: int, r: int, c: int) -> Tile:
	var tile: Tile = TilePrefab.instantiate()
	tile.position = Vector2((c+1) * 100, (r+2) * 80)
	main_grid.add_child(tile)
	tile.init_tile(v)
	
	return tile

func add_on_top_drop_zone(r: int, c: int, tile: Tile):
	var dropZone: DropZone = DropZonePrefab.instantiate()
	dropZone.type = GlobalConst.DropZone.ON_TOP
	dropZone.is_active = true
	dropZone.tiles.append(tile)
	dropZone.position = Vector2((c+1) * 100, (r+2) * 80)
	main_grid.add_child(dropZone)

# Initiate operator tile in the operator stack
func initiate_operator_tile(
	p: int, 
):
	var rand_symbol = randi_range(0, GlobalConst.OperatorSymbol.size() - 2)
	var rand_type = randi_range(1, GlobalConst.OperatorType.size() - 2) 
	var rand_value = randi_range(1, 20)
	
	var tile: Tile = TilePrefab.instantiate()
	var width = get_window().size.x
	var height = get_window().size.y
	tile.position = Vector2(width - 80, height - p * 80)
	
	operator_stack.add_child(tile)
	tile.init_tile(rand_value, rand_symbol, rand_type, p)
	
	GameManager.add_operator_tile(tile)

func _process(_delta):
	# Add new operator tile on the operator stack
	# Or do nothing if negative hazard happens
	if GameManager._op_stack.size() < 7:
		initiate_operator_tile(7)
	
	# check for game finished
	if total <= 0:
		# stop the game play and show level complete
		# model with next level or menu
		print("Level complete")
	
	# check for level stuck
