extends Node2D

var level: int = 1

func _ready():
	var game_play_scene: GamePlay = preload("res://scenes/GamePlay.tscn").instantiate()
	GameManager.set_board_size(level * 5)
	
	GameManager.set_lower_limit(8) # setting loweset number in board
	GameManager.set_upper_limit(40) # setting highest number in board
	
	GameManager.set_stack_size(7) # setting number of operator at a time
	
	# Initializing board and operator stack data
	GameManager.Initialize_Board()
	GameManager.Initialize_Stack()
	
	add_child(game_play_scene)
