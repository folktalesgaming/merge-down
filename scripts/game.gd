extends Node2D

var level: int = 1

func _ready():
	var game_play_scene: GamePlay = preload("res://scenes/GamePlay.tscn").instantiate()
	
	game_play_scene.board_size = level * 5
	
	add_child(game_play_scene)
