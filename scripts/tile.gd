class_name Tile
extends Node2D

@onready var bg: Sprite2D = %Bg
@onready var num_val: Label = %NumVal

var value: int
var symbol: GlobalConst.OperatorSymbol
var type: GlobalConst.OperatorType

# Generate a new tile with given value, symbol and type
func init_tile(
	v: int, 
	s: GlobalConst.OperatorSymbol = GlobalConst.OperatorSymbol.NONE, 
	t: GlobalConst.OperatorType = GlobalConst.OperatorType.NUM
):
	value = v
	symbol = s
	type = t
	
	var to_add_val = "" 
	if symbol == GlobalConst.OperatorSymbol.SUB:
		to_add_val =  "-"
	if symbol == GlobalConst.OperatorSymbol.DIVIDE:
		to_add_val =  "/"
	
	if type != GlobalConst.OperatorType.MULTI:
		to_add_val = to_add_val + str(value)
	num_val.text = to_add_val
	
	if type == GlobalConst.OperatorType.NUM:
		var rng := RandomNumberGenerator.new()
		rng.seed = value
		bg.self_modulate = Color(rng.randf(), rng.randf(), rng.randf(), 1)
	elif type == GlobalConst.OperatorType.SINGLE:
		bg.self_modulate = Color(0.4, 0.45, 0.35, 1)
	elif type == GlobalConst.OperatorType.MULTI:
		bg.self_modulate = Color(0.8, 0.3, 0.2, 1)

# Operate on the tile with given value and symbol
func operate(val: int, sym: GlobalConst.OperatorSymbol):
	if sym == GlobalConst.OperatorSymbol.SUB:
		value -= val
	elif sym == GlobalConst.OperatorSymbol.DIVIDE:
		var newValue: float = value % val
		# if there is no reminder
		if newValue == 0:
			value /= val
		else:
			# else split tile
			pass
	
	if value <= 0:
		if value < 0:
			# Change the 4th or 5th in line operator tile
			# with this tile
			pass
			
		# destroy the tile
