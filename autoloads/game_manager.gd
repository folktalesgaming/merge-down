extends Node

signal board_updated(row: int, col: int, new_val: int)
signal tile_cleared(row: int, col: int)
signal new_operator_tile_added(removed_op_index: int)

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
	return _board[row][col]

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
	for i in range(_board_size):
		var row: Array[int] = []
		row.resize(_board_size)
		for j in range(_board_size):
			var val = randi_range(_lower_limit, _upper_limit)
			row[j] = val
		_board.append(row)

# Intialize stack with random operators
func Initialize_Stack():
	for i in range(_stack_size):
		_op_stack.append(get_rand_op_data(i)) 

func get_rand_op_data(i) -> Dictionary:
	return {
		value = randi_range(1, 15),
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
	else:
		_total -= (current_val - result)
		_board[row][col] = result
		board_updated.emit(row, col, result)
	
	_op_stack.remove_at(op_tile_pos)
	
	if _total == 0:
		print("Game Completed")
		pass
	else:
		_op_stack.append(get_rand_op_data(6))
		new_operator_tile_added.emit(op_tile_pos)
		

# Swap operator
func swap_operator_negative(swap_index: int, op_title_data: Dictionary):
	_op_stack[swap_index] = op_title_data
