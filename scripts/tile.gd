class_name Tile
extends Node2D

@onready var bg: Sprite2D = %Bg
@onready var num_val: Label = %NumVal

# Internal properties of tile 
var _value: int
var _symbol: GlobalConst.OperatorSymbol
var _type: GlobalConst.OperatorType

enum STATE {
	IN_STACK,
	MOVING_TO_BOARD,
	MOVING_TO_STACK,
	DROPING,
	APPEARING,
}

var _state = STATE.IN_STACK
var _tween

# public properties of tile for actions like drag and drop
var is_draggable: bool = false
var operator_tile_position: int = 0
var drop_zone: GlobalConst.DropZone = GlobalConst.DropZone.ON_TOP
var initial_position: Vector2
var is_in_drop_zone: bool = false
var drop_zone_ref: DropZone

# Generate a new tile with given value, symbol and type
func init_tile(
	v: int, 
	s: GlobalConst.OperatorSymbol = GlobalConst.OperatorSymbol.NONE, 
	t: GlobalConst.OperatorType = GlobalConst.OperatorType.NUM,
	p: int = 0
):
	_value = v
	_symbol = s
	_type = t
	operator_tile_position = p
	
	var to_add_val = "" 
	if _symbol == GlobalConst.OperatorSymbol.SUB:
		to_add_val =  "-"
	if _symbol == GlobalConst.OperatorSymbol.DIVIDE:
		to_add_val =  "/"
	
	if _type != GlobalConst.OperatorType.MULTI:
		to_add_val = to_add_val + str(_value)
	num_val.text = to_add_val
	
	if _type == GlobalConst.OperatorType.NUM:
		var rng := RandomNumberGenerator.new()
		rng.seed = _value
		bg.self_modulate = Color(rng.randf(), rng.randf(), rng.randf(), 1)
		
		is_draggable = false
	else:
		if _type == GlobalConst.OperatorType.SINGLE:
			drop_zone = GlobalConst.DropZone.ON_TOP
			bg.self_modulate = Color(0.4, 0.45, 0.35, 1)
		elif _type == GlobalConst.OperatorType.MULTI:
			drop_zone = GlobalConst.DropZone.IN_BETWEEN
			bg.self_modulate = Color(0.8, 0.3, 0.2, 1)

# Operate on the tile with given value and symbol
func operate(val: int, sym: GlobalConst.OperatorSymbol):
	if sym == GlobalConst.OperatorSymbol.SUB:
		_value -= val
	elif sym == GlobalConst.OperatorSymbol.DIVIDE:
		var newValue: float = _value % val
		# if there is no reminder
		if newValue == 0:
			_value /= val
		else:
			# else split tile
			pass
	
	num_val.text = str(_value)
	
	if _value <= 0:
		if _value < 0:
			# Change the 4th or 5th in line operator tile
			# with this tile
			pass
			
		# destroy the tile

func _process(delta):
	if is_draggable:
		if Input.is_action_just_pressed("click"):
			scale = Vector2(.7, .7)
		if Input.is_action_pressed("click"):
			_state = STATE.MOVING_TO_BOARD
			if !DragHelper.picked_operator_tile:
				DragHelper.change_picked_tile(self)
			global_position = lerp(global_position, get_global_mouse_position(), 65 * delta)
		if Input.is_action_just_released("click"):
			check_drop()
	match _state:
		STATE.MOVING_TO_STACK:
			tween_position(STATE.IN_STACK, 0.4, initial_position)
		STATE.DROPING:
			tween_position(STATE.IN_STACK, 0.3, Vector2(self.position.x, self.position.y + 80))

# change state to droping if operator below it is removed
func drop_operator_tile(last_operator_pos: int):
	if last_operator_pos < operator_tile_position:
		operator_tile_position -= 1
		_state = STATE.DROPING

# animating the position of tile with tween
func tween_position(next_state: STATE, tween_time: float, target_position: Vector2):
	if _tween:
		_tween.kill()
		
	_tween = create_tween()
	_tween.set_ease(Tween.EASE_IN_OUT)
	_tween.set_trans(Tween.TRANS_CUBIC)
	#_tween.set_parallel(true)
	
	_tween.tween_property($".", "position", target_position, tween_time).from(self.position)
	
	_state = next_state

# checking if the operator tile is able to be droped or not
func check_drop():
	scale = Vector2(1, 1)
	is_draggable = false
	
	if is_in_drop_zone && drop_zone_ref:
		if drop_zone_ref.type == GlobalConst.DropZone.ON_TOP:
			var tile: Tile = drop_zone_ref.tiles[0]
			tile.operate(_value, _symbol)
			
			GameManager.consume_operator(self)
		elif drop_zone_ref.type == GlobalConst.DropZone.IN_BETWEEN:
			pass
	else:
		_state = STATE.MOVING_TO_STACK
	
	DragHelper.remove_picked_tile()

# on mouse enter in drag area 2D
func _on_drag_area_mouse_entered():
	if !DragHelper.picked_operator_tile && operator_tile_position > 0 && operator_tile_position < 4:
		initial_position = self.position
		is_draggable = true

# on area entered inside the drop zone
func _on_drag_area_area_entered(area):
	if _type != GlobalConst.OperatorType.NUM:
		if area is DropZone:
			if area.type == drop_zone && area.is_active:
				is_in_drop_zone = true
				drop_zone_ref = area

# on mouse exit the drag area 2D
func _on_drag_area_mouse_exited():
	if !DragHelper.picked_operator_tile:
		is_draggable = false

# on area exited the drop zone
func _on_drag_area_area_exited(area):
	if area == drop_zone_ref:
		is_in_drop_zone = false
		drop_zone_ref = null
