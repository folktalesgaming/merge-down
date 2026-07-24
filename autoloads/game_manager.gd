extends Node

signal board_updated(row: int, col: int, new_val: int)
signal tile_cleared(row: int, col: int)
signal new_operator_tile_added(removed_op_index: int)
signal negative_hazard(s_i: int, val: int, r: int, c: int, r_i: int)
signal level_completed()
signal in_between_tile_status_changed(r: int, c: int, status: bool)
signal level_stuck()


# Properties
var _board: Array[Array]
var _op_stack: Array[Dictionary]
var _board_size: int = 5
var _stack_size: int = 7
var _total: int = 0

var _in_between_drop_zone_status: Array[Array]

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
	_in_between_drop_zone_status.clear()
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
		type = Utility.get_weighted_random_type([0, 70, 30]),
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
		in_between_tile_status_changed.emit(row, col, false)
		
		if result < 0:
			new_op_tile_created = true
			var rand_index = randi_range(0, 6)
			_op_stack[rand_index] = get_rand_op_data(rand_index)
			negative_hazard.emit(rand_index, result, row, col, op_tile_pos)
	else:
		_total -= (current_val - result)
		_board[row][col] = result
		board_updated.emit(row, col, result)
	
	if _total == 0:
		level_completed.emit()
		return
		
	if !new_op_tile_created:
		_op_stack.remove_at(op_tile_pos)
		_op_stack.append(get_rand_op_data(6))
		new_operator_tile_added.emit(op_tile_pos)
	
	if check_stuck():
		level_stuck.emit()


func consume_multi_operator(op_data: Dictionary, tiles_pos: Array[Vector2]):
	var r_1: int = tiles_pos[0].x
	var c_1: int = tiles_pos[0].y
	var r_2: int = tiles_pos[1].x
	var c_2: int = tiles_pos[1].y
	
	var board_one_val: int = _board[r_1][c_1]
	var board_two_val: int = _board[r_2][c_2]
	var sym: GlobalConst.OperatorSymbol = op_data["symbol"]
	var op_tile_pos: int = op_data["index"]
	
	var is_merged_to_board_one: bool = true
	var new_op_tile_created: bool = false
	
	var result: int = 0
	
	match sym:
		GlobalConst.OperatorSymbol.SUB:
			if board_one_val > board_two_val:
				result = board_one_val - board_two_val
			else:
				is_merged_to_board_one = false
				result = board_two_val - board_one_val
		GlobalConst.OperatorSymbol.DIVIDE:
			var rem: int = 0
			if board_one_val > board_two_val:
				rem = board_one_val % board_two_val
				if rem == 0:
					result = board_one_val / board_two_val
				else:
					# TODO: SPLIT
					result = rem
			else:
				is_merged_to_board_one = false
				rem = board_two_val % board_one_val
				if rem == 0:
					result = board_two_val / board_one_val
				else:
					# TODO: SPLIT
					result = rem
	
	if result <= 0:
		_total -= (board_one_val+board_two_val)
		_board[r_1][c_1] = 0
		_board[r_2][c_2] = 0
		tile_cleared.emit(r_1, c_1)
		tile_cleared.emit(r_2, c_2)
		
		in_between_tile_status_changed.emit(r_1, c_1, false)
		in_between_tile_status_changed.emit(r_2, c_2, false)
		
		if result < 0:
			new_op_tile_created = true
			var rand_index = randi_range(0, 6)
			_op_stack[rand_index] = get_rand_op_data(rand_index)
			negative_hazard.emit(rand_index, result, r_1, c_1, op_tile_pos)
	else:
		_total -= (board_one_val+board_two_val) - result
		if is_merged_to_board_one:
			_board[r_1][c_1] = result
			board_updated.emit(r_1, c_1, result)
			tile_cleared.emit(r_2, c_2)
			in_between_tile_status_changed.emit(r_2, c_2, false)
		else:
			_board[r_2][c_2] = result
			board_updated.emit(r_2, c_2, result)
			tile_cleared.emit(r_1, c_1)
			in_between_tile_status_changed.emit(r_1, c_1, false)
			
	if _total == 0:
		level_completed.emit()
		return
	
	if !new_op_tile_created:
		_op_stack.remove_at(op_tile_pos)
		_op_stack.append(get_rand_op_data(6))
		new_operator_tile_added.emit(op_tile_pos)
	
	if check_stuck():
		level_stuck.emit()


func check_stuck() -> bool:
	var has_active_multi_zone: bool = false
	
	for i in range(_in_between_drop_zone_status.size()):
		for j in range(_in_between_drop_zone_status[i].size()):
			if _in_between_drop_zone_status[i][j].is_active:
				has_active_multi_zone = true
				break
		if has_active_multi_zone:
			break

	var has_single_operator: bool = false
	for i in range(3):
		if _op_stack[i]["type"] == GlobalConst.OperatorType.SINGLE:
			has_single_operator = true
			break
	
	if has_active_multi_zone or has_single_operator:
		return false
	
	return true
