extends Node

signal board_updated(row: int, col: int, new_val: int)
signal tile_cleared(row: int, col: int)
signal new_operator_tile_added(removed_op_index: int)
signal negative_hazard(s_i: int, val: int, r: int, c: int, r_i: int)
signal level_completed()

# Properties
var _board: Array[Array]
var _op_stack: Array[Dictionary]
var _board_size: int = 5
var _stack_size: int = 7
var _total: int = 0

var _lower_limit: int = 8
var _upper_limit: int = 40

# Getters and Setters

func get_board_tile_data(row: int, col: int) -> int:
	if row >= 0 and row < _board.size():
		if col >= 0 and col < _board[row].size():
			return _board[row][col]
	return 0

# Board Size
func set_board_size(b_size: int):
	_board_size = b_size

func get_board_size() -> int:
	return _board_size

# Stack Size
func set_stack_size(s_size: int):
	_stack_size = s_size

func get_stack_size() -> int:
	return _stack_size

# Board Value Limit
func set_lower_limit(l_limit: int):
	_lower_limit = l_limit

func get_lower_limit() -> int:
	return _lower_limit
	
func set_upper_limit(u_limit: int):
	_upper_limit = u_limit

func get_upper_limit() -> int:
	return _upper_limit


# CUSTOM FUNCTIONS

# Initialize board with random values
func Initialize_Board():
	_board.clear()
	_total = 0
	
	for i in range(_board_size):
		var row: Array[int] = []
		row.resize(_board_size)
		for j in range(_board_size):
			var val = randi_range(_lower_limit, _upper_limit)
			row[j] = val
			_total += val
		_board.append(row)

# Intialize stack with random operators
func Initialize_Stack():
	_op_stack.clear()
	
	for i in range(_stack_size):
		_op_stack.append(get_rand_op_data(i)) 

func get_rand_op_data(i: int, val: int = -1) -> Dictionary:
	var new_val = randi_range(1, 15)
	if val != -1:
		new_val = val
	
	return {
		value = new_val,
		symbol = randi_range(0, GlobalConst.OperatorSymbol.size() - 2),
		type = randi_range(1, GlobalConst.OperatorType.size() - 1),
		index = i,
	};

# append operator to the stack
func add_operator_tile(tile: Dictionary):
	_op_stack.append(tile)

# updating the board value
func update_board(row: int, col: int, new_value: int):
	_board[row][col] = new_value

# Consume operator to be called from tile on drop
func consume_operator(op_tile_data: Dictionary, row: int, col: int):
	var current_val: int = _board[row][col]
	var op_val: int = op_tile_data["value"]
	var op_tile_pos: int = op_tile_data["index"]
	
	var new_op_tile_created: bool = false
	
	var result: int = 0
	
	match op_tile_data["symbol"]:
		GlobalConst.OperatorSymbol.SUB:
			result = current_val - op_val
		GlobalConst.OperatorSymbol.DIVIDE:
			var rem: int = current_val % op_val
			if rem == 0:
				result = int(current_val/op_val)
			else:
				# TODO: SPLIT INSTEAD OF reminder
				result = rem
	
	if result <= 0:
		_total -= current_val
		_board[row][col] = 0
		tile_cleared.emit(row, col)
		
		if result < 0:
			new_op_tile_created = true
			var rand_index = randi_range(0, 6)
			_op_stack[rand_index] = get_rand_op_data(rand_index)
			negative_hazard.emit(rand_index, result, row, col, op_tile_pos)
	else:
		_total -= (current_val - result)
		_board[row][col] = result
		board_updated.emit(row, col, result)
	
	print(_total)
	
	if _total == 0:
		level_completed.emit()
		return
		
	if !new_op_tile_created:
		_op_stack.remove_at(op_tile_pos)
		_op_stack.append(get_rand_op_data(6))
		new_operator_tile_added.emit(op_tile_pos)
		
