extends Node2D

func _on_start_pressed():
	GameManager.set_board_size(3)
	AudioManager.Play_Button_Click_SFX()
	get_tree().change_scene_to_file("res://scenes/GamePlay.tscn")

func _on_tutorial_pressed():
	GameManager.set_board_size(2)
	AudioManager.Play_Button_Click_SFX()
	get_tree().change_scene_to_file("res://scenes/Tutorial.tscn")
