class_name Tile
extends Node2D

# On ready variable
@onready var bg: Sprite2D = %Bg
@onready var num_val: Label = %NumVal
@onready var animation_player = %AnimationPlayer


# PROPERTIES

# CORE
var _value: int
var _symbol: GlobalConst.OperatorSymbol = GlobalConst.OperatorSymbol.NONE
var _type: GlobalConst.OperatorType = GlobalConst.OperatorType.NUM

# EXTRA
var _tween: Tween
enum STATE {
	IDLE,
	DRAGGING,
	BACKTOIDLE,
	DROPPING,
	APPEARING,
	DESTROYING
}
var _state: STATE = STATE.APPEARING

# Drag related properties
var is_draggable: bool = false
var drop_zone_type: GlobalConst.DropZone
var drop_zone_ref
var initial_position: Vector2
var is_in_drop_zone: bool = false

# Position related data
var stack_pos: int = -1
var board_row: int = -1
var board_col: int = -1

# in built functions
func _ready():
	bg.material = bg.material.duplicate()

func _process(delta):
	if is_draggable:
		if Input.is_action_just_pressed("click"):
			scale = Vector2(.7, .7)
		if Input.is_action_pressed("click"):
			_state = STATE.DRAGGING
			if !DragHelper.picked_operator_tile:
				DragHelper.change_picked_tile(self)
			global_position = lerp(global_position, get_global_mouse_position(), 65 * delta)
		if Input.is_action_just_released("click"):
			check_drop()
	match _state:
		STATE.IDLE:
			pass
		STATE.BACKTOIDLE:
			tween_pos(initial_position, 0.4)
			_state = STATE.IDLE
		STATE.DROPPING:
			tween_pos(Vector2(self.position.x, self.position.y + 80), 0.3)
			_state = STATE.IDLE
		STATE.APPEARING:
			animation_player.play("appear")
			_state = STATE.IDLE

# Custom Functions

# Render the data in scene
func render_tile(val: int):
	var to_add_val = "" 
	
	if _symbol == GlobalConst.OperatorSymbol.SUB:
		to_add_val =  "-"
	if _symbol == GlobalConst.OperatorSymbol.DIVIDE:
		to_add_val =  "/"
	
	if _type != GlobalConst.OperatorType.MULTI:
		to_add_val = to_add_val + str(val)
	num_val.text = to_add_val
	
	if _type == GlobalConst.OperatorType.NUM:
		var rng := RandomNumberGenerator.new()
		rng.seed = val
		set_sprite_color(Color(rng.randf(), rng.randf(), rng.randf(), 1))
		
		is_draggable = false
	else:
		if _type == GlobalConst.OperatorType.SINGLE:
			drop_zone_type = GlobalConst.DropZone.ON_TOP
			set_sprite_color(Color(0.4, 0.45, 0.35, 1))
		elif _type == GlobalConst.OperatorType.MULTI:
			drop_zone_type = GlobalConst.DropZone.IN_BETWEEN
			set_sprite_color(Color(0.8, 0.3, 0.2, 1))

# initializing the values
func Initialize_Value(
	val: int, 
	symbol: GlobalConst.OperatorSymbol = GlobalConst.OperatorSymbol.NONE,
	type: GlobalConst.OperatorType = GlobalConst.OperatorType.NUM
):
	_value = val
	_symbol = symbol
	_type = type
	
	render_tile(val)

func set_stack_pos(s_pos: int):
	stack_pos = s_pos

func set_board_pos(r: int, c: int):
	board_row = r
	board_col = c

func set_sprite_color(new_color: Color) -> void:
	if bg.material is ShaderMaterial:
		bg.material.set_shader_parameter("tile_color", new_color)

func set_state(new_state: STATE):
	_state = new_state
	
# function to tween position of the opertor tile
func tween_pos(
	target_position: Vector2, 
	tween_duration: float
):
	if _tween:
		_tween.kill()
	
	_tween = create_tween()
	_tween.set_ease(Tween.EASE_IN_OUT)
	_tween.set_trans(Tween.TRANS_CUBIC)
	
	_tween.tween_property($".", "position", target_position, tween_duration)\
		.from(self.position)

# tween dropping the tile
func drop_op_tile(removed_op_index: int):
	if removed_op_index < stack_pos:
		stack_pos -= 1
		_state = STATE.DROPPING
#
#func drop_op_tile_negative(removed_i: int, swap_i: int):
	#if swap_i < removed_i:
		#pass
	#else:
		#drop_op_tile(removed_i)

## Check if the current Opertator Tile can be droped or not
func check_drop():
	scale = Vector2(1, 1)
	is_draggable = false
	
	if is_in_drop_zone && drop_zone_ref:
		if drop_zone_ref.type == GlobalConst.DropZone.ON_TOP && drop_zone_ref.is_active:
			var tile: Tile = drop_zone_ref.tiles[0]
			
			GameManager.consume_operator({
				value = self._value,
				symbol = self._symbol,
				type = self._type,
				index = self.stack_pos
			}, tile.board_row, tile.board_col)
			DragHelper.remove_picked_tile()
			remove_tile()
		elif drop_zone_ref.type == GlobalConst.DropZone.IN_BETWEEN:
			_state = STATE.BACKTOIDLE
			DragHelper.remove_picked_tile()
			pass
	else:
		_state = STATE.BACKTOIDLE
		DragHelper.remove_picked_tile()
	
func remove_tile():
	animation_player.play("destroy")
	
	await get_tree().create_timer(.4).timeout
	queue_free()

func remove_tile_by_swap():
	tween_pos(Vector2(self.position.x + 60, self.position.y), 0.4)
	
	await get_tree().create_timer(.8).timeout
	queue_free()

## On Mouse Entering the Drag Area (Area2D)
func _on_drag_area_mouse_entered():
	if !DragHelper.picked_operator_tile\
		 && stack_pos >= 0 && stack_pos < 3\
		 && _state == STATE.IDLE:
		initial_position = self.position
		is_draggable = true
		scale = Vector2(.7, .7)

## On Mouse Exit the Drag Area (Area2D)
func _on_drag_area_mouse_exited():
	if !DragHelper.picked_operator_tile:
		is_draggable = false
		scale = Vector2(1, 1)

## On Drag Area entered inside the drop zone
func _on_drag_area_area_entered(area):
	if _type != GlobalConst.OperatorType.NUM:
		if area is DropZone:
			if area.type == drop_zone_type && area.is_active:
				is_in_drop_zone = true
				drop_zone_ref = area

## On Drag Area exited the drop zone
func _on_drag_area_area_exited(area):
	if area == drop_zone_ref:
		is_in_drop_zone = false
		drop_zone_ref = null
