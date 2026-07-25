extends Node2D

@onready var consume_operator = %consume_operator
@onready var clear_tile = %clear_tile
@onready var button_click = %button_click

func Play_Consume_Operator_SFX():
	consume_operator.play()

func Play_Tile_Clear_SFX():
	clear_tile.play()

func Play_Button_Click_SFX():
	button_click.play()
