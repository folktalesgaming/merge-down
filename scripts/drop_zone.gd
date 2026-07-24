class_name DropZone
extends Area2D

@onready var color_rect = %ColorRect

var type: GlobalConst.DropZone
var is_active: bool

var board_pos: Array[Vector2]

func _ready():
	if type == GlobalConst.DropZone.IN_BETWEEN:
		#color_rect.visible = false
		self_modulate.darkened(0.4)

func add_board_pos(pos: Vector2):
	board_pos.append(pos)

func check_board_pos(pos: Vector2) -> bool:
	return board_pos.find(pos) != -1
