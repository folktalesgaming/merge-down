extends Node2D

const TilePrefab = preload("res://prefabs/Tile.tscn")

var total: int = 1000

func _ready():
	test()
	# Initialize a board matrix of dynamic n*n size
	
	# Fill the board with random large number tiles
	
	# Initialize a stack of operators with random operator tiles
	pass

func test():
	# TESTING
	var tile: Tile = TilePrefab.instantiate()
	tile.position = Vector2(400, 300)
	add_child(tile)
	tile.init_tile(4)
	
	var tile1: Tile = TilePrefab.instantiate()
	tile1.position = Vector2(600, 400)
	add_child(tile1)
	tile1.init_tile(56)
	
	var tile2: Tile = TilePrefab.instantiate()
	tile2.position = Vector2(400, 600)
	add_child(tile2)
	tile2.init_tile(431)

func _process(_delta):
	# Wait for player selection
	
	# based on the selection operate on tiles
	
	# Add new operator tile on the operator stack
	# Or do nothing if negative hazard happens
	
	# check for game finished
	if total <= 0:
		# stop the game play and show level complete
		# model with next level or menu
		print("Level complete")
	
	# check for level stuck
